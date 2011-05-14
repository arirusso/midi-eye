#!/usr/bin/env ruby
module MIDIEye
  
  class UniMIDIInput
    
    attr_reader :device, :pointer
    
    Parser = Nibbler.new
    
    def initialize(input)      
      @pointer = 0      
      @device = input      
    end
    
    def poll(&block)
      msgs = @device.buffer.slice(@pointer, @device.buffer.length - @pointer)
      msgs.each do |raw_msg|
        objs = [Parser.parse(raw_msg[:data], :timestamp => raw_msg[:timestamp])].flatten.compact
        objs.each do |batch|
          [batch[:messages]].flatten.each do |m|
            block.call({ :message => m, :timestamp => batch[:timestamp] })
          end
        end
      end
      @pointer = @device.buffer.length      
    end
    
  end
            
end