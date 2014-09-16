require "helper"

class ListenerTest < Test::Unit::TestCase

  include MIDIEye
  include MIDIMessage
  include TestHelper
  
  def test_rapid_control_change_message
    sleep(0.2)
    output = $test_device[:output]
    input = $test_device[:input]
    listener = Listener.new(input)
    @i = 0
    listener.listen_for(:class => ControlChange) do |event|
      @i += 1
      if @i == 5 * 126
        close_all(input, output, listener)
        assert_equal(5 * 126, @i)
      end
    end
    listener.start(:background => true)
    sleep(0.5)
    5.times do
      126.times do |i|
        output.puts(176, 1, i+1)
      end
    end
    listener.join    
  end
  
  def test_control_change_message
    sleep(0.2)
    output = $test_device[:output]
    input = $test_device[:input]
    listener = Listener.new(input)
    listener.listen_for(:class => ControlChange) do |event|
      assert_equal(ControlChange, event[:message].class)
      assert_equal(1, event[:message].index)      
      assert_equal(35, event[:message].value)
      assert_equal([176, 1, 35], event[:message].to_bytes)
      close_all(input, output, listener)
    end
    listener.start(:background => true)
    sleep(0.5)
    output.puts(176, 1, 35)
    listener.join    
  end
  
  def test_delete_event
    sleep(0.2)
    output = $test_device[:output]
    input = $test_device[:input]
    listener = Listener.new(input)
    listener.listen_for(:listener_name => :test) do |event|
      assert_equal(1, listener.event.count)
      listener.delete_event(:test)
      assert_equal(0, listener.event.count)
      close_all(input, output, listener)
    end
    listener.start(:background => true)
    sleep(0.5)
    output.puts(0x90, 0x70, 0x20)
    listener.join 
  end
  
  def test_uses_input
    sleep(0.2)
    output = $test_device[:output]
    input = $test_device[:input]
    listener = Listener.new(input)
    assert_equal(true, listener.uses_input?(input))    
  end
  
  def test_reject_dup_input
    sleep(0.2)
    output = $test_device[:output]
    input = $test_device[:input]
    listener = Listener.new(input)
    listener.add_input(input)
    assert_equal(1, listener.sources.size)     
  end
  
  def test_remove_input
    sleep(0.2)
    output = $test_device[:output]
    input = $test_device[:input]
    listener = Listener.new(input)
    assert_equal(1, listener.sources.size)
    listener.remove_input(input)
    assert_equal(0, listener.sources.size)  
  end
  
  def test_recognize_input_class
    sleep(0.2)
    input = $test_device[:input]
    output = $test_device[:output]
    listener = Listener.new(input)
    assert_equal(Source, listener.sources.first.class)
    close_all(input, output, listener)
  end
  
  def test_listen_for_basic
    sleep(0.2)
    @i = 0
    output = $test_device[:output]
    input = $test_device[:input]
    listener = Listener.new(input)
    listener.listen_for do |event|
      @i += 1
      assert_equal(1, @i)
      close_all(input, output, listener)
    end
    listener.start(:background => true)
    sleep(0.5)
    output.puts(0x90, 0x40, 0x10)
    listener.join
  end

  def test_listen_for_sysex
    sleep(0.2)
    output = $test_device[:output]
    input = $test_device[:input]
    listener = Listener.new(input)
    listener.listen_for(:class => SystemExclusive::Command) do |event|
      assert_equal(SystemExclusive::Command, event[:message].class)
      assert_equal([0xF0, 0x41, 0x10, 0x42, 0x12, 0x40, 0x00, 0x7F, 0x00, 0x41, 0xF7], event[:message].to_byte_array)
      close_all(input, output, listener)
    end
    listener.start(:background => true)
    sleep(0.5)
    output.puts(0xF0, 0x41, 0x10, 0x42, 0x12, 0x40, 0x00, 0x7F, 0x00, 0x41, 0xF7)
    listener.join
  end
  
  def test_listen_for_note_on
    sleep(0.2)
    output = $test_device[:output]
    input = $test_device[:input]
    listener = Listener.new(input)
    listener.listen_for(:class => NoteOff) do |event|
      assert_equal(NoteOff, event[:message].class)
      assert_equal(0x50, event[:message].note)      
      assert_equal(0x40, event[:message].velocity)
      assert_equal([0x80, 0x50, 0x40], event[:message].to_bytes)
      close_all(input, output, listener)
    end
    listener.start(:background => true)
    sleep(0.5)
    output.puts(0x80, 0x50, 0x40)
    listener.join
  end
  
end
