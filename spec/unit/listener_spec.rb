# frozen_string_literal: true

require 'helper'

describe MIDIEye::Listener do
  let(:event1) { { data: [0x90, 0x30, 0x20], timestamp: Time.now } }
  let(:event2) { { data: [0x91, 0x20, 0x10], timestamp: Time.now } }
  let(:input1) { double(gets: double, buffer: [event1, event2]) }
  let(:input2) { double(gets: double, buffer: [event1, event2]) }
  let(:input3) { double(gets: double, buffer: [event1, event2]) }
  let(:listener) { MIDIEye::Listener.new(input_arg) }

  describe '#uses_input?' do
    context 'when there are multiple inputs' do
      let(:input_arg) { [input1, input2] }

      it 'returns true for those inputs' do
        expect(listener.uses_input?(input1)).to eq(true)
        expect(listener.uses_input?(input2)).to eq(true)
        expect(listener.uses_input?(input3)).to eq(false)
      end
    end

    context 'when there is one input' do
      let(:input_arg) { input1 }

      it 'returns true for that input' do
        expect(listener.uses_input?(input1)).to eq(true)
        expect(listener.uses_input?(input2)).to eq(false)
      end
    end
  end

  describe '#add_input' do
    let(:input_arg) { input1 }

    it 'adds an input' do
      expect(listener.uses_input?(input1)).to eq(true)
      expect(listener.uses_input?(input2)).to eq(false)
      listener.add_input(input2)
      expect(listener.uses_input?(input1)).to eq(true)
      expect(listener.uses_input?(input2)).to eq(true)
    end
  end

  describe '#remove_input' do
    let(:input_arg) { [input1, input2] }

    it 'removes the input' do
      expect(listener.uses_input?(input1)).to eq(true)
      expect(listener.uses_input?(input2)).to eq(true)
      listener.remove_input(input2)
      expect(listener.uses_input?(input1)).to eq(true)
      expect(listener.uses_input?(input2)).to eq(false)
    end
  end

  describe '#run' do
    let(:input_arg) { input2 }

    context 'when no background param' do
      it 'runs in background' do
        expect(listener).to receive(:listen)
        expect(listener).to_not receive(:join)
        listener.run
      end
    end

    context 'when background param is false' do
      it 'runs in foreground' do
        expect(listener).to receive(:listen)
        expect(listener).to receive(:join)
        listener.run(background: false)
      end
    end
  end

  describe '#close' do
    let(:input_arg) { input3 }

    it 'clears event handlers and sources' do
      expect(listener.event_handlers).to receive(:clear)
      expect(listener.sources).to receive(:clear)
      listener.close
    end
  end

  describe '#running?' do
    let(:input_arg) { input3 }
    after do
      listener.close
    end

    context 'when running' do
      it 'returns true' do
        listener.run(background: true)

        expect(listener.running?).to eq(true)
      end
    end

    context 'when not running' do
      it 'returns false' do
        expect(listener.running?).to eq(false)
      end
    end
  end

  describe '#join' do
    let(:input_arg) { input3 }
    it 'joins the listener thread' do
      expect_any_instance_of(Thread).to receive(:join)

      listener.run(background: true)
      listener.join
      listener.close
    end
  end

  describe '#listen_for' do
    let(:input_arg) { input3 }

    it 'adds event listener' do
      expect_any_instance_of(MIDIEye::EventHandlers).to receive(:add)

      listener.listen_for(name: :test) { |e| p e }
    end
  end

  describe '#poll' do
    let(:input_arg) { [input1, input2] }

    it 'polls each input for new messages' do
      expect(listener.sources.count).to eq(2)
      expect(listener.sources[0]).to receive(:poll).and_return(double)
      expect(listener.sources[1]).to receive(:poll).and_return(double)

      listener.poll
    end
  end
end
