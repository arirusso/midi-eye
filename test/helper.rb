dir = File.dirname(File.expand_path(__FILE__))
$LOAD_PATH.unshift(dir + "/../lib")

require "minitest/autorun"
require "mocha/test_unit"
require "shoulda-context"

require "midi-eye"

module TestHelper

  extend self

  attr_reader :device

  def select_devices
    @device ||= {}
    { :input => UniMIDI::Input, :output => UniMIDI::Output }.each do |type, klass|
      @device[type] = klass.gets
    end
  end

end

TestHelper.select_devices
