#!/usr/bin/env ruby
#
# this is an example that takes any note messages from a unimidi input,
# transposes them up an octave and sends them to a unimidi output
#
#
$:.unshift File.join( File.dirname( __FILE__ ), '../lib')

require 'midi-eye'

include MIDIEye
include MIDIMessage 

@input = UniMIDI::Input.first.open
@output = UniMIDI::Output.first.open

transpose = Listener.new(@input)

transpose.on_message(:class => [NoteOn, NoteOff]) do |event|
   
  p "from #{event[:message].note} to #{(event[:message].note + 12)}"
  
  event[:message].note += 12
  @output.puts(event[:message].to_bytes)
  
end

p "use control-c to quit..."

transpose.run
