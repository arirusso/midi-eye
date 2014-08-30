module MIDIEye
  
  class Listener
    
    attr_reader :events 
    attr_accessor :sources
      
    @input_types = []
      
    class << self
      # A registry of input types
      attr_reader :input_types      
    end
        
    def initialize(input, options = {})
      @sources = []
      @event_queue = []
      @events = []
  
      add_input(input)
    end
    
    # Does this listener use the given input?
    # @return [Boolean]
    def uses_input?(input)
      @sources.any? { |source| source.uses?(input) }
    end
    
    # Add a MIDI source
    # takes a raw input or array of
    # @param [Array<UniMIDI::Input>, UniMIDI::Input] inputs Input(s) to add to the list of sources for this listener
    # @return [Array<MIDIEye::UniMIDIInput>] The updated list of sources for this listener
    def add_input(inputs)
      inputs = [inputs].flatten.compact
      new_sources = inputs.map do |i|
        klass = self.class.input_types.find { |type| type.compatible?(i) }
        raise "Input class type #{i.class.name} not compatible" if klass.nil?
        klass.new(i) unless uses_input?(i)
      end
      @sources += new_sources.compact
      @sources
    end
    
    # Remove a MIDI source
    # @param [Array<UniMIDI::Input>, UniMIDI::Input] inputs Input(s) to remove from the list of sources for this listener
    # @return [Array<MIDIEye::UniMIDIInput>] The updated list of sources for this listener
    def remove_input(inputs)
      inputs = [inputs].flatten.compact
      inputs.each do |input|
        @sources.delete_if { |source| source.uses?(input) }
      end
      @sources
    end
    
    def delete_event(name)
      @events.delete_if { |event| event[:listener_name] == name }
    end
    
    # Start listening for MIDI messages
    # @params [Hash] options
    # @option options [Boolean] :background Run in a background thread
    # @return [MIDIEye::Listener] self
    def run(options = {})      
      listen
      @listener.join unless !!options[:background]
      self
    end
    alias_method :start, :run
    
    # Stop listening for MIDI messages.
    # @return [MIDIEye::Listener] self
    def close
      @listener.kill unless @listener.nil?
      @events.clear
      @sources.clear
      @event_queue.clear
      self
    end
    alias_method :stop, :close
    
    # Join the listener if it's being run in the background.
    # @return [MIDIEye::Listener] self
    def join
      @listener.join
      self
    end
    
    # Add an event to listen for
    # @return [MIDIEye::Listener] self
    def listen_for(options = {}, &callback)
      raise "Listener must have a block" if callback.nil?
      name = options[:listener_name]
      options.delete(:listener_name)
      event = { 
        :conditions => options, 
        :proc => callback, 
        :listener_name => name 
      }
      @events << event
      self      
    end
    alias_method :on_message, :listen_for
    alias_method :listen, :listen_for
    
    # Poll the input source for new input. this will normally be done by the background thread 
    def poll
      @sources.each do |input|
        input.poll do |objs|
          objs.each do |batch|
            messages = [batch[:messages]].flatten.compact
            messages.each do |message|
              unless message.nil?
                data = { :message => message, :timestamp => batch[:timestamp] }
                @events.each { |name| queue_event(name, data) }
              end
            end 
          end
        end
      end
    end

    private

    # A loop that runs while the listener is active
    def listen_loop
      interval = 1.0/1000
      loop do
        poll
        trigger_queued_events unless @event_queue.empty?
        sleep(interval)
      end
    end
    
    # Start the background listener thread    
    def listen   
      @listener = Thread.new { listen_loop }       
      @listener.abort_on_exception = true
      true
    end
    
    # Trigger all queued events
    def trigger_queued_events
      @event_queue.length.times { trigger_event(@event_queue.shift) }
    end
    
    # Does the given message meet the given conditions?
    def meets_conditions?(conditions, message)
      results = conditions.map do |key, value|
        if message.respond_to?(key)
          if value.kind_of?(Array)
            value.include?(message.send(key))
          else
            value.eql?(message.send(key))
          end
        else
          false
        end
      end
      results.all?
    end
    
    # Trigger an event
    def trigger_event(event)
      action = event[:action]
      conditions = action[:conditions]
      if conditions.nil? || meets_conditions?(conditions, event[:message][:message])
        begin
          action[:proc].call(event[:message])
        rescue
          # help
        end
      end
    end
    
    # Add an event to the trigger queue 
    def queue_event(action, message)  
      event = { 
        :action => action, 
        :message => message 
      }
      @event_queue << event
    end
                
  end  
  
end
