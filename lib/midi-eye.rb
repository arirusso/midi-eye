#
# midi-eye
# MIDI input event listener for Ruby
# https://github.com/arirusso/midi-eye
#
# (c)2011-2017 Ari Russo
# Apache 2.0 License
#

# libs
require "forwardable"
require "midi-message"
require "nibbler"
require "unimidi"

# classes
require "midi-eye/event"
require "midi-eye/listener"
require "midi-eye/source"

module MIDIEye

  VERSION = "0.3.10"

end
