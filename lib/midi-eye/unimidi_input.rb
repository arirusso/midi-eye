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
      @pointer = @device.buffer.length
      msgs.each { |raw_msg| yield(raw_msg) }            
    end
    
    def self.is_compatible?(input)
      klass = input.class.name.split("::").first
      klass.eql?("UniMIDI")
    end
    
    Listener.input_types << self 
    
  end
            
end