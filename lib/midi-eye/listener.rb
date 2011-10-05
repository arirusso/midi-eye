#!/usr/bin/env ruby
module MIDIEye
  
  class Listener
    
    attr_reader :events, :sources
      
    @input_types = []
      
    class << self
      # a registry of input types
      attr_reader :input_types      
    end
        
    def initialize(input, options = {})
      @sources = []
      @event_queue = []
      @events = []
            
      #@exit_background_requested = false      
      @sources += [input].flatten.map do |i|
        klass = self.class.input_types.find { |type| type.is_compatible?(i) }
        raise "Input class type #{i.class.name} not compatible" if klass.nil?
        klass.new(i)
      end
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
      name = options[:name]
      options.delete(:name)
      @events << { :conditions => options, :proc => proc, :name => name }
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
        loop do
          #Thread.exit if @exit_background_requested
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
        value.kind_of?(Array) ? value.include?(message.send(key)) : value.eql?(message.send(key)) 
      end.include?(false)
    end
    
    # trigger an event
    def trigger_event(event)
      action = event[:action]
      return unless meets_conditions?(action[:conditions], event[:message][:message]) || action[:conditions].nil?
      #unless action[:method].nil? || !self.respond_to?(action[:method])
      #  send(action[:method], event[:message]) 
      #else
      action[:proc].call(event[:message])
      #end
    end
    
    # add an event to the trigger queue 
    def queue_event(event, message)  
      @event_queue << { :action => event, :message => message }
    end
                
  end  
  
end