#!/usr/bin/env ruby
$:.unshift(File.join("..", "lib"))

require "midi-eye"

#
# This example plays arpeggios in sync with MIDI clock ticks that are received on an input
#

# First, initialize the MIDI io ports
@input = UniMIDI::Input.gets
@output = UniMIDI::Output.gets

# Initialize the MIDIEye listener and pass it the input port
@clock = MIDIEye::Listener.new(@input)

# The notes of the arpeggio
@notes = [43, 46, 48, 55, 58, 61, 62, 67, 70, 72]

# Play a note and step through the arpeggio every time 2 clicks arrive
@ticks_per_note = 2

message_counter = 0
note_counter = 0
is_note_on = true

# Listen for clock messages
@clock.listen_for(:name => "Clock") do |event|

  # Should it output a note on this click?
  if message_counter.eql?(@ticks_per_note)

    # Should it send note on or note off?
    type = is_note_on ? MIDIMessage::NoteOn : MIDIMessage::NoteOff

    # Construct the note
    note = type.new(0, @notes[note_counter], 64)

    # Output the note
    @output.puts(note)

    # Print the note value to the console
    puts(@notes[note_counter]) if is_note_on

    is_note_on = !is_note_on

    # Once its finished with both note on and off for this particular note,
    # increment the note counter
    note_counter = (note_counter < (@notes.length-1) ? note_counter + 1 : 0) if is_note_on
    message_counter = 0
  else
    message_counter += 1
  end

end

p "Control-C to quit..."

# Start the listener
@clock.run
