require "helper"

class ListenerTest < Test::Unit::TestCase

  context "Listener" do

    setup do
      sleep(0.2)
      @output = $test_device[:output]
      @input = $test_device[:input]
      @listener = MIDIEye::Listener.new(@input)
    end

    context "#listen_for" do

      context "no filter" do

        setup do
          @i = 0
          @listener.listen_for do |event|
            @i += 1
            assert_equal(1, @i)
            TestHelper.close_all(@input, @output, @listener)
          end
          @listener.start(:background => true)
          sleep(0.5)
        end

        should "receive messages" do
          @output.puts(0x90, 0x40, 0x10)
          @listener.join
        end

      end

      context "filter on control change" do

        context "rapid messages" do

          setup do
            @i = 0
            @listener.listen_for(:class => MIDIMessage::ControlChange) do |event|
              @i += 1
              if @i == 5 * 126
                TestHelper.close_all(@input, @output, @listener)
                assert_equal(5 * 126, @i)
              end
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
            @listener.join
          end

        end

        context "normal messages" do

          setup do
            @listener.listen_for(:class => MIDIMessage::ControlChange) do |event|
              assert_equal(MIDIMessage::ControlChange, event[:message].class)
              assert_equal(1, event[:message].index)
              assert_equal(35, event[:message].value)
              assert_equal([176, 1, 35], event[:message].to_bytes)
              TestHelper.close_all(@input, @output, @listener)
            end
            @listener.start(:background => true)
            sleep(0.5)
          end

          should "receive messages" do
            @output.puts(176, 1, 35)
            @listener.join
          end

        end

      end

      context "filter on sysex" do

        setup do
          @listener.listen_for(:class => MIDIMessage::SystemExclusive::Command) do |event|
            assert_equal(MIDIMessage::SystemExclusive::Command, event[:message].class)
            assert_equal([0xF0, 0x41, 0x10, 0x42, 0x12, 0x40, 0x00, 0x7F, 0x00, 0x41, 0xF7], event[:message].to_byte_array)
            TestHelper.close_all(@input, @output, @listener)
          end
          @listener.start(:background => true)
          sleep(0.5)
        end

        should "receive messages" do
          @output.puts(0xF0, 0x41, 0x10, 0x42, 0x12, 0x40, 0x00, 0x7F, 0x00, 0x41, 0xF7)
          @listener.join
        end

      end

      context "filter on note on" do

        setup do
          @listener.listen_for(:class => MIDIMessage::NoteOff) do |event|
            assert_equal(MIDIMessage::NoteOff, event[:message].class)
            assert_equal(0x50, event[:message].note)
            assert_equal(0x40, event[:message].velocity)
            assert_equal([0x80, 0x50, 0x40], event[:message].to_bytes)
            TestHelper.close_all(@input, @output, @listener)
          end
          @listener.start(:background => true)
          sleep(0.5)
        end

        should "receive messages" do
          @output.puts(0x80, 0x50, 0x40)
          @listener.join
        end

      end

    end

    context "#delete_event" do

      setup do
        @listener.listen_for(:listener_name => :test) do |event|
          assert_equal(1, @listener.event.count)
          @listener.delete_event(:test)
          assert_equal(0, @listener.event.count)
          TestHelper.close_all(@input, @output, @listener)
        end
        @listener.start(:background => true)
        sleep(0.5)
      end

      should "receive messages" do
        @output.puts(0x90, 0x70, 0x20)
        @listener.join
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
        @listener.listen_for(:class => MIDIMessage::NoteOff) do |event|
          TestHelper.close_all(@input, @output, @listener)
        end
        @listener.start(:background => true)
        sleep(0.5)
        @output.puts(0x80, 0x50, 0x40)
        @listener.join
      end

      should "close" do
        assert @listener.close
        refute @listener.running?
      end

    end

  end

end
