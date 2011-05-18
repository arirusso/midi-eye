#!/usr/bin/env ruby
module MIDIEye
  
  class Listener
    
    attr_reader :events, :sources
      
    @input_types = []
      
    class << self
      attr_reader :input_types      
    end
        
    def initialize(input, options = {})
      @parser = Nibbler.new
      @sources = []
      @event_queue = []
      @events = []
            
      @exit_background_requested = false      
      @sources += [input].flatten.map do |i|
        klass = self.class.input_types.find { |type| type.is_compatible?(i) }
        klass.new(i)
      end
    end
    
    def run(options = {})      
      listen!
      unless options[:background]
        @listener.join  
      end
    end
    
    def close
      @listener.kill unless @listener.nil?
    end
    
    def poll
      @sources.each do |input|
        input.poll do |raw_msg|
          unless raw_msg.nil?        
            objs = [@parser.parse(raw_msg[:data], :timestamp => raw_msg[:timestamp])].flatten.compact
            objs.each do |batch|
              [batch[:messages]].flatten.each do |single_message|
                unless single_message.nil?
                  data = { :message => single_message, :timestamp => batch[:timestamp] }
                  @events.each { |name| queue_event(name, data) }
                end
              end
            end 
          end
        end
      end
    end
    
    def listen_for(options = {}, &proc)
      return if options[:call_method].nil? && proc.nil?
      @events << { :method => options[:call_method], :proc => proc, :conditions => options }      
    end
    alias_method :on_message, :listen_for
    
    private
        
    def listen!   
      t = 1.0/1000
      @listener = Thread.fork do       
        loop do
          Thread.exit if @exit_background_requested
          poll
          trigger_queued_events unless @event_queue.empty?
          sleep(t)
        end
      end
    end
    
    def trigger_queued_events
      @event_queue.length.times { trigger_event(@event_queue.shift) }
    end
    
    def meets_conditions?(conditions, message)
      !conditions.map do |key, value|
        value.kind_of?(Array) ? value.include?(message.send(key)) : value.eql?(message.send(key)) 
      end.include?(false)
    end
    
    def trigger_event(event)
      action = event[:action]
      return unless meets_conditions?(action[:conditions], event[:message][:message]) || action[:conditions].nil?
      unless action[:method].nil? || !self.respond_to?(action[:method])
        send(action[:method], event[:message]) 
      else
        action[:proc].call(event[:message])
      end
    end
    
    def queue_event(event, message)  
      @event_queue << { :action => event, :message => message }
    end
                
  end  
  
end