# frozen_string_literal: true

module MIDIEye
  # Listens for MIDI Messages
  class Listener
    LISTEN_INTERVAL = 1.0 / 10_000

    attr_reader :event
    attr_accessor :sources

    # @param [Array<UniMIDI::Input>, UniMIDI::Input] inputs Input(s) to add to the list of sources for this listener
    def initialize(inputs)
      @sources = []
      @event = Event.new

      add_input(inputs)
    end

    # Does this listener use the given input?
    # @param [UniMIDI::Input] input
    # @return [Boolean]
    def uses_input?(input)
      @sources.any? { |source| source.uses?(input) }
    end

    # Add a MIDI source
    # @param [Array<UniMIDI::Input>, UniMIDI::Input] inputs Input(s) to add to the list of sources for this listener
    # @return [Array<MIDIEye::Source>] The updated list of sources for this listener
    def add_input(inputs)
      inputs = [inputs].flatten.compact
      input_sources = inputs.reject { |input| uses_input?(input) }
      @sources += input_sources.map { |input| Source.new(input) }
      @sources
    end
    alias add_inputs add_input

    # Remove a MIDI source
    # @param [Array<UniMIDI::Input>, UniMIDI::Input] inputs Input(s) to remove from
    #    the list of sources for this listener
    # @return [Array<MIDIEye::Source>] The updated list of sources for this listener
    def remove_input(inputs)
      inputs = [inputs].flatten.compact
      inputs.each do |input|
        @sources.delete_if { |source| source.uses?(input) }
      end
      @sources
    end
    alias remove_inputs remove_input

    # Start listening for MIDI messages
    # @params [Hash] options
    # @option options [Boolean] :background Run in a background thread
    # @return [MIDIEye::Listener] self
    def run(options = {})
      listen
      join if options[:background].nil?
      self
    end
    alias start run

    # Stop listening for MIDI messages.
    # @return [MIDIEye::Listener] self
    def close
      @listener.kill if running?
      @event.clear
      @sources.clear
      self
    end
    alias stop close

    # Is the listener running?
    # @return [Boolean]
    def running?
      !@listener.nil? && @listener.alive?
    end

    # Join the listener if it's being run in the background.
    # @return [MIDIEye::Listener] self
    def join
      begin
        @listener.join
      rescue StandardError => e
        @listener.kill
        Thread.main.raise(e)
      end
      self
    end

    # Deletes the event with the given name (for backwards compat)
    # @param [String, Symbol] event_name
    # @return [Boolean]
    def delete_event(event_name)
      !@event.delete(event_name).nil?
    end

    # Add an event to listen for
    # @param [Hash] options
    # @return [MIDIEye::Listener] self
    def listen_for(options = {}, &callback)
      raise 'Listener must have a block' if callback.nil?

      @event.add(options, &callback)
      self
    end
    alias on_message listen_for

    # Poll the input source for new input. This will normally be done by the background thread
    def poll
      @sources.each do |input|
        input.poll do |parser_event|
          parser_event_to_messages(parser_event)
        end
      end
    end

    private

    def parser_event_to_messages(parser_event)
      parser_event.report.messages.each do |message|
        data = {
          message: message,
          timestamp: parser_event.timestamp
        }
        @event.enqueue_all(data)
      end
    end

    # A loop that runs while the listener is active
    def listen_loop
      loop do
        poll
        @event.trigger_enqueued
        sleep(LISTEN_INTERVAL)
      end
    end

    # Start the background listener thread
    def listen
      @listener = Thread.new do
        begin
          listen_loop
        rescue StandardError => e
          Thread.main.raise(e)
        end
      end
      @listener.abort_on_exception = true
      true
    end
  end
end
