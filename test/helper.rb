#!/usr/bin/env ruby

dir = File.dirname(File.expand_path(__FILE__))
$LOAD_PATH.unshift dir + '/../lib'

require 'test/unit'
require 'midi-eye'
require 'midi-message'

module TestHelper
	
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
  
end
