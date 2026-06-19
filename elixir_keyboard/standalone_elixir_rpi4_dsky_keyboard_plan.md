# Standalone Elixir Keyboard Input Plan for Raspberry Pi 4 + VirtualAGC DSKY

## Purpose

Write a standalone Elixir program for a Raspberry Pi 4 Model B that reads a physical 3×7 DSKY-style keyboard matrix and sends DSKY keypresses into VirtualAGC/`yaAGC`.

This program is **input-only**. It does **not** drive the display and does **not** replace the existing `AGC_DSKY_Replica` display project. The existing Python display script can continue to run and update the Raspberry Pi/Arduino/Nextion display stack.

The Elixir program’s job is:

```text
Physical 3×7 keypad
  → Raspberry Pi GPIO
  → standalone Elixir scanner
  → DSKY key mapping
  → yaAGC TCP channel packets
```

## Existing Project Context

Repository:

```text
https://github.com/mwhagedorn/AGC_DSKY_Replica
```

Relevant existing files:

```text
Python Scripts/ericDSKY.py
Python Scripts/test.sh
```

Important observations from the existing codebase:

1. `test.sh` starts `yaAGC` with:

   ```bash
   ./yaAGC --port=19697 --core=../Colossus249/Colossus249.bin
   ```

2. `ericDSKY.py` defaults to connecting to `localhost:19697`.

3. `ericDSKY.py` already contains the DSKY key mapping and `packetize()` logic.

4. The existing Python script polls keyboard input through `inputsForAGC()` and `get_char_keyboard_nonblock()`.

5. This standalone Elixir program should reproduce the **input side only**, using the same key mapping and packet format.

## Target Hardware

- Raspberry Pi 4 Model B
- Standalone Elixir already installed
- Physical 3×7 matrix keyboard
- Existing VirtualAGC install
- Existing `AGC_DSKY_Replica` display wiring/code remains in place

## Hardware: 3×7 Keyboard Matrix

### Matrix Size

```text
3 rows × 7 columns = 21 possible keys
```

### GPIO Required

```text
3 row GPIO outputs + 7 column GPIO inputs = 10 GPIO pins
```

## GPIO Connection Table

Use **BCM GPIO numbering in code**.

### Rows: Outputs

| Matrix Row | BCM GPIO | Physical Pin | Direction | Purpose |
|---|---:|---:|---|---|
| R0 | GPIO17 | Pin 11 | Output | Driven LOW during scan |
| R1 | GPIO27 | Pin 13 | Output | Driven LOW during scan |
| R2 | GPIO22 | Pin 15 | Output | Driven LOW during scan |

### Columns: Inputs with Pull-ups

| Matrix Column | BCM GPIO | Physical Pin | Direction | Purpose |
|---|---:|---:|---|---|
| C0 | GPIO5  | Pin 29 | Input | Read with pull-up |
| C1 | GPIO6  | Pin 31 | Input | Read with pull-up |
| C2 | GPIO12 | Pin 32 | Input | Read with pull-up |
| C3 | GPIO13 | Pin 33 | Input | Read with pull-up |
| C4 | GPIO16 | Pin 36 | Input | Read with pull-up |
| C5 | GPIO19 | Pin 35 | Input | Read with pull-up |
| C6 | GPIO26 | Pin 37 | Input | Read with pull-up |

### Reference Ground

| Purpose | Physical Pin | Notes |
|---|---:|---|
| GND | Pin 6 | Common reference ground |

## Wiring Rule Per Key

Each key should be wired:

```text
ROW ──[ SWITCH ]──|>|── COLUMN
```

Rules:

- One diode per key is strongly recommended.
- Diode direction: row side → column side.
- Columns use internal pull-ups.
- Rows are normally HIGH.
- During scan, drive one row LOW at a time.
- A pressed key reads as LOW on the matching column while its row is active.

## Proposed 3×7 Key Layout

This is a practical 21-position layout. Adjust later if your physical panel differs.

| Row/Col | C0 | C1 | C2 | C3 | C4 | C5 | C6 |
|---|---|---|---|---|---|---|---|
| R0 | VERB | NOUN | + | - | CLR | PRO | KEY REL |
| R1 | 7 | 8 | 9 | ENTER | RESET | UNUSED | UNUSED |
| R2 | 4 | 5 | 6 | 1 | 2 | 3 | 0 |

Notes:

- `KEY REL` maps to the existing Python key `K`.
- `CLR` maps to `C`.
- `ENTER` maps to `E`.
- `PRO` is special in the existing Python code: press and release are represented as `P` and `PR`. The Elixir implementation should handle this explicitly.
- `RESET` maps to `R`, but be careful: the Python script also uses repeated `R` presses to exit. The Elixir program should not inherit that exit behavior.

## Existing DSKY Key Mapping to Preserve

Mirror the key mapping already used by `ericDSKY.py`.

| Logical Key | Python Input Char | AGC Channel | Value | Mask |
|---|---|---:|---:|---:|
| 0 | `0` | `0o15` | `0o20` | `0o37` |
| 1 | `1` | `0o15` | `0o1`  | `0o37` |
| 2 | `2` | `0o15` | `0o2`  | `0o37` |
| 3 | `3` | `0o15` | `0o3`  | `0o37` |
| 4 | `4` | `0o15` | `0o4`  | `0o37` |
| 5 | `5` | `0o15` | `0o5`  | `0o37` |
| 6 | `6` | `0o15` | `0o6`  | `0o37` |
| 7 | `7` | `0o15` | `0o7`  | `0o37` |
| 8 | `8` | `0o15` | `0o10` | `0o37` |
| 9 | `9` | `0o15` | `0o11` | `0o37` |
| + | `+` | `0o15` | `0o32` | `0o37` |
| - | `-` | `0o15` | `0o33` | `0o37` |
| VERB | `V` | `0o15` | `0o21` | `0o37` |
| NOUN | `N` | `0o15` | `0o37` | `0o37` |
| RESET | `R` | `0o15` | `0o22` | `0o37` |
| CLR | `C` | `0o15` | `0o36` | `0o37` |
| KEY REL | `K` | `0o15` | `0o31` | `0o37` |
| ENTER | `E` | `0o15` | `0o34` | `0o37` |
| PRO press | `P` | `0o32` | `0o00000` | `0o20000` |
| PRO release | `PR` | `0o32` | `0o20000` | `0o20000` |

## Software Architecture

Create a standalone Mix project, for example:

```bash
cd ~/projects
mix new dsky_keyboard_input --sup
cd dsky_keyboard_input
```

Recommended module layout:

```text
lib/
  dsky_keyboard_input/
    application.ex
    gpio_matrix.ex
    debouncer.ex
    keymap.ex
    agc_client.ex
    agc_packet.ex
    event_router.ex

config/
  config.exs

test/
  keymap_test.exs
  agc_packet_test.exs
  debouncer_test.exs
```

## Dependencies

Because Elixir is already installed standalone on the Pi, keep this as a normal Mix application rather than a Nerves firmware project.

Add `circuits_gpio` to `mix.exs`:

```elixir
defp deps do
  [
    {:circuits_gpio, "~> 2.1"}
  ]
end
```

Then run:

```bash
mix deps.get
mix compile
```

If dependency installation is unavailable on the Pi, an alternative is to use Erlang ports to call a tiny Python or C GPIO helper. Prefer `Circuits.GPIO` first.

## Configuration

Use `config/config.exs`:

```elixir
import Config

config :dsky_keyboard_input,
  agc_host: '127.0.0.1',
  agc_port: 19697,
  scan_interval_ms: 5,
  debounce_ms: 15,
  rows: [17, 27, 22],
  cols: [5, 6, 12, 13, 16, 19, 26]
```

## Runtime Process Design

Use a small OTP supervision tree:

```text
DskyKeyboardInput.Application
  ├── DskyKeyboardInput.AgcClient
  ├── DskyKeyboardInput.EventRouter
  └── DskyKeyboardInput.GpioMatrix
```

### `GpioMatrix`

Responsibilities:

- Open row pins as outputs.
- Open column pins as inputs with pull-ups.
- Scan the 3×7 matrix every `scan_interval_ms`.
- Track raw pressed/released state.
- Send raw events to `EventRouter`.

GPIO setup:

```elixir
{:ok, row_gpio} = Circuits.GPIO.open(pin, :output)
{:ok, col_gpio} = Circuits.GPIO.open(pin, :input, pull_mode: :pullup)
```

Scanning algorithm:

```text
Set all rows HIGH
For each row:
  Drive current row LOW
  short settle delay
  Read every column
  If column reads LOW, key is pressed
  Drive current row HIGH
Compare against previous matrix state
Emit changes
```

### `Debouncer`

Responsibilities:

- Maintain per-key state.
- Ignore changes that are unstable for less than `debounce_ms`.
- Emit only clean `:key_down` and `:key_up` events.

Use timestamp-based debouncing, not `Process.sleep` per key.

### `Keymap`

Responsibilities:

- Convert `{row, col}` into a logical DSKY key.
- Convert logical key into an AGC channel tuple.

Example logical mapping:

```elixir
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

def key_for_position({2, 0}), do: {:digit, 4}
def key_for_position({2, 1}), do: {:digit, 5}
def key_for_position({2, 2}), do: {:digit, 6}
def key_for_position({2, 3}), do: {:digit, 1}
def key_for_position({2, 4}), do: {:digit, 2}
def key_for_position({2, 5}), do: {:digit, 3}
def key_for_position({2, 6}), do: {:digit, 0}
```

### `AgcPacket`

Responsibilities:

- Encode the same 4-byte AGC peripheral packet format used by `ericDSKY.py`.
- For each channel operation, send a mask packet followed by a value packet.

The existing Python `packetize(tuple)` sends:

1. Mask packet, with the high bit pattern beginning `0x20`.
2. Actual data packet, with the high bit pattern beginning `0x00`.

Elixir equivalent:

```elixir
defmodule DskyKeyboardInput.AgcPacket do
  use Bitwise

  def encode_operation({channel, value, mask}) do
    encode_mask(channel, mask) <> encode_value(channel, value)
  end

  def encode_mask(channel, mask) do
    <<
      0x20 ||| ((channel >>> 3) &&& 0x0F),
      0x40 ||| ((channel <<< 3) &&& 0x38) ||| ((mask >>> 12) &&& 0x07),
      0x80 ||| ((mask >>> 6) &&& 0x3F),
      0xC0 ||| (mask &&& 0x3F)
    >>
  end

  def encode_value(channel, value) do
    <<
      0x00 ||| ((channel >>> 3) &&& 0x0F),
      0x40 ||| ((channel <<< 3) &&& 0x38) ||| ((value >>> 12) &&& 0x07),
      0x80 ||| ((value >>> 6) &&& 0x3F),
      0xC0 ||| (value &&& 0x3F)
    >>
  end
end
```

### `AgcClient`

Responsibilities:

- Maintain TCP connection to `yaAGC` on `127.0.0.1:19697`.
- Reconnect if `yaAGC` restarts.
- Send encoded DSKY input packets.

Important:

- The existing `test.sh` uses port `19697`.
- Do not hardcode a different port unless you also change the VirtualAGC launch script.

### `EventRouter`

Responsibilities:

- Receive debounced `:key_down` / `:key_up` events.
- Only send most keys on `:key_down`.
- Handle `PRO` specially:
  - On `:key_down`, send `{0o32, 0o00000, 0o20000}`.
  - On `:key_up`, send `{0o32, 0o20000, 0o20000}`.

For all normal DSKY keys, send the corresponding channel tuple on `:key_down` only.

## Key Handling Rules

### Normal keys

For digits, `VERB`, `NOUN`, `ENTER`, `CLR`, `KEY REL`, `+`, `-`, and `RESET`:

```text
On key_down: send one AGC channel operation
On key_up: do nothing
```

### PRO key

For `PRO`:

```text
On key_down: send PRO pressed state
On key_up: send PRO released state
```

Do not emulate the Python script’s 0.75-second timeout unless physical key release events are unreliable.

## Integration with Existing Startup

Current existing `test.sh`:

```bash
screen -dm bash -c "cd /home/pi/virtualagc/yaAGC/; ./yaAGC --port=19697 --core=../Colossus249/Colossus249.bin"
cd /home/pi/virtualagc/piPeripheral/
python3 ericDSKY.py
```

Add the Elixir input process after `yaAGC` starts. Example:

```bash
screen -dm bash -c "cd /home/pi/virtualagc/yaAGC/; ./yaAGC --port=19697 --core=../Colossus249/Colossus249.bin"
sleep 2
screen -dm bash -c "cd /home/pi/virtualagc/piPeripheral/; python3 ericDSKY.py"
screen -dm bash -c "cd /home/pi/projects/dsky_keyboard_input; MIX_ENV=prod mix run --no-halt"
```

If `yaAGC` only accepts one peripheral client in your installed version, use the alternate IPC strategy below.

## Alternate Strategy if Multiple yaAGC TCP Clients Conflict

If the standalone Elixir process cannot connect to `yaAGC` while `ericDSKY.py` is running, do **not** duplicate display logic.

Instead:

1. Modify `ericDSKY.py` to read key tokens from a FIFO such as `/tmp/dsky_keys`.
2. Keep `ericDSKY.py` as the single process connected to `yaAGC`.
3. Make Elixir write high-level tokens to the FIFO:

```text
VERB
NOUN
1
2
3
ENTER
PRO_DOWN
PRO_UP
```

This keeps Python responsible for `packetize()` and display output, while Elixir remains responsible only for physical keyboard input.

Prefer the direct Elixir-to-yaAGC approach first because it avoids modifying the existing Python display script.

## Testing Plan

### 1. Unit tests

Create tests for:

- Matrix position → logical key mapping.
- Logical key → AGC tuple mapping.
- AGC tuple → 8-byte encoded mask+value packet.
- PRO down/up behavior.
- Debounce behavior.

### 2. GPIO dry-run mode

Add a dry-run mode that logs key events without connecting to `yaAGC`:

```bash
MIX_ENV=dev mix run --no-halt -- --dry-run
```

Expected output:

```text
key_down {0,0} -> :verb -> {0o15, 0o21, 0o37}
key_down {2,6} -> {:digit, 0} -> {0o15, 0o20, 0o37}
```

### 3. TCP integration test

Run `yaAGC` manually:

```bash
cd /home/pi/virtualagc/yaAGC
./yaAGC --port=19697 --core=../Colossus249/Colossus249.bin
```

Run the Elixir program and press:

```text
VERB 37 ENTER
```

Confirm `yaAGC`/display behavior.

### 4. Full-system test

Run:

1. `yaAGC`
2. `ericDSKY.py`
3. Elixir keyboard input process

Press physical keys and verify:

- Elixir logs key events.
- `yaAGC` receives key events.
- Existing display updates normally.

## Implementation Phases for an Agent

### Phase 1: Create project skeleton

- Create Mix OTP app.
- Add config.
- Add `circuits_gpio` dependency.
- Add placeholder modules and tests.

### Phase 2: Implement key mapping and packet encoding

- Implement `Keymap`.
- Implement `AgcPacket`.
- Add unit tests matching the table above.

### Phase 3: Implement TCP client

- Connect to `127.0.0.1:19697`.
- Send encoded packet bytes.
- Add reconnect/backoff.
- Add logging.

### Phase 4: Implement GPIO scanner

- Open GPIO pins.
- Scan 3×7 matrix.
- Log raw state changes.
- Add dry-run mode.

### Phase 5: Implement debouncer and router

- Convert raw transitions to stable events.
- Route key-down/key-up to AGC operations.
- Handle PRO specially.

### Phase 6: Integrate with startup script

- Update startup script to launch Elixir input process after `yaAGC`.
- Verify that `ericDSKY.py` still runs as display client.
- If connection conflicts occur, fall back to FIFO integration.

### Phase 7: Hardware validation

- Test each row/column connection.
- Press every key and verify mapped output.
- Confirm no ghosting with multi-key combinations.

## Known Risks and Mitigations

| Risk | Mitigation |
|---|---|
| GPIO pin conflict with existing hardware | Confirm current display/Arduino wiring does not use the selected pins |
| Key bounce | Debounce in Elixir with 10–20 ms stable-state requirement |
| Ghosting | Use one diode per switch |
| `yaAGC` connection conflict | Fall back to FIFO into `ericDSKY.py` |
| Wrong packet encoding | Unit-test against `ericDSKY.py` packetization |
| PRO key behavior wrong | Treat PRO as press/release, not a one-shot normal key |

## Definition of Done

The project is complete when:

1. The Elixir program starts on the Raspberry Pi 4 with `mix run --no-halt`.
2. It scans the physical 3×7 keyboard matrix.
3. Every physical key maps to the expected DSKY key.
4. Normal keys send one DSKY operation on key-down.
5. PRO sends distinct press and release operations.
6. `VERB 37 ENTER` can be entered from the physical keypad.
7. The existing `AGC_DSKY_Replica` display path continues to operate.

