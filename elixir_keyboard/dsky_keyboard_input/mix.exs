defmodule DskyKeyboardInput.MixProject do
  use Mix.Project

  def project do
    [
      app: :dsky_keyboard_input,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(Mix.env())
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {DskyKeyboardInput.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  # GPIO hardware access is only needed on the Raspberry Pi (prod). In dev and
  # test the code uses DskyKeyboardInput.Gpio.Stub, so the dependency is omitted
  # entirely there — letting the project compile and tests run with no Hex/network
  # access. On the Pi, fetch and run under prod:
  #   MIX_ENV=prod mix deps.get && MIX_ENV=prod mix run --no-halt
  defp deps(:prod), do: [{:circuits_gpio, "~> 2.1"}]
  defp deps(_env), do: []
end
