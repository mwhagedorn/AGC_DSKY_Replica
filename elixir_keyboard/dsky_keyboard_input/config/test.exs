import Config

# Tests must never touch real GPIO or open a TCP socket to yaAGC. Use the stub
# GPIO backend and dry-run mode so the supervision tree can start harmlessly.
config :dsky_keyboard_input,
  dry_run: true,
  autostart: false,
  gpio_module: DskyKeyboardInput.Gpio.Stub
