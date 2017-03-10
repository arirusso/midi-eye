module MIDIEye

  class Listener

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
    alias_method :add_inputs, :add_input

    # Remove a MIDI source
    # @param [Array<UniMIDI::Input>, UniMIDI::Input] inputs Input(s) to remove from the list of sources for this listener
    # @return [Array<MIDIEye::Source>] The updated list of sources for this listener
    def remove_input(inputs)
      inputs = [inputs].flatten.compact
      inputs.each do |input|
        @sources.delete_if { |source| source.uses?(input) }
      end
      @sources
    end
    alias_method :remove_inputs, :remove_input

    # Start listening for MIDI messages
    # @params [Hash] options
    # @option options [Boolean] :background Run in a background thread
    # @return [MIDIEye::Listener] self
    def run(options = {})
      listen
      join unless !!options[:background]
      self
    end
    alias_method :start, :run

    # Stop listening for MIDI messages.
    # @return [MIDIEye::Listener] self
    def close
      @listener.kill if running?
      @event.clear
      @sources.clear
      self
    end
    alias_method :stop, :close

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
      rescue Exception => exception
        @listener.kill
        Thread.main.raise(exception)
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
      raise "Listener must have a block" if callback.nil?
      @event.add(options, &callback)
      self
    end
    alias_method :on_message, :listen_for

    # Poll the input source for new input. This will normally be done by the background thread
    def poll
      @sources.each do |input|
        input.poll do |objs|
          objs.each do |batch|
            messages = [batch[:messages]].flatten.compact
            messages.each do |message|
              unless message.nil?
                data = { :message => message, :timestamp => batch[:timestamp] }
                @event.enqueue_all(data)
              end
            end
          end
        end
      end
    end

    private

    # A loop that runs while the listener is active
    def listen_loop
      interval = 1.0/1000
      loop do
        poll
        @event.trigger_enqueued
        sleep(interval)
      end
    end

    # Start the background listener thread
    def listen
      @listener = Thread.new do
        begin
          listen_loop
        rescue Exception => exception
          Thread.main.raise(exception)
        end
      end
      @listener.abort_on_exception = true
      true
    end

  end

end
