defmodule DskyKeyboardInput.KeymapTest do
  use ExUnit.Case, async: true

  alias DskyKeyboardInput.Keymap

  describe "key_for_position/1" do
    test "row 0" do
      assert Keymap.key_for_position({0, 0}) == :verb
      assert Keymap.key_for_position({0, 1}) == :plus
      assert Keymap.key_for_position({0, 2}) == {:digit, 7}
      assert Keymap.key_for_position({0, 3}) == {:digit, 8}
      assert Keymap.key_for_position({0, 4}) == {:digit, 9}
      assert Keymap.key_for_position({0, 5}) == :clear
      assert Keymap.key_for_position({0, 6}) == :enter
    end

    test "row 1 digits and control keys" do
      assert Keymap.key_for_position({1, 0}) == :noun
      assert Keymap.key_for_position({1, 1}) == :minus
      assert Keymap.key_for_position({1, 2}) == {:digit, 4}
      assert Keymap.key_for_position({1, 3}) == {:digit, 5}
      assert Keymap.key_for_position({1, 4}) == {:digit, 6}
      assert Keymap.key_for_position({1, 5}) == :pro
    end

    test "row 2" do
      assert Keymap.key_for_position({2, 0}) == nil
      assert Keymap.key_for_position({2, 1}) == {:digit, 0}
      assert Keymap.key_for_position({2, 2}) == {:digit, 1}
      assert Keymap.key_for_position({2, 3}) == {:digit, 2}
      assert Keymap.key_for_position({2, 4}) == {:digit, 3}
      assert Keymap.key_for_position({2, 5}) == :key_rel
      assert Keymap.key_for_position({2, 6}) == nil
    end

    test "unused positions are nil" do
      assert Keymap.key_for_position({2, 0}) == nil
      assert Keymap.key_for_position({2, 6}) == nil
      assert Keymap.key_for_position({9, 9}) == nil
    end
  end

  describe "operation_for_key/1 matches ericDSKY.py parseDskyKey" do
    test "digits" do
      assert Keymap.operation_for_key({:digit, 0}) == {0o15, 0o20, 0o37}
      assert Keymap.operation_for_key({:digit, 1}) == {0o15, 0o1, 0o37}
      assert Keymap.operation_for_key({:digit, 2}) == {0o15, 0o2, 0o37}
      assert Keymap.operation_for_key({:digit, 3}) == {0o15, 0o3, 0o37}
      assert Keymap.operation_for_key({:digit, 4}) == {0o15, 0o4, 0o37}
      assert Keymap.operation_for_key({:digit, 5}) == {0o15, 0o5, 0o37}
      assert Keymap.operation_for_key({:digit, 6}) == {0o15, 0o6, 0o37}
      assert Keymap.operation_for_key({:digit, 7}) == {0o15, 0o7, 0o37}
      assert Keymap.operation_for_key({:digit, 8}) == {0o15, 0o10, 0o37}
      assert Keymap.operation_for_key({:digit, 9}) == {0o15, 0o11, 0o37}
    end

    test "control keys" do
      assert Keymap.operation_for_key(:verb) == {0o15, 0o21, 0o37}
      assert Keymap.operation_for_key(:noun) == {0o15, 0o37, 0o37}
      assert Keymap.operation_for_key(:plus) == {0o15, 0o32, 0o37}
      assert Keymap.operation_for_key(:minus) == {0o15, 0o33, 0o37}
      assert Keymap.operation_for_key(:clear) == {0o15, 0o36, 0o37}
      assert Keymap.operation_for_key(:key_rel) == {0o15, 0o31, 0o37}
      assert Keymap.operation_for_key(:enter) == {0o15, 0o34, 0o37}
      assert Keymap.operation_for_key(:reset) == {0o15, 0o22, 0o37}
    end

    test "pro has no plain operation; uses dedicated press/release" do
      assert Keymap.operation_for_key(:pro) == nil
      assert Keymap.pro_pressed() == {0o32, 0o00000, 0o20000}
      assert Keymap.pro_released() == {0o32, 0o20000, 0o20000}
    end

    test "unknown keys return nil" do
      assert Keymap.operation_for_key(:nonsense) == nil
      assert Keymap.operation_for_key(nil) == nil
    end
  end
end
