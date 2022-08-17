# frozen_string_literal: true

require 'unimidi'

module IntegrationSpecHelper
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
