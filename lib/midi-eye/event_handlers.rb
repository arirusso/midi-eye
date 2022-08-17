# frozen_string_literal: true

module MIDIEye
  # User defined callbacks for input events
  class EventHandlers
    extend Forwardable

    EventHandler = Struct.new(:conditions, :proc, :name)
    EnqueuedEvent = Struct.new(:handler, :event)

    def_delegators :@handlers, :count

    def initialize
      @handlers = []
      @event_queue = Queue.new
    end

    # Delete an event by name
    # @param [String, Symbol] name
    def delete(name)
      @handlers.delete_if { |handler| handler.name.to_s == name.to_s }
    end

    # Clear the event handlers and their events
    # @return [Boolean]
    def clear
      @handlers.clear
      @event_queue.clear
      true
    end

    # Add a user-defined input callback
    # @param [Hash] options
    # @param [Proc] callback
    # @return [Hash]
    def add(options = {}, &callback)
      name = options[:name]
      options.delete(:name)
      handler = EventHandler.new(options, callback, name)
      @handlers << handler
      handler
    end

    # Trigger all enqueued events
    # @return [Integer] The number of triggered events
    def handle_enqueued
      counter = 0
      until @event_queue.empty?
        counter += 1
        handle_event(@event_queue.shift)
      end
      counter
    end

    # Enqueue the given event for all handlers
    # @return [Array<Hash>]
    def enqueue(event)
      @handlers.map { |handler| enqueue_event_for_handler(handler, event) }
    end

    private

    # For the given handler, add an event to the queue
    # @return [Hash]
    def enqueue_event_for_handler(handler, event)
      enqueued_event = EnqueuedEvent.new(handler, event)
      @event_queue << enqueued_event
      enqueued_event
    end

    # Does the given message meet the given conditions?
    def meets_conditions?(conditions, message)
      conditions.map { |key, value| condition_met?(message, key, value) }.all?
    end

    # Trigger an event
    def handle_event(shifted_event)
      handler = shifted_event.handler
      conditions = handler.conditions
      return unless conditions.nil? || meets_conditions?(conditions, shifted_event.event[:message])

      begin
        handler.proc.call(shifted_event.event)
      rescue StandardError => e
        Thread.main.raise(e)
      end
    end

    def condition_met?(message, key, value)
      if message.respond_to?(key)
        if value.is_a?(Enumerable)
          value.include?(message.send(key))
        else
          value.eql?(message.send(key))
        end
      else
        false
      end
    end
  end
end
