# frozen_string_literal: true

dir = File.dirname(File.expand_path(__FILE__))
$LOAD_PATH.unshift("#{dir}/../lib")

require 'rspec'
require 'midi-eye'

module SpecHelper
  module_function

  def devices
    if @devices.nil?
      @devices = {}
      { input: UniMIDI::Input, output: UniMIDI::Output }.each do |type, klass|
        @devices[type] = klass.gets
      end
    end
    @devices
  end
end
