module MIDIEye
  
  # This class deals with retrieving new messages from a unimidi input buffer
  class UniMIDIInput
    
    attr_reader :device, :pointer
    
    def initialize(input)   
      @parser = Nibbler.new   
      @pointer = 0      
      @device = input      
    end
    
    # Grabs new messages from the unimidi buffer
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
    
    # Whether the given input is a UniMIDI input
    def self.compatible?(input)
      input.respond_to?(:gets) && input.respond_to?(:buffer)
    end
    
    # If this source was created from the given input
    def uses?(input)
      @device == input
    end
    
    # Add this class to the Listener class' known input types
    Listener.input_types << self 
    
  end
            
end
