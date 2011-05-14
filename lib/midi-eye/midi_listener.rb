#!/usr/bin/env ruby
module MIDIEye
  
  module Listener
    
    def self.included(base)
      base.extend(ClassMethods)
    end
    
    def initialize_midi_listener
      @sources = self.class.sources.map do |hash|
        klass = case hash[:type]
          when :unimidi then UniMIDIInput
        end 
        hash[:sources].each do |source|
          klass.new(source)
        end
      end
    end
    
    def poll
      @sources.each do |input|
        events = self.class.midi_events 
        input.poll do |message|
          events.each do |action|
            condition = action[:condition].call(msg) unless action[:condition].nil?
            observer.send(action[:method], msg) if condition
          end
        end
      end
    end
    
    module ClassMethods
      
      attr_reader :midi_events, :sources
      
      def midi_event(method, options = {})
        @midi_events ||= []
        @midi_events << { :method => method, :condition => options[:when] }
      end
      
      def listen_on(sources, type)
        @sources ||= []
        @sources << { :sources => [sources].flatten, :type => type }
      end
      
    end
                
  end  
  
end