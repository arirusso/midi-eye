module MIDIEye
  
  class Event

    def initialize
      @event = []
      @queue = []
    end

    # Delete an event by name
    # @param [String, Symbol] name
    def delete(name)
      @event.delete_if { |event| event[:listener_name].to_s == name.to_s }
    end

    def clear
      @event.clear
      @queue.clear
    end

    def add(options = {}, &callback)
      name = options[:listener_name]
      options.delete(:listener_name)
      event = { 
        :conditions => options, 
        :proc => callback, 
        :listener_name => name 
      }
      @event << event
      event
    end

    # Trigger all enqueued events
    def trigger_enqueued
      while !@queue.empty? do
        trigger(@queue.shift)
      end
    end

    def enqueue_all(message)
      @event.each { |name| enqueue(name, message) }
    end

    # Add an event to the trigger queue 
    def enqueue(action, message)  
      event = { 
        :action => action, 
        :message => message 
      }
      @queue << event
    end

    def count
      @event.count
    end

    private

    # Does the given message meet the given conditions?
    def meets_conditions?(conditions, message)
      results = conditions.map do |key, value|
        if message.respond_to?(key)
          if value.kind_of?(Array)
            value.include?(message.send(key))
          else
            value.eql?(message.send(key))
          end
        else
          false
        end
      end
      results.all?
    end

    # Trigger an event
    def trigger(event)
      action = event[:action]
      conditions = action[:conditions]
      if conditions.nil? || meets_conditions?(conditions, event[:message][:message])
        begin
          action[:proc].call(event[:message])
        rescue
          # help
        end
      end
    end
    
  end

end
