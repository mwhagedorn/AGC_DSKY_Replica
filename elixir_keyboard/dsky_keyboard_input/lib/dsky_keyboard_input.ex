defmodule DskyKeyboardInput do
  @moduledoc """
  Standalone Raspberry Pi 4 keyboard-input bridge for VirtualAGC / yaAGC.

  This application is **input only**: it scans a physical 3x7 DSKY-style key
  matrix over GPIO and sends the corresponding DSKY keypresses to yaAGC over TCP.
  It does not drive the DSKY display — the existing `ericDSKY.py` continues to
  own the display path.

  Pipeline:

      physical 3x7 keypad
        -> GpioMatrix (GPIO scan)
        -> Debouncer
        -> EventRouter (logical key -> AGC operation; PRO press/release)
        -> AgcClient (TCP to 127.0.0.1:19697)

  See `standalone_elixir_rpi4_dsky_keyboard_plan.md` for the full design.
  """
end
