#!/usr/bin/env ruby
module MIDIEye
  
  class Listener
    
    attr_reader :events 
    attr_accessor :sources
      
    @input_types = []
      
    class << self
      # a registry of input types
      attr_reader :input_types      
    end
        
    def initialize(input, options = {})
      @sources = []
      @event_queue = []
      @events = []
  
      add_input(input)
    end
    
    # add a source
    # takes a raw input or array of
    def add_input(input)
      @sources += [input].flatten.map do |i|
        klass = self.class.input_types.find { |type| type.is_compatible?(i) }
        raise "Input class type #{i.class.name} not compatible" if klass.nil?
        klass.new(i)
      end
    end
    
    # remove a source
    # takes a raw input or array of
    def remove_input(inputs)
      to_remove = [inputs].flatten
      to_remove.each do |input|
        @sources.delete_if { |source| source.uses?(input) }
      end
    end
    
    def delete_event(name)
      @events.delete_if { |e| e[:listener_name] == name }
    end
    
    # start the listener. pass in :background => true to run only in a background thread. returns self
    def run(options = {})      
      listen!
      unless options[:background]
        @listener.join  
      end
      self
    end
    alias_method :start, :run
    
    # stop the listener. returns self
    def close
      @listener.kill unless @listener.nil?
      @events.clear
      @sources.clear
      @event_queue.clear
      self
    end
    alias_method :stop, :close
    
    # join the listener if it's being run in the background. returns self
    def join
      @listener.join
      self
    end
    
    # add an event to listen for. returns self
    def listen_for(options = {}, &proc)
      raise 'listener must have a block' if proc.nil?
      name = options[:listener_name]
      options.delete(:listener_name)
      @events << { :conditions => options, :proc => proc, :listener_name => name }
      self      
    end
    alias_method :on_message, :listen_for
    alias_method :listen, :listen_for
    
    # poll the input source for new input. this will normally be done by the background thread 
    def poll
      @sources.each do |input|
        input.poll do |objs|
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

    private
    
    # start the background listener thread    
    def listen!   
      t = 1.0/1000
      @listener = Thread.fork do       
        Thread.abort_on_exception = true
        loop do
          poll
          trigger_queued_events unless @event_queue.empty?
          sleep(t)
        end
      end
    end
    
    # trigger all queued events
    def trigger_queued_events
      @event_queue.length.times { trigger_event(@event_queue.shift) }
    end
    
    # does <em>message</em> meet <em>conditions</em>?
    def meets_conditions?(conditions, message)
      !conditions.map do |key, value|
        message.respond_to?(key) && (value.kind_of?(Array) ? value.include?(message.send(key)) : value.eql?(message.send(key))) 
      end.include?(false)
    end
    
    # trigger an event
    def trigger_event(event)
      begin
        action = event[:action]
        if meets_conditions?(action[:conditions], event[:message][:message]) || action[:conditions].nil?
          action[:proc].call(event[:message])
        end
      rescue
      end
    end
    
    # add an event to the trigger queue 
    def queue_event(event, message)  
      @event_queue << { :action => event, :message => message }
    end
                
  end  
  
end