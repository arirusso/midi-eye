#!/usr/bin/env ruby

require 'helper'

class ListenerTest < Test::Unit::TestCase

  include MIDIEye
  include TestHelper
  include TestHelper::Config # edit this module to change hardware settings
  
  def test_input_class
    listener = Listener.new(TestInput)
    assert_equal(UniMIDIInput, listener.sources.first.class)
  end

end