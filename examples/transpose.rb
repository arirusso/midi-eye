#!/usr/bin/env ruby
$:.unshift File.join( File.dirname( __FILE__ ), '../lib')

require 'midi-eye'
  
# this is an example that takes any note messages received from a unimidi input
# and sends them to an output transposed up one octave

# first, initialize the MIDI io ports  
@input = UniMIDI::Input.gets
@output = UniMIDI::Output.gets

# then create a listener for the input port  
transpose = MIDIEye::Listener.new(@input)

# bind an event to the listener using Listener#listen_for
#
# the listener will try to positively match the parameters you pass in to the properties of
# the messages it receives
#
# in this example, we will look for note on/off messages
#
# you also have the option of leaving out the parameters altogether and including a conditional
# in your callback (eg if event[:message].class.eql?(NoteOn) do... etc)
#
# you can bind as many events to a listener as you wish
#
transpose.listen_for(:class => [MIDIMessage::NoteOn, MIDIMessage::NoteOff]) do |event|

  puts "Transposing from #{event[:message].note} to #{(event[:message].note + 12)}"
     
  # raise the note value by an octave
  event[:message].note += 12
    
  # send the altered note message to the output you chose earlier 
  @output.puts(event[:message])

end

# now start the listener

p "control-c to quit..."
  
transpose.run
  
# or have the listener run only in a background thread by using
# this will allow you to run multiple listeners at the same time for instance, if you're
# trying to listen on multiple input ports
  
# Transpose.run(:background => true)
