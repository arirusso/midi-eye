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
      @parser = Nibbler.new
      @pointer = 0
      @device = input
    end

    # Grabs new messages from the input buffer
    def poll(&block)
      messages = @device.buffer.slice(@pointer, @device.buffer.length - @pointer)
      @pointer = @device.buffer.length
      messages.each do |raw_message|
        unless raw_message.nil?
          parsed_messages = @parser.parse(raw_message[:data], :timestamp => raw_message[:timestamp]) rescue nil
          objects = [parsed_messages].flatten.compact
          yield(objects)
        end
      end
    end

    # If this source was created from the given input
    # @param [UniMIDI::Input] input
    # @return [Boolean]
    def uses?(input)
      @device == input
    end

  end

end
