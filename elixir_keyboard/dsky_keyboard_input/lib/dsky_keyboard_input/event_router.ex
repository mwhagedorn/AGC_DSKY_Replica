defmodule DskyKeyboardInput.EventRouter do
  @moduledoc """
  Turns debounced matrix events into AGC channel operations.

  * Normal keys (digits, VERB, NOUN, ENTER, CLR, KEY REL, +, -, RESET) fire a
    single operation on `:key_down` and nothing on `:key_up`.
  * The PRO key fires its *pressed* operation on `:key_down` and its *released*
    operation on `:key_up`.

  Unmapped positions (the two unused matrix cells) are ignored.
  """

  use GenServer
  require Logger

  alias DskyKeyboardInput.{AgcClient, Keymap}

  # --- Public API ---

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Deliver a debounced key event from the matrix scanner."
  @spec key_event(:key_down | :key_up, {non_neg_integer(), non_neg_integer()}) :: :ok
  def key_event(direction, pos) do
    GenServer.cast(__MODULE__, {:key_event, direction, pos})
  end

  # --- GenServer callbacks ---

  @impl true
  def init(opts), do: {:ok, %{sink: Keyword.get(opts, :sink, AgcClient)}}

  @impl true
  def handle_cast({:key_event, direction, pos}, state) do
    handle_event(direction, pos, Keymap.key_for_position(pos), state)
    {:noreply, state}
  end

  # PRO: distinct press/release operations.
  defp handle_event(:key_down, pos, :pro, state) do
    op = Keymap.pro_pressed()
    Logger.info("key_down #{fmt(pos)} -> :pro -> #{fmt_op(op)}")
    send_op(state, op)
  end

  defp handle_event(:key_up, pos, :pro, state) do
    op = Keymap.pro_released()
    Logger.info("key_up #{fmt(pos)} -> :pro -> #{fmt_op(op)}")
    send_op(state, op)
  end

  # Normal keys: fire on key_down only.
  defp handle_event(:key_down, pos, key, state) when not is_nil(key) do
    case Keymap.operation_for_key(key) do
      nil ->
        Logger.debug("key_down #{fmt(pos)} -> #{inspect(key)} (no operation)")

      op ->
        Logger.info("key_down #{fmt(pos)} -> #{inspect(key)} -> #{fmt_op(op)}")
        send_op(state, op)
    end
  end

  # key_up for normal keys, and any event for unmapped positions: ignore.
  defp handle_event(_direction, _pos, _key, _state), do: :ok

  defp send_op(%{sink: sink}, op), do: sink.send_operation(op)

  defp fmt({row, col}), do: "{#{row},#{col}}"

  defp fmt_op({channel, value, mask}) do
    "{0o#{Integer.to_string(channel, 8)}, 0o#{Integer.to_string(value, 8)}, " <>
      "0o#{Integer.to_string(mask, 8)}}"
  end
end
