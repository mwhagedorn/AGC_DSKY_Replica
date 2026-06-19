import Config

# Standalone DSKY keyboard input configuration.
#
# These values mirror the existing Python display client (ericDSKY.py) and the
# VirtualAGC launch in test.sh, which uses port 19697.
config :dsky_keyboard_input,
  # yaAGC connection. Host is a charlist because it is passed to :gen_tcp.connect/3.
  agc_host: ~c"127.0.0.1",
  agc_port: 19697,

  # Matrix scanning cadence and debounce window (milliseconds).
  scan_interval_ms: 5,
  debounce_ms: 15,

  # BCM GPIO numbering. Rows are driven outputs, columns are pulled-up inputs.
  rows: [17, 27, 22],
  cols: [5, 6, 12, 13, 16, 19, 26],

  # When true, key events are logged instead of being sent to yaAGC over TCP.
  # Overridden at boot by the `--dry-run` command-line flag.
  dry_run: false,

  # GPIO backend module. Defaults to Circuits.GPIO; tests/dev hosts without the
  # dependency or hardware can swap in a stub.
  gpio_module: Circuits.GPIO

import_config "#{config_env()}.exs"
