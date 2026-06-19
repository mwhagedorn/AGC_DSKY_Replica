defmodule DskyKeyboardInput.AgcClient do
  @moduledoc """
  Maintains the TCP connection to `yaAGC` and sends encoded DSKY operations.

  Connects to `agc_host:agc_port` (default `127.0.0.1:19697`, matching the
  existing `test.sh`). Reconnects with a capped backoff if `yaAGC` is not yet up
  or restarts. In dry-run mode no socket is opened and operations are only logged.
  """

  use GenServer
  require Logger

  alias DskyKeyboardInput.AgcPacket

  @backoff_start_ms 250
  @backoff_max_ms 5_000

  # --- Public API ---

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Send a `{channel, value, mask}` operation to yaAGC (async)."
  @spec send_operation(AgcPacket.operation()) :: :ok
  def send_operation(operation) do
    GenServer.cast(__MODULE__, {:send_operation, operation})
  end

  # --- GenServer callbacks ---

  @impl true
  def init(_opts) do
    state = %{
      host: env(:agc_host, ~c"127.0.0.1"),
      port: env(:agc_port, 19697),
      dry_run: env(:dry_run, false),
      socket: nil,
      backoff: @backoff_start_ms
    }

    if state.dry_run do
      Logger.info("AgcClient starting in dry-run mode (no TCP connection)")
      {:ok, state}
    else
      {:ok, state, {:continue, :connect}}
    end
  end

  @impl true
  def handle_continue(:connect, state), do: {:noreply, connect(state)}

  @impl true
  def handle_cast({:send_operation, operation}, %{dry_run: true} = state) do
    Logger.info("[dry-run] would send #{format_op(operation)}")
    {:noreply, state}
  end

  def handle_cast({:send_operation, _operation}, %{socket: nil} = state) do
    Logger.warning("Dropping DSKY operation: not connected to yaAGC")
    {:noreply, state}
  end

  def handle_cast({:send_operation, operation}, %{socket: socket} = state) do
    case :gen_tcp.send(socket, AgcPacket.encode_operation(operation)) do
      :ok ->
        Logger.debug("Sent #{format_op(operation)}")
        {:noreply, state}

      {:error, reason} ->
        Logger.warning("Send failed (#{inspect(reason)}); reconnecting")
        :gen_tcp.close(socket)
        {:noreply, connect(%{state | socket: nil})}
    end
  end

  # yaAGC pings / writes back to peripheral clients; we are input-only, so ignore.
  @impl true
  def handle_info({:tcp, _socket, _data}, state), do: {:noreply, state}

  def handle_info({:tcp_closed, _socket}, state) do
    Logger.warning("yaAGC connection closed; reconnecting")
    {:noreply, connect(%{state | socket: nil})}
  end

  def handle_info({:tcp_error, _socket, reason}, state) do
    Logger.warning("yaAGC connection error (#{inspect(reason)}); reconnecting")
    if state.socket, do: :gen_tcp.close(state.socket)
    {:noreply, connect(%{state | socket: nil})}
  end

  def handle_info(:reconnect, state), do: {:noreply, connect(state)}

  def handle_info(_msg, state), do: {:noreply, state}

  # --- Internal ---

  defp connect(state) do
    opts = [:binary, active: true, packet: :raw]

    case :gen_tcp.connect(state.host, state.port, opts, 1_000) do
      {:ok, socket} ->
        Logger.info("Connected to yaAGC (#{state.host}:#{state.port})")
        %{state | socket: socket, backoff: @backoff_start_ms}

      {:error, reason} ->
        Logger.warning(
          "Could not connect to yaAGC (#{state.host}:#{state.port}): " <>
            "#{inspect(reason)}; retrying in #{state.backoff} ms"
        )

        Process.send_after(self(), :reconnect, state.backoff)
        %{state | socket: nil, backoff: min(state.backoff * 2, @backoff_max_ms)}
    end
  end

  defp format_op({channel, value, mask}) do
    "{0o#{Integer.to_string(channel, 8)}, 0o#{Integer.to_string(value, 8)}, " <>
      "0o#{Integer.to_string(mask, 8)}}"
  end

  defp env(key, default), do: Application.get_env(:dsky_keyboard_input, key, default)
end
