#!/usr/bin/env ruby
#
module MIDIEye
  
  # this class deals with retrieving new messages from
  # a unimidi input buffer
  class UniMIDIInput
    
    attr_reader :device, :pointer
    
    def initialize(input)   
      @parser = Nibbler.new   
      @pointer = 0      
      @device = input      
    end
    
    # this grabs new messages from the unimidi buffer
    def poll(&block)
      msgs = @device.buffer.slice(@pointer, @device.buffer.length - @pointer)
      @pointer = @device.buffer.length
      msgs.each do |raw_msg| 
        unless raw_msg.nil?        
          objs = [@parser.parse(raw_msg[:data], :timestamp => raw_msg[:timestamp])].flatten.compact
          yield(objs)
        end
      end    
    end
    
    # if <em>input</em> looks like a unimidi input, this returns true
    def self.is_compatible?(input)
      input.respond_to?(:gets) && input.respond_to?(:buffer)
    end
    
    # add this class to the Listener class' known input types
    Listener.input_types << self 
    
  end
            
end