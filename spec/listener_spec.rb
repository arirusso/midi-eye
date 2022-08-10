# frozen_string_literal: true

require 'helper'

describe MIDIEye::Listener do
  let(:input) { SpecHelper.devices[:input] }
  let(:output) { SpecHelper.devices[:output] }
  let(:listener) { MIDIEye::Listener.new(input) }
  before { sleep 0.2 }

  after do
    listener.close
    input.clear_buffer
    input.close
    output.close
    sleep 0.5
  end

  describe '#listen_for' do
    describe 'no filter' do
      it 'receivs messages' do
        i = 0
        listener.listen_for do |_event|
          i += 1
        end
        listener.start(background: true)

        sleep 0.5

        output.puts(0x90, 0x40, 0x10)
        sleep(0.2)
        expect(i).to eq(1)
      end
    end

    describe 'filter on control change' do
      describe 'rapid messages' do
        it 'receives messages' do
          i = 0
          listener.listen_for(class: MIDIMessage::ControlChange) do
            i += 1
          end
          listener.start(background: true)

          5.times do
            126.times do |i2|
              output.puts(176, 1, i2 + 1)
              sleep 0.001
            end
          end
          expect(i).to eq(5 * 126)
        end
      end

      describe 'normal messages' do
        it 'receives messages' do
          event = nil
          listener.listen_for(class: MIDIMessage::ControlChange) do |e|
            event = e
          end
          listener.start(background: true)
          sleep 0.5
          input.clear_buffer

          output.puts(176, 1, 35)
          sleep 0.2
          expect(event).to_not be_nil
          expect(event[:message]).to be_a(MIDIMessage::ControlChange)
          expect(event[:message].index).to eq(1)
          expect(event[:message].value).to eq(35)
          expect(event[:message].to_bytes).to eq([176, 1, 35])
        end
      end
    end

    describe 'filter on sysex' do
      it 'receives messages' do
        event = nil
        listener.listen_for(class: MIDIMessage::SystemExclusive::Command) do |e|
          event = e
        end
        listener.start(background: true)
        sleep 0.5

        output.puts(0xF0, 0x41, 0x10, 0x42, 0x12, 0x40, 0x00, 0x7F, 0x00, 0x41, 0xF7)
        sleep 0.2
        expect(event).to_not be_nil
        expect(event[:message]).to be_a(MIDIMessage::SystemExclusive::Command)
        expect(event[:message].to_byte_array).to eq([0xF0, 0x41, 0x10, 0x42, 0x12, 0x40, 0x00, 0x7F, 0x00, 0x41, 0xF7])
      end
    end

    describe 'filter on note on' do
      it 'receives messages' do
        event = nil
        listener.listen_for(class: MIDIMessage::NoteOff) do |e|
          event = e
        end
        listener.start(background: true)
        sleep 0.5

        output.puts(0x80, 0x50, 0x40)
        sleep 0.2
        expect(event).to_not be_nil
        expect(event[:message]).to be_a(MIDIMessage::NoteOff)
        expect(event[:message].note).to eq(0x50)
        expect(event[:message].velocity).to eq(0x40)
        expect(event[:message].to_bytes).to eq([0x80, 0x50, 0x40])
      end
    end
  end

  describe '#delete_event' do
    it 'deletes event' do
      event = nil
      listener.listen_for(listener_name: :test) do |e|
        event = e
      end
      output.puts(0x90, 0x70, 0x20)
      listener.start(background: true)
      sleep 0.5

      expect(listener.event.count).to eq(1)
      listener.delete_event(:test)
      expect(listener.event.count).to eq(0)
    end
  end

  describe '#uses_input?' do
    it 'acknowledges input' do
      expect(listener.uses_input?(input)).to be(true)
    end
  end

  describe '#add_input' do
    it 'ignores redundant input' do
      num_sources = listener.sources.size
      listener.add_input(input)
      expect(listener.sources.size).to eq(num_sources)
      expect(listener.sources.last).to be_a(MIDIEye::Source)
    end
  end

  describe '#remove_input' do
    it 'removes input' do
      num_sources = listener.sources.size
      expect(num_sources).to be > 0
      listener.remove_input(input)
      expect(listener.sources.size).to eq(num_sources - 1)
    end
  end

  describe '#close' do
    before do
      listener.start(background: true)
      output.puts(0x80, 0x50, 0x40)
    end

    it 'closes' do
      expect(listener.close).to be_truthy
      sleep 0.5
      expect(listener.running?).to be(false)
    end
  end
end
