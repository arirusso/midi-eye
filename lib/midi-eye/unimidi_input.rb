#!/usr/bin/env ruby
module MIDIEye
  
  class UniMIDIInput
    
    attr_reader :device, :pointer
    
    def initialize(input)      
      @pointer = 0      
      @device = input      
    end
    
    def poll(&block)
      msgs = @device.buffer.slice(@pointer, @device.buffer.length - @pointer)
      msgs.each { |raw_msg| block.call(raw_msg) }
      @pointer = @device.buffer.length      
    end
    
  end
            
end