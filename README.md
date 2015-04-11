# MIDI EYE

MIDI input event listener for Ruby

## Install

`gem install midi-eye`

or using Bundler, add this to your Gemfile

`gem "midi-eye"`

## Usage

```ruby
require 'midi-eye'
```

The following is an example that takes any note messages received from a unimidi input, transposes them up one octave and then sends them to an output  

First, pick some MIDI IO ports

```ruby
@input = UniMIDI::Input.gets
@output = UniMIDI::Output.gets
```

Then create a listener for the input port

```ruby
transpose = MIDIEye::Listener.new(@input)
```

You can bind an event to the listener using `Listener#listen_for`

The listener will try to positively match the parameters you pass in to the properties of the messages it receives.

In this example, we specify that the listener listens for note on/off messages, which are identifiable by their class.

```ruby
transpose.listen_for(:class => [MIDIMessage::NoteOn, MIDIMessage::NoteOff]) do |event|

  # raise the note value by an octave
  event[:message].note += 12

  # send the altered note message to the output you chose earlier
  @output.puts(event[:message])

end
```

There is also the option of leaving out the parameters altogether and including using conditional if/unless/case/etc statements in the callback.

You can bind as many events to a listener as you wish by repeatedly calling `Listener#listen_for`

Once all the events are bound, start the listener

```ruby
transpose.run
```

A listener can also be run in a background thread by passing in `:background => true`.

```ruby
transpose.run(:background => true)

transpose.join # join the background thread later
```

## Documentation

* [examples](http://github.com/arirusso/midi-eye/tree/master/examples)
* [rdoc](http://rdoc.info/gems/midi-eye)

## Author

* [Ari Russo](http://github.com/arirusso) <ari.russo at gmail.com>

## License

Apache 2.0, See the file LICENSE

Copyright (c) 2011-2015 [Ari Russo](http://arirusso.com)
