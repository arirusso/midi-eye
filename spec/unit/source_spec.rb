# frozen_string_literal: true

require 'helper'

describe MIDIEye::Source do
  let(:event1) { { data: [0x90, 0x30, 0x20], timestamp: Time.now } }
  let(:event2) { { data: [0x91, 0x20, 0x10], timestamp: Time.now } }
  let(:message) { double }
  let(:input) { double(gets: double, buffer: [event1, event2]) }
  let(:source) { MIDIEye::Source.new(input) }
  before do
    allow_any_instance_of(Nibbler::Session).to receive(:parse).and_return(message)
  end

  describe '.compatible?' do
    context 'when device is compatible' do
      it 'returns true' do
        expect(MIDIEye::Source.compatible?(input)).to eq(true)
      end
    end

    context 'when device is not compatible' do
      let(:input) { double }

      it 'returns false' do
        expect(MIDIEye::Source.compatible?(input)).to eq(false)
      end
    end
  end

  describe '#poll' do
    it 'moves pointer to end of buffer and yields with each message' do
      expect(source.pointer).to eq(0)
      source.poll do |messages|
        expect(messages).to include(message)
      end
      expect(source.pointer).to eq(2)
    end
  end

  describe '#uses?' do
    context 'when listener is not using device' do
      it 'returns false' do
        expect(source.uses?(double)).to eq(false)
      end
    end

    context 'when listener is using device' do
      it 'returns true' do
        expect(source.uses?(input)).to eq(true)
      end
    end
  end
end
