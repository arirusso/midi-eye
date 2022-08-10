# frozen_string_literal: true

module MIDIEye
  # Retrieves new messages from a unimidi input buffer
  class Source
    attr_reader :device, :pointer

    # Whether the given object is a UniMIDI input
    # @param [Object] input
    # @return [Boolean]
    def self.compatible?(input)
      input.respond_to?(:gets) && input.respond_to?(:buffer)
    end

    # @param [UniMIDI::Input] input
    def initialize(input)
      @parser = Nibbler::Session.new
      @pointer = 0
      @device = input
    end

    # Grabs new messages from the input buffer
    def poll(&block)
      messages = @device.buffer.slice(@pointer, @device.buffer.length - @pointer)
      @pointer = @device.buffer.length
      messages.compact.each { |raw_message| handle_message(raw_message, &block) }
    end

    # If this source was created from the given input
    # @param [UniMIDI::Input] input
    # @return [Boolean]
    def uses?(input)
      @device == input
    end

    private

    def handle_message(raw_message)
      event = begin
        @parser.parse_events(*raw_message[:data], timestamp: raw_message[:timestamp])
      # rescue StandardError
      #   nil
      end
      #p parser_result
      yield(event)
    end
  end
end
