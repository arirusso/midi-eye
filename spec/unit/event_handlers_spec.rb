# frozen_string_literal: true

require 'helper'

describe MIDIEye::EventHandlers do
  let(:event_handlers) { MIDIEye::EventHandlers.new }
  let(:event_handler1) { proc { |event| "#{event} 1" } }
  let(:event_handler2) { proc { |event| "#{event} 2" } }
  let(:event1) do
    {
      message: 'a message',
      timestamp: Time.now.to_i
    }
  end
  let(:event2) do
    {
      message: 'another message',
      timestamp: Time.now.to_i
    }
  end

  describe '#delete' do
    it 'deletes an event handler' do
      expect(event_handlers.count).to eq(0)
      event_handlers.add(name: :test, &event_handler1)
      expect(event_handlers.count).to eq(1)
      event_handlers.delete(:test)
      expect(event_handlers.count).to eq(0)
    end
  end

  describe '#clear' do
    it 'deletes all event handlers' do
      expect(event_handlers.count).to eq(0)
      event_handlers.add(name: :test, &event_handler1)
      event_handlers.add(name: :test, &event_handler2)
      event_handlers.clear
      expect(event_handlers.count).to eq(0)
    end
  end

  describe '#add' do
    it 'adds an event handler' do
      expect(event_handlers.count).to eq(0)
      event_handlers.add(name: :test, &event_handler1)
      expect(event_handlers.count).to eq(1)
    end
  end

  describe '#enqueue' do
    it 'enqueues an event' do
      expect(event_handlers.count).to eq(0)
      event_handlers.add(name: :test, &event_handler1)
      event_handlers.enqueue(event1)
      event_handlers.enqueue(event2)

      expect(event_handlers.handle_enqueued).to eq(2)
    end
  end

  describe '#handle_enqueued' do
    it 'processes the events and returns the number of events processed' do
      expect(event_handler1).to receive(:call).exactly(:twice)
      expect(event_handler2).to receive(:call).exactly(:twice)
      expect(event_handlers.count).to eq(0)
      event_handlers.add(name: :test, &event_handler1)
      event_handlers.add(name: :test, &event_handler2)
      expect(event_handlers.count).to eq(2)
      event_handlers.enqueue(event1)
      event_handlers.enqueue(event2)

      expect(event_handlers.handle_enqueued).to eq(4)
    end
  end
end
