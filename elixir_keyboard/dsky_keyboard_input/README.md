# DskyKeyboardInput

Standalone Elixir program for a Raspberry Pi 4 that reads a physical **3×7
DSKY-style keyboard matrix** over GPIO and sends DSKY keypresses to
VirtualAGC / `yaAGC` over TCP.

This program is **input-only**. It does not drive the display — the existing
`ericDSKY.py` continues to own the DSKY display path. See
`../standalone_elixir_rpi4_dsky_keyboard_plan.md` for the full design.

```text
physical 3×7 keypad
  → GpioMatrix (GPIO scan)
  → Debouncer
  → EventRouter (logical key → AGC operation; PRO press/release)
  → AgcClient (TCP to 127.0.0.1:19697)
```

## Module layout

| Module        | Responsibility |
|---------------|----------------|
| `GpioMatrix`  | Opens row/column GPIO lines, scans the 3×7 matrix every `scan_interval_ms`, debounces, emits events. |
| `Debouncer`   | Pure, timestamp-based per-key debouncing → stable `:key_down`/`:key_up`. |
| `Keymap`      | `{row, col}` → logical key, and logical key → AGC `{channel, value, mask}`. |
| `EventRouter` | Routes events to AGC operations; normal keys fire on key-down, PRO fires distinct press/release. |
| `AgcPacket`   | Encodes the 4-byte yaAGC peripheral packets (mask + value), matching `ericDSKY.py` `packetize()`. |
| `AgcClient`   | Maintains the TCP connection to `yaAGC` with reconnect/backoff. |

## GPIO wiring (BCM numbering)

- Rows (outputs, idle HIGH): GPIO **17, 27, 22**
- Columns (inputs, pull-up): GPIO **5, 6, 12, 13, 16, 19, 26**
- Common ground: physical pin 6

Key layout:

| R/C | C0   | C1   | C2 | C3    | C4    | C5  | C6      |
|-----|------|------|----|-------|-------|-----|---------|
| R0  | VERB | NOUN | +  | -     | CLR   | PRO | KEY REL |
| R1  | 7    | 8    | 9  | ENTER | RESET | —   | —       |
| R2  | 4    | 5    | 6  | 1     | 2     | 3   | 0       |

## Running on the Raspberry Pi (production)

The `circuits_gpio` hardware dependency is only pulled in under `MIX_ENV=prod`:

```bash
MIX_ENV=prod mix deps.get
MIX_ENV=prod mix run --no-halt
```

Start it after `yaAGC` is up (which `test.sh` launches on port 19697). To watch
key events without sending them to yaAGC, add `--dry-run`:

```bash
MIX_ENV=prod mix run --no-halt -- --dry-run
```

Dry-run logs lines like:

```text
key_down {0,0} -> :verb -> {0o15, 0o21, 0o37}
key_down {2,6} -> {:digit, 0} -> {0o15, 0o20, 0o37}
```

## Development & tests

On a workstation there is no GPIO hardware and (here) no Hex/SSL to fetch
packages. In `dev`/`test` the `circuits_gpio` dependency is omitted and the code
uses `DskyKeyboardInput.Gpio.Stub`, so the project compiles and tests run with no
network access:

```bash
mix test
```

In `dev`, `GpioMatrix` logs a warning and idles when real GPIO is unavailable;
the rest of the supervision tree (AgcClient reconnect loop, EventRouter) runs
normally.

## yaAGC connection conflict fallback

If `yaAGC` refuses a second peripheral client while `ericDSKY.py` is connected,
fall back to the FIFO path: `ericDSKY.py` already reads tokens from
`/tmp/dsky_keys`, so Elixir can write high-level tokens there instead of opening
its own TCP connection. Prefer the direct TCP approach first.
