#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift(File.join('..', 'lib'))

require 'midi-eye'

# This example takes any note messages received from a UniMIDI input,
# transposes them up one octave and sends them to an output

# First, initialize the MIDI io ports
@input = UniMIDI::Input.gets
@output = UniMIDI::Output.gets

# Create a listener for the input port
transpose = MIDIEye::Listener.new(@input)

# Bind an event to the listener using Listener#listen_for
#
# The listener will try to positively match the parameters you pass in to the properties of
# the messages it receives
#
# This example looks for note on/off messages
#
# You also have the option of leaving out the parameters altogether and including a conditional
# in your callback (eg if event[:message].class.eql?(NoteOn) do... etc)
#
# There's no limit to how many events can be binded to a listener
#
transpose.on_message do |event|
  # Send the altered note message to the output
  @output.puts(event[:message])
end

# Start the listener

p 'Control-C to quit...'

transpose.run

# You can also have the listener run only in a background thread by using
#
# Transpose.run(:background => true)
#
# This will allow you to run multiple listeners at the same time for example, if you
# want to listen on multiple input ports
