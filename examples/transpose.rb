#!/usr/bin/env ruby
$:.unshift File.join( File.dirname( __FILE__ ), '../lib')

require 'midi-eye'
require 'unimidi'
require 'midi-message'

class Transpose

  include MIDIEye::Listener

  attr_reader :input
  
  listen_on :input, 
            :type => :unimidi

  midi_event :on_note, :when => Proc.new { |e| e[:message].kind_of?(MIDIMessage::NoteOn) }
  
  def initialize(input, output, options = {})
    @input = input
    @output = output
    initialize_midi_listener
  end

  private

  def on_note(event)
    p "from note #{event[:message].note} to #{(event[:message].note += 12)}"
    @output.puts(event[:message].to_a)
  end

end

p "use control-c to quit..."

output = UniMIDI::Output.first.open
input = UniMIDI::Input.first.open 

Transpose.new(input, output).start
