defmodule DskyKeyboardInput.Application do
  @moduledoc false

  use Application
  require Logger

  alias DskyKeyboardInput.{AgcClient, EventRouter, GpioMatrix}

  @impl true
  def start(_type, _args) do
    maybe_enable_dry_run()

    opts = [strategy: :one_for_one, name: DskyKeyboardInput.Supervisor]
    Supervisor.start_link(children(), opts)
  end

  # The test suite drives the workers individually, so it disables autostart to
  # avoid name clashes with processes it starts itself.
  defp children do
    if Application.get_env(:dsky_keyboard_input, :autostart, true) do
      [
        AgcClient,
        EventRouter,
        {GpioMatrix, gpio_module: Application.get_env(:dsky_keyboard_input, :gpio_module)}
      ]
    else
      []
    end
  end

  # Honour `mix run --no-halt -- --dry-run`: log key events instead of opening a
  # TCP connection to yaAGC.
  defp maybe_enable_dry_run do
    if "--dry-run" in System.argv() do
      Application.put_env(:dsky_keyboard_input, :dry_run, true)
      Logger.info("Dry-run enabled via command line")
    end
  end
end
