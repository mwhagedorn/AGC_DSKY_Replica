defmodule DskyKeyboardInput.Keymap do
  @moduledoc """
  Maps physical matrix positions to logical DSKY keys, and logical keys to the
  AGC channel operations used by `ericDSKY.py`.

  Matrix layout (3 rows x 7 columns), per the project plan:

      | R/C | C0   | C1   | C2  | C3    | C4    | C5      | C6      |
      | R0  | VERB | NOUN | +   | -     | CLR   | PRO     | KEY REL |
      | R1  | 7    | 8    | 9   | ENTER | RESET | UNUSED  | UNUSED  |
      | R2  | 4    | 5    | 6   | 1     | 2     | 3       | 0       |

  Channel/value/mask values mirror the `parseDskyKey` table in `ericDSKY.py`.
  The `PRO` key is special: it has distinct pressed and released operations and
  is therefore handled by `EventRouter` via `pro_pressed/0` and `pro_released/0`
  rather than `operation_for_key/1`.
  """

  alias DskyKeyboardInput.AgcPacket

  @type logical_key ::
          :verb
          | :noun
          | :plus
          | :minus
          | :clear
          | :pro
          | :key_rel
          | :enter
          | :reset
          | {:digit, 0..9}

  @keycode_channel 0o15
  @pro_channel 0o32
  @keycode_mask 0o37
  @pro_mask 0o20000

  # DSKY 5-bit keycodes for the decimal digits (channel 0o15).
  @digit_codes %{
    0 => 0o20,
    1 => 0o1,
    2 => 0o2,
    3 => 0o3,
    4 => 0o4,
    5 => 0o5,
    6 => 0o6,
    7 => 0o7,
    8 => 0o10,
    9 => 0o11
  }

  @doc """
  Translate a `{row, col}` matrix position into a logical DSKY key.

  Returns `nil` for the two unused positions (`{1, 5}` and `{1, 6}`).
  """
  @spec key_for_position({non_neg_integer(), non_neg_integer()}) :: logical_key() | nil
  def key_for_position({0, 0}), do: :verb
  def key_for_position({0, 1}), do: :noun
  def key_for_position({0, 2}), do: :plus
  def key_for_position({0, 3}), do: :minus
  def key_for_position({0, 4}), do: :clear
  def key_for_position({0, 5}), do: :pro
  def key_for_position({0, 6}), do: :key_rel

  def key_for_position({1, 0}), do: {:digit, 7}
  def key_for_position({1, 1}), do: {:digit, 8}
  def key_for_position({1, 2}), do: {:digit, 9}
  def key_for_position({1, 3}), do: :enter
  def key_for_position({1, 4}), do: :reset
  def key_for_position({1, 5}), do: nil
  def key_for_position({1, 6}), do: nil

  def key_for_position({2, 0}), do: {:digit, 4}
  def key_for_position({2, 1}), do: {:digit, 5}
  def key_for_position({2, 2}), do: {:digit, 6}
  def key_for_position({2, 3}), do: {:digit, 1}
  def key_for_position({2, 4}), do: {:digit, 2}
  def key_for_position({2, 5}), do: {:digit, 3}
  def key_for_position({2, 6}), do: {:digit, 0}

  def key_for_position(_), do: nil

  @doc """
  Translate a logical key into its AGC `{channel, value, mask}` operation.

  Returns `nil` for `:pro` (handled separately) and for unknown keys.
  """
  @spec operation_for_key(logical_key() | nil) :: AgcPacket.operation() | nil
  def operation_for_key({:digit, n}) when is_map_key(@digit_codes, n) do
    {@keycode_channel, @digit_codes[n], @keycode_mask}
  end

  def operation_for_key(:verb), do: {@keycode_channel, 0o21, @keycode_mask}
  def operation_for_key(:noun), do: {@keycode_channel, 0o37, @keycode_mask}
  def operation_for_key(:plus), do: {@keycode_channel, 0o32, @keycode_mask}
  def operation_for_key(:minus), do: {@keycode_channel, 0o33, @keycode_mask}
  def operation_for_key(:clear), do: {@keycode_channel, 0o36, @keycode_mask}
  def operation_for_key(:key_rel), do: {@keycode_channel, 0o31, @keycode_mask}
  def operation_for_key(:enter), do: {@keycode_channel, 0o34, @keycode_mask}
  def operation_for_key(:reset), do: {@keycode_channel, 0o22, @keycode_mask}
  def operation_for_key(_), do: nil

  @doc "AGC operation for the PRO key being pressed."
  @spec pro_pressed() :: AgcPacket.operation()
  def pro_pressed, do: {@pro_channel, 0o00000, @pro_mask}

  @doc "AGC operation for the PRO key being released."
  @spec pro_released() :: AgcPacket.operation()
  def pro_released, do: {@pro_channel, @pro_mask, @pro_mask}
end
