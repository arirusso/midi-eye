module MIDIEye
  
  # User defined callbacks for input events
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

    # Clear the collection of events
    # @return [Boolean]
    def clear
      @event.clear
      @queue.clear
      true
    end

    # Add a user-defined input callback
    # @param [Hash] options
    # @param [Proc] callback
    # @return [Hash]
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
    # @return [Fixnum] The number of triggered events
    def trigger_enqueued
      counter = 0
      while !@queue.empty? do
        counter += 1
        trigger(@queue.shift)
      end
      counter
    end

    # Enqueue all events with the given message
    # @return [Array<Hash>]
    def enqueue_all(message)
      @event.map { |action| enqueue(action, message) }
    end

    # Add an event to the trigger queue
    # @return [Hash]
    def enqueue(action, message)  
      event = { 
        :action => action, 
        :message => message 
      }
      @queue << event
      event
    end

    # The number of events
    # @return [Fixnum]
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
        rescue Exception => exception
          Thread.main.raise exception
        end
      end
    end
    
  end

end
