import Config

# On a developer workstation there is usually no real GPIO hardware. circuits_gpio
# 2.x ships a stub backend that lets the app boot, but you can also run in dry-run
# mode (mix run --no-halt -- --dry-run) to log key events without touching yaAGC.
