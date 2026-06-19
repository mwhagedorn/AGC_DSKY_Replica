defmodule DskyKeyboardInput.AgcPacketTest do
  use ExUnit.Case, async: true

  alias DskyKeyboardInput.AgcPacket

  # Reference implementation mirroring ericDSKY.py's packetize(), used to
  # cross-check the Elixir encoder.
  import Bitwise

  defp ref_packetize({channel, value, mask}) do
    mask_pkt = <<
      0x20 ||| (channel >>> 3 &&& 0x0F),
      0x40 ||| (channel <<< 3 &&& 0x38) ||| (mask >>> 12 &&& 0x07),
      0x80 ||| (mask >>> 6 &&& 0x3F),
      0xC0 ||| (mask &&& 0x3F)
    >>

    value_pkt = <<
      0x00 ||| (channel >>> 3 &&& 0x0F),
      0x40 ||| (channel <<< 3 &&& 0x38) ||| (value >>> 12 &&& 0x07),
      0x80 ||| (value >>> 6 &&& 0x3F),
      0xC0 ||| (value &&& 0x3F)
    >>

    mask_pkt <> value_pkt
  end

  test "encode_operation produces 8 bytes: mask packet then value packet" do
    op = {0o15, 0o21, 0o37}
    encoded = AgcPacket.encode_operation(op)

    assert byte_size(encoded) == 8
    assert binary_part(encoded, 0, 4) == AgcPacket.encode_mask(0o15, 0o37)
    assert binary_part(encoded, 4, 4) == AgcPacket.encode_value(0o15, 0o21)
  end

  test "mask packet carries the expected leading bit signatures" do
    <<b0, b1, b2, b3>> = AgcPacket.encode_mask(0o15, 0o37)
    assert (b0 &&& 0xF0) == 0x20
    assert (b1 &&& 0xC0) == 0x40
    assert (b2 &&& 0xC0) == 0x80
    assert (b3 &&& 0xC0) == 0xC0
  end

  test "value packet carries the expected leading bit signatures" do
    <<b0, b1, b2, b3>> = AgcPacket.encode_value(0o15, 0o21)
    assert (b0 &&& 0xF0) == 0x00
    assert (b1 &&& 0xC0) == 0x40
    assert (b2 &&& 0xC0) == 0x80
    assert (b3 &&& 0xC0) == 0xC0
  end

  test "matches the ericDSKY.py packetize reference for the full key table" do
    ops = [
      {0o15, 0o20, 0o37},
      {0o15, 0o1, 0o37},
      {0o15, 0o11, 0o37},
      {0o15, 0o21, 0o37},
      {0o15, 0o37, 0o37},
      {0o15, 0o32, 0o37},
      {0o15, 0o33, 0o37},
      {0o15, 0o22, 0o37},
      {0o15, 0o36, 0o37},
      {0o15, 0o31, 0o37},
      {0o15, 0o34, 0o37},
      {0o32, 0o00000, 0o20000},
      {0o32, 0o20000, 0o20000}
    ]

    for op <- ops do
      assert AgcPacket.encode_operation(op) == ref_packetize(op)
    end
  end
end
