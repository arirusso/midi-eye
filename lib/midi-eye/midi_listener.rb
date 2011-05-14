#!/usr/bin/env ruby
module MIDIEye
  
  module Listener
    
    def self.included(base)
      base.extend(ClassMethods)
    end
    
    def initialize_midi_listener
      @parser ||= Nibbler.new
      @sources ||= []
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
      @listener.join unless options[:background]
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
              [batch[:messages]].flatten.each do |m|
                hash = { :message => m, :timestamp => batch[:timestamp] }
                events.each { |event| handle_event(event, hash) }
              end
            end 
          end
        end
      end
    end
    
    protected
    
    def listen!   
      @listener = Thread.fork do       
        while true
          poll
        end
      end
    end
    
    def handle_event(event, message)
      condition = event[:condition].call(message) unless event[:condition].nil?
      send(event[:method], message) if condition
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