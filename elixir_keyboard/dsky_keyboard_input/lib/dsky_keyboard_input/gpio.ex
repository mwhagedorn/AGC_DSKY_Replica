defmodule DskyKeyboardInput.Gpio do
  @moduledoc """
  Minimal GPIO behaviour used by `GpioMatrix`.

  The production backend is `Circuits.GPIO` (which already implements these
  function signatures). `DskyKeyboardInput.Gpio.Stub` provides a no-hardware
  implementation for tests and developer workstations. The backend module is
  chosen via the `:gpio_module` application environment key.
  """

  @type gpio_spec :: non_neg_integer()
  @type line_handle :: reference() | term()

  @callback open(gpio_spec(), :input | :output, keyword()) ::
              {:ok, line_handle()} | {:error, term()}
  @callback read(line_handle()) :: 0 | 1
  @callback write(line_handle(), 0 | 1) :: :ok
  @callback close(line_handle()) :: :ok
end

defmodule DskyKeyboardInput.Gpio.Stub do
  @moduledoc """
  No-hardware GPIO backend. Opens always succeed; inputs read `1` (pulled-up =
  not pressed) so the matrix scanner reports no key presses. Useful for tests and
  for booting the app on a machine without GPIO.
  """

  @behaviour DskyKeyboardInput.Gpio

  @impl true
  def open(_spec, _direction, _opts), do: {:ok, make_ref()}

  @impl true
  def read(_handle), do: 1

  @impl true
  def write(_handle, _value), do: :ok

  @impl true
  def close(_handle), do: :ok
end
