defmodule DskyKeyboardInput.EventRouterTest do
  use ExUnit.Case, async: false

  alias DskyKeyboardInput.EventRouter

  # Test sink: forwards operations to whichever process is registered as the
  # current test sink, so assertions can run in the test process.
  defmodule TestSink do
    def send_operation(op) do
      send(Process.whereis(:event_router_test_sink), {:op, op})
      :ok
    end
  end

  setup do
    Process.register(self(), :event_router_test_sink)
    start_supervised!({EventRouter, sink: TestSink})
    :ok
  end

  test "normal key fires its operation on key_down only" do
    EventRouter.key_event(:key_down, {0, 0})
    assert_receive {:op, {0o15, 0o21, 0o37}}

    EventRouter.key_event(:key_up, {0, 0})
    refute_receive {:op, _}, 50
  end

  test "digit key routes through the keymap" do
    EventRouter.key_event(:key_down, {2, 6})
    assert_receive {:op, {0o15, 0o20, 0o37}}
  end

  test "PRO sends distinct press and release operations" do
    EventRouter.key_event(:key_down, {0, 5})
    assert_receive {:op, {0o32, 0o00000, 0o20000}}

    EventRouter.key_event(:key_up, {0, 5})
    assert_receive {:op, {0o32, 0o20000, 0o20000}}
  end

  test "unused matrix position produces no operation" do
    EventRouter.key_event(:key_down, {1, 5})
    refute_receive {:op, _}, 50
  end
end
