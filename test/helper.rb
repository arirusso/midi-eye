dir = File.dirname(File.expand_path(__FILE__))
$LOAD_PATH.unshift(dir + "/../lib")

require "test/unit"
require "mocha/test_unit"
require "shoulda-context"

require "midi-eye"

module TestHelper

  extend self

  def select_devices
    $test_device ||= {}
    { :input => UniMIDI::Input, :output => UniMIDI::Output }.each do |type, klass|
      $test_device[type] = klass.gets
    end
  end

  def close_all(input, output, listener)
    listener.close
    input.clear_buffer
    input.close
    output.close
    sleep(0.1)
  end

end

TestHelper.select_devices
