#!/usr/bin/env ruby
#
# midi-eye
# Transparent MIDI event listener for Ruby
# (c)2011 Ari Russo 
# licensed under the Apache 2.0 License
# 

require 'midi-message'
require 'nibbler'
require 'unimidi'

require 'midi-eye/listener'
require 'midi-eye/unimidi_input'

module MIDIEye
  
  VERSION = "0.1.8"
  
end