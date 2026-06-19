defmodule DskyKeyboardInput.Debouncer do
  @moduledoc """
  Timestamp-based matrix debouncing.

  The debouncer holds a committed ("stable") pressed/released state per key. A
  raw reading only flips the stable state once it has stayed different for at
  least `debounce_ms`. This avoids `Process.sleep` per key: callers pass the
  current monotonic time in and the debouncer compares timestamps.

  Usage:

      deb = Debouncer.new(15)
      {deb, events} = Debouncer.update(deb, {0, 0}, true, now_ms)

  `events` is a (possibly empty) list of `{:key_down, pos}` / `{:key_up, pos}`.
  """

  @enforce_keys [:debounce_ms]
  defstruct debounce_ms: 15, keys: %{}

  @type pos :: {non_neg_integer(), non_neg_integer()}
  @type event :: {:key_down | :key_up, pos()}
  @type t :: %__MODULE__{debounce_ms: non_neg_integer(), keys: map()}

  @doc "Create a debouncer with the given stable-state window in milliseconds."
  @spec new(non_neg_integer()) :: t()
  def new(debounce_ms) when is_integer(debounce_ms) and debounce_ms >= 0 do
    %__MODULE__{debounce_ms: debounce_ms}
  end

  @doc """
  Feed one raw reading for `pos` (`true` = pressed) at time `now` (ms).

  Returns `{debouncer, events}`.
  """
  @spec update(t(), pos(), boolean(), integer()) :: {t(), [event()]}
  def update(%__MODULE__{} = deb, pos, raw?, now) when is_boolean(raw?) do
    state = Map.get(deb.keys, pos, %{stable: false, pending: nil, pending_since: 0})

    cond do
      # Reading matches committed state: cancel any in-flight transition.
      raw? == state.stable ->
        {put_key(deb, pos, %{state | pending: nil}), []}

      # A new candidate transition: start the debounce timer.
      state.pending != raw? ->
        {put_key(deb, pos, %{state | pending: raw?, pending_since: now}), []}

      # Candidate has been stable long enough: commit and emit.
      now - state.pending_since >= deb.debounce_ms ->
        new_state = %{state | stable: raw?, pending: nil}
        {put_key(deb, pos, new_state), [event(raw?, pos)]}

      # Candidate still settling.
      true ->
        {deb, []}
    end
  end

  @doc """
  Apply a full scan: `pressed` is the set of positions currently reading pressed,
  `all_positions` the complete key list. Returns `{debouncer, events}`.
  """
  @spec update_scan(t(), MapSet.t(pos()), [pos()], integer()) :: {t(), [event()]}
  def update_scan(%__MODULE__{} = deb, pressed, all_positions, now) do
    Enum.reduce(all_positions, {deb, []}, fn pos, {acc_deb, acc_events} ->
      {acc_deb, events} = update(acc_deb, pos, MapSet.member?(pressed, pos), now)
      {acc_deb, acc_events ++ events}
    end)
  end

  defp put_key(deb, pos, state), do: %{deb | keys: Map.put(deb.keys, pos, state)}

  defp event(true, pos), do: {:key_down, pos}
  defp event(false, pos), do: {:key_up, pos}
end
