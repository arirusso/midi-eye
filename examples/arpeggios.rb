#!/usr/bin/env ruby
#
# this is an example that takes plays arpeggios in time with
# MIDI clock ticks that are received on an input
#

$:.unshift File.join( File.dirname( __FILE__ ), '../lib')

require "midi-eye"

include MIDIEye
include MIDIMessage

input = UniMIDI::Input.first.open
output = UniMIDI::Output.first.open

@clock = MIDIEye::Listener.new(input)

@notes = [43, 46, 48, 55, 58, 61, 62, 67, 70, 72]
@ticks_per_note = 2

@message_counter = 0
@note_counter = 0
@note_on = true

@clock.on_message(:name => "Clock") do |event|
    
    if @message_counter.eql?(@ticks_per_note) 
      type = @note_on ? NoteOn : NoteOff
      note = type.new(0, @notes[@note_counter], 64)   
      output.puts(note.to_bytes)
      @note_on=!@note_on      
      @note_counter = (@note_counter < (@notes.length-1) ? @note_counter + 1 : 0) if @note_on
      @message_counter = 0
    else
      @message_counter += 1
    end

end
  
@clock.run

