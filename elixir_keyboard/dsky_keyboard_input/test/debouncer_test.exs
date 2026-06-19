defmodule DskyKeyboardInput.DebouncerTest do
  use ExUnit.Case, async: true

  alias DskyKeyboardInput.Debouncer

  @pos {0, 0}

  test "a press shorter than the debounce window emits nothing" do
    deb = Debouncer.new(15)

    {deb, e0} = Debouncer.update(deb, @pos, true, 0)
    assert e0 == []

    # Still within the window, still pressed.
    {deb, e1} = Debouncer.update(deb, @pos, true, 10)
    assert e1 == []

    # Released before the window elapsed: no key_down ever fires.
    {_deb, e2} = Debouncer.update(deb, @pos, false, 12)
    assert e2 == []
  end

  test "a press stable past the window emits a single key_down" do
    deb = Debouncer.new(15)

    {deb, []} = Debouncer.update(deb, @pos, true, 0)
    {deb, events} = Debouncer.update(deb, @pos, true, 15)
    assert events == [{:key_down, @pos}]

    # Further pressed readings do not re-emit.
    {_deb, again} = Debouncer.update(deb, @pos, true, 30)
    assert again == []
  end

  test "release after a committed press emits key_up once" do
    deb = Debouncer.new(15)
    {deb, [{:key_down, @pos}]} = press(deb, @pos, 0)

    {deb, []} = Debouncer.update(deb, @pos, false, 100)
    {deb, events} = Debouncer.update(deb, @pos, false, 115)
    assert events == [{:key_up, @pos}]

    {_deb, again} = Debouncer.update(deb, @pos, false, 130)
    assert again == []
  end

  test "bounce within the window does not produce events" do
    deb = Debouncer.new(15)

    # Chattering contact: each flip resets the pending timer.
    {deb, []} = Debouncer.update(deb, @pos, true, 0)
    {deb, []} = Debouncer.update(deb, @pos, false, 3)
    {deb, []} = Debouncer.update(deb, @pos, true, 6)
    {deb, []} = Debouncer.update(deb, @pos, false, 9)

    # Settles released; since stable was already false, nothing emits.
    {_deb, events} = Debouncer.update(deb, @pos, false, 30)
    assert events == []
  end

  test "update_scan debounces multiple keys independently" do
    deb = Debouncer.new(15)
    positions = [{0, 0}, {1, 0}]
    pressed = MapSet.new([{0, 0}])

    {deb, []} = Debouncer.update_scan(deb, pressed, positions, 0)
    {_deb, events} = Debouncer.update_scan(deb, pressed, positions, 15)

    assert events == [{:key_down, {0, 0}}]
  end

  defp press(deb, pos, t0) do
    {deb, []} = Debouncer.update(deb, pos, true, t0)
    Debouncer.update(deb, pos, true, t0 + 15)
  end
end
