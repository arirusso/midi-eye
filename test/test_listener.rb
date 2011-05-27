#!/usr/bin/env ruby

require 'helper'

class ListenerTest < Test::Unit::TestCase

  include MIDIEye
  include MIDIMessage
  include TestHelper
  include TestHelper::Config # edit this module to change hardware settings
  
  def test_recognize_input_class
    sleep(0.5)
    TestInput.open do |input|
      listener = Listener.new(input)
      assert_equal(UniMIDIInput, listener.sources.first.class)
    end
  end
  
  def test_listen_for_basic
    sleep(0.5)
    @i = 0
    TestOutput.open do |output|
      TestInput.open do |input|
        listener = Listener.new(input)
        listener.listen_for do |event|
          @i += 1
          assert_equal(1, @i)
          listener.close
        end
        listener.start(:background => true)
        sleep(0.1)
        output.puts(0x90, 0x40, 0x10)
        listener.join
      end
    end
  end
  
  def test_listen_for_note_on
    sleep(0.5)
    TestOutput.open do |output|
      TestInput.open do |input|
        listener = Listener.new(input)
        listener.listen_for(:class => NoteOn) do |event|
          assert_equal(NoteOn, event[:message].class)
          assert_equal(0x50, event[:message].note)      
          assert_equal(0x40, event[:message].velocity)
          assert_equal([0x90, 0x50, 0x40], event[:message].to_a)
          listener.close  
        end
        listener.start(:background => true)
        sleep(0.1)
        output.puts(0x90, 0x50, 0x40)
        listener.join
      end
    end
  end

end