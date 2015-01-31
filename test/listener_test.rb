require "helper"

class ListenerTest < Minitest::Test

  context "Listener" do

    setup do
      sleep(0.2)
      @output = TestHelper.device[:output]
      @input = TestHelper.device[:input]
      @listener = MIDIEye::Listener.new(@input)
    end

    teardown do
      @listener.close
      @input.clear_buffer
      @input.close
      @output.close
      sleep(0.5)
    end

    context "#listen_for" do

      context "no filter" do

        setup do
          @i = 0
          @listener.listen_for do |event|
            @i += 1
          end
          @listener.start(:background => true)
          sleep(0.5)
        end

        should "receive messages" do
          @output.puts(0x90, 0x40, 0x10)
          sleep(0.2)
          assert_equal 1, @i
        end

      end

      context "filter on control change" do

        context "rapid messages" do

          setup do
            @i = 0
            @listener.listen_for(:class => MIDIMessage::ControlChange) do |event|
              @i += 1
            end
            @listener.start(:background => true)
            sleep(0.5)
          end

          should "receive messages" do
            5.times do
              126.times do |i|
                @output.puts(176, 1, i+1)
              end
            end
            sleep(1)
            assert_equal(5 * 126, @i)
          end

        end

        context "normal messages" do

          setup do
            @event = nil
            @listener.listen_for(:class => MIDIMessage::ControlChange) do |event|
              @event = event
            end
            @listener.start(:background => true)
            sleep(0.5)
            @input.clear_buffer
          end

          should "receive messages" do
            @output.puts(176, 1, 35)
            sleep(0.2)
            refute_nil @event
            assert_equal(MIDIMessage::ControlChange, @event[:message].class)
            assert_equal(1, @event[:message].index)
            assert_equal(35, @event[:message].value)
            assert_equal([176, 1, 35], @event[:message].to_bytes)
          end

        end

      end

      context "filter on sysex" do

        setup do
          @event = nil
          @listener.listen_for(:class => MIDIMessage::SystemExclusive::Command) do |event|
            @event = event
          end
          @listener.start(:background => true)
          sleep(0.5)
        end

        should "receive messages" do
          @output.puts(0xF0, 0x41, 0x10, 0x42, 0x12, 0x40, 0x00, 0x7F, 0x00, 0x41, 0xF7)
          sleep(0.2)
          refute_nil @event
          assert_equal(MIDIMessage::SystemExclusive::Command, @event[:message].class)
          assert_equal([0xF0, 0x41, 0x10, 0x42, 0x12, 0x40, 0x00, 0x7F, 0x00, 0x41, 0xF7], @event[:message].to_byte_array)
        end

      end

      context "filter on note on" do

        setup do
          @event = nil
          @listener.listen_for(:class => MIDIMessage::NoteOff) do |event|
            @event = event
          end
          @listener.start(:background => true)
          sleep(0.5)
        end

        should "receive messages" do
          @output.puts(0x80, 0x50, 0x40)
          sleep(0.2)
          refute_nil @event
          assert_equal(MIDIMessage::NoteOff, @event[:message].class)
          assert_equal(0x50, @event[:message].note)
          assert_equal(0x40, @event[:message].velocity)
          assert_equal([0x80, 0x50, 0x40], @event[:message].to_bytes)
        end

      end

    end

    context "#delete_event" do

      setup do
        @event = nil
        @listener.listen_for(:listener_name => :test) do |event|
          @event = event
        end
        @output.puts(0x90, 0x70, 0x20)
        @listener.start(:background => true)
        sleep(0.5)
      end

      should "delete event" do
        assert_equal(1, @listener.event.count)
        @listener.delete_event(:test)
        assert_equal(0, @listener.event.count)
      end

    end

    context "#uses_input?" do

      should "acknowledge input" do
        assert @listener.uses_input?(@input)
      end

    end

    context "#add_input" do

      should "ignore redundant input" do
        num_sources = @listener.sources.size
        @listener.add_input(@input)
        assert_equal num_sources, @listener.sources.size
        assert_equal MIDIEye::Source, @listener.sources.last.class
      end

    end

    context "#remove_input" do

      should "remove input" do
        num_sources = @listener.sources.size
        assert num_sources > 0
        @listener.remove_input(@input)
        assert_equal num_sources - 1, @listener.sources.size
      end

    end

    context "#close" do

      setup do
        @listener.start(:background => true)
        @output.puts(0x80, 0x50, 0x40)
      end

      should "close" do
        assert @listener.close
        sleep(0.5)
        refute @listener.running?
      end

    end

  end

end
