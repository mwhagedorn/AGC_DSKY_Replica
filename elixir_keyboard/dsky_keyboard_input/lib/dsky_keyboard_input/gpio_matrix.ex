defmodule DskyKeyboardInput.GpioMatrix do
  @moduledoc """
  Scans the 3x7 DSKY keyboard matrix and emits debounced key events.

  Rows are driven outputs (normally HIGH), columns are pulled-up inputs. On each
  tick every row is driven LOW in turn and the columns are read; a column reading
  LOW means the key at that `{row, col}` is pressed. Raw readings are run through
  `Debouncer` and stable transitions are forwarded to `EventRouter`.

  If GPIO lines cannot be opened (e.g. running on a workstation without the
  hardware), the scanner logs a warning and idles instead of crashing.
  """

  use GenServer
  require Logger

  alias DskyKeyboardInput.{Debouncer, EventRouter}

  # --- Public API ---

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  # --- GenServer callbacks ---

  @impl true
  def init(opts) do
    gpio = Keyword.get(opts, :gpio_module, env(:gpio_module, DskyKeyboardInput.Gpio.Stub))
    row_pins = env(:rows, [17, 27, 22])
    col_pins = env(:cols, [5, 6, 12, 13, 16, 19, 26])
    scan_interval = env(:scan_interval_ms, 5)
    debounce_ms = env(:debounce_ms, 15)
    sink = Keyword.get(opts, :sink, EventRouter)

    case open_lines(gpio, row_pins, col_pins) do
      {:ok, rows, cols} ->
        positions = scannable_positions(length(row_pins), length(col_pins))

        state = %{
          gpio: gpio,
          rows: rows,
          cols: cols,
          positions: positions,
          scan_interval: scan_interval,
          debouncer: Debouncer.new(debounce_ms),
          sink: sink
        }

        Logger.info(
          "GpioMatrix scanning #{length(positions)} keys " <>
            "(rows=#{inspect(row_pins)} cols=#{inspect(col_pins)})"
        )

        schedule_scan(scan_interval)
        {:ok, state}

      {:error, reason} ->
        Logger.warning(
          "GpioMatrix could not open GPIO lines (#{inspect(reason)}); " <>
            "running idle (no scanning). This is expected off-hardware."
        )

        {:ok, %{idle: true}}
    end
  end

  @impl true
  def handle_info(:scan, %{idle: true} = state), do: {:noreply, state}

  def handle_info(:scan, state) do
    pressed = read_matrix(state)
    now = System.monotonic_time(:millisecond)
    {debouncer, events} = Debouncer.update_scan(state.debouncer, pressed, state.positions, now)

    Enum.each(events, fn {direction, pos} -> state.sink.key_event(direction, pos) end)

    schedule_scan(state.scan_interval)
    {:noreply, %{state | debouncer: debouncer}}
  end

  def handle_info(_msg, state), do: {:noreply, state}

  # --- Internal ---

  defp open_lines(gpio, row_pins, col_pins) do
    with {:ok, rows} <- open_all(gpio, row_pins, :output, []),
         {:ok, cols} <- open_all(gpio, col_pins, :input, pull_mode: :pullup) do
      # Rows idle HIGH; a row is pulsed LOW only while it is being scanned.
      Enum.each(rows, fn handle -> gpio.write(handle, 1) end)
      {:ok, rows, cols}
    end
  rescue
    error -> {:error, error}
  end

  defp open_all(gpio, pins, direction, opts) do
    Enum.reduce_while(pins, {:ok, []}, fn pin, {:ok, acc} ->
      case gpio.open(pin, direction, opts) do
        {:ok, handle} -> {:cont, {:ok, [handle | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, handles} -> {:ok, Enum.reverse(handles)}
      error -> error
    end
  end

  # Drive each row LOW, read the columns, restore the row HIGH.
  defp read_matrix(%{gpio: gpio, rows: rows, cols: cols}) do
    rows
    |> Enum.with_index()
    |> Enum.reduce(MapSet.new(), fn {row_handle, row_idx}, pressed ->
      gpio.write(row_handle, 0)
      settle()

      pressed =
        cols
        |> Enum.with_index()
        |> Enum.reduce(pressed, fn {col_handle, col_idx}, acc ->
          if gpio.read(col_handle) == 0 do
            MapSet.put(acc, {row_idx, col_idx})
          else
            acc
          end
        end)

      gpio.write(row_handle, 1)
      pressed
    end)
  end

  # Brief settle so the driven row level propagates before reading columns.
  defp settle, do: :ok

  defp scannable_positions(n_rows, n_cols) do
    for row <- 0..(n_rows - 1),
        col <- 0..(n_cols - 1),
        DskyKeyboardInput.Keymap.key_for_position({row, col}) != nil,
        do: {row, col}
  end

  defp schedule_scan(interval), do: Process.send_after(self(), :scan, interval)

  defp env(key, default), do: Application.get_env(:dsky_keyboard_input, key, default)
end
