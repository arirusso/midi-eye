#!/usr/bin/env ruby
$:.unshift File.join( File.dirname( __FILE__ ), '../lib')

require "midi-eye"

include MIDIMessage

#
# this is an example that takes plays arpeggios in sync with
# MIDI clock ticks that are received on an input
#

# first, initialize the MIDI io ports
@input = UniMIDI::Input.first.open
@output = UniMIDI::Output.first.open

# initialize the listener and give it the input port
@clock = MIDIEye::Listener.new(@input)

# the notes of the arpeggio
@notes = [43, 46, 48, 55, 58, 61, 62, 67, 70, 72]

# play a note and step through the arpeggio every time 2 notes are played 
@ticks_per_note = 2

message_counter = 0
note_counter = 0
note_on = true

# look for clock messages
@clock.listen_for(:name => "Clock") do |event|
  
  # is it time to output a note?
  if message_counter.eql?(@ticks_per_note)
    # should we send note on or note off? 
    type = note_on ? NoteOn : NoteOff
    # construct the note
    note = type.new(0, @notes[note_counter], 64)
    # output the note   
    @output.puts(note.to_bytes)
    
    note_on=!note_on    
    # step the note counter if we've finished with both note on and off for this 
    # particular note  
    note_counter = (note_counter < (@notes.length-1) ? note_counter + 1 : 0) if note_on
    message_counter = 0
  else
    message_counter += 1
  end

end

p "control-c to quit..."

# start the listener
@clock.run
