defmodule DskyKeyboardInput.AgcPacket do
  @moduledoc """
  Encodes DSKY input as the 4-byte yaAGC peripheral packets.

  This is a direct port of the `packetize/1` function in `ericDSKY.py`. A single
  channel operation `{channel, value, mask}` is sent as two packets:

    1. a *mask* packet whose first byte has the high bits `0x20`, and
    2. a *value* packet whose first byte has the high bits `0x00`.

  `encode_operation/1` returns the two packets concatenated (8 bytes total).
  """

  import Bitwise

  @typedoc "An AGC channel operation: `{channel, value, mask}` (all integers)."
  @type operation :: {non_neg_integer(), non_neg_integer(), non_neg_integer()}

  @doc """
  Encode a `{channel, value, mask}` operation as the mask packet followed by the
  value packet (8 bytes).
  """
  @spec encode_operation(operation()) :: binary()
  def encode_operation({channel, value, mask}) do
    encode_mask(channel, mask) <> encode_value(channel, value)
  end

  @doc "Encode the mask packet (4 bytes, leading bits `0x20`)."
  @spec encode_mask(non_neg_integer(), non_neg_integer()) :: binary()
  def encode_mask(channel, mask) do
    <<
      0x20 ||| (channel >>> 3 &&& 0x0F),
      0x40 ||| (channel <<< 3 &&& 0x38) ||| (mask >>> 12 &&& 0x07),
      0x80 ||| (mask >>> 6 &&& 0x3F),
      0xC0 ||| (mask &&& 0x3F)
    >>
  end

  @doc "Encode the value packet (4 bytes, leading bits `0x00`)."
  @spec encode_value(non_neg_integer(), non_neg_integer()) :: binary()
  def encode_value(channel, value) do
    <<
      0x00 ||| (channel >>> 3 &&& 0x0F),
      0x40 ||| (channel <<< 3 &&& 0x38) ||| (value >>> 12 &&& 0x07),
      0x80 ||| (value >>> 6 &&& 0x3F),
      0xC0 ||| (value &&& 0x3F)
    >>
  end
end
