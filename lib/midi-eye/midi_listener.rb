#!/usr/bin/env ruby
module MIDIEye
  
  module Listener
    
    def self.included(base)
      base.extend(ClassMethods)
    end
    
    def initialize_midi_listener
      @parser ||= Nibbler.new
      @sources ||= []
      @event_queue ||= []
      @exit_background_requested = false
      @sources += self.class.sources.map do |hash|
        klass = case hash[:type]
          when :unimidi then UniMIDIInput
        end 
        [send(hash[:sources])].flatten.map do |source|
          klass.new(source)
        end
      end.flatten
    end
    
    def run(options = {})      
      listen!
      #@listener.priority = 20
      unless options[:background]
        trigger_event({ :method => :on_start_background_thread })
        @listener.join        
        trigger_event({ :method => :on_exit_background_thread })
      end
    end
    
    def close
      @listener.kill
    end
    
    def poll
      events = self.class.midi_events
      @sources.each do |input|
        input.poll do |raw_msg|
          unless raw_msg.nil?         
            objs = [@parser.parse(raw_msg[:data], :timestamp => raw_msg[:timestamp])].flatten.compact
            objs.each do |batch|
              [batch[:messages]].flatten.each do |single_message|
                data = { :message => single_message, :timestamp => batch[:timestamp] }
                events.each { |name| queue_event(name, data) }
              end
            end 
          end
        end
      end
    end
    
    protected
    
    def listen!   
      @listener = Thread.fork do       
        loop do
          Thread.exit if @exit_background_requested
          poll
          trigger_queued_events unless @event_queue.empty?
          sleep(1.0/1000.0)
        end
      end
    end
    
    def trigger_queued_events
      @event_queue.length.times { trigger_event(@event_queue.shift) }
    end
    
    def trigger_event(event)
      send(event[:method], event[:event]) if self.respond_to?(event[:method])
    end
    
    def queue_event(event, message)
      condition = event[:condition].nil? ? true : event[:condition].call(message) 
      @event_queue << { :method => event[:method], :event => message } if condition
    end
    
    module ClassMethods
      
      attr_reader :midi_events, :sources
      
      def midi_event(method, options = {})
        @midi_events ||= []
        @midi_events << { :method => method, :condition => options[:when] }
      end
      
      def listen_on(sources, options)
        @sources ||= []
        @sources << { :sources => sources, :type => options[:type] }
      end
      
    end
                
  end  
  
end