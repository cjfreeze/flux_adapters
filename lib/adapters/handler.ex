defmodule Flux.Adapters.Handler do
  @moduledoc false
  use Flux.HTTP.Handler
  require Logger

  if Code.ensure_loaded?(:cowboy_websocket) do
    @behaviour :cowboy_websocket
  end

  @connection Flux.Adapters.Plug

  @impl true
  def handle_request(conn, {endpoint, opts}) do
    Flux.Adapters.Plug.conn(flux_conn)
    |> endpoint.__handler__(opts)
    |> case do
      {:websocket, conn, handler, opts} ->
        case Phoenix.Transports.WebSocket.connect(conn, endpoint, handler, opts) do
          {:ok, %{adapter: {@connection, flux_conn}} = _conn, state} ->
            Flux.Websocket.upgrade(flux_conn, Flux.Adapters.Websocket, [handler | state])

          other ->
            IO.puts(other, label: :error)
        end

      {:plug, conn, endpoint, opts} ->
        %{adapter: {@connection, flux_conn}} =
          conn
          |> endpoint.call(opts)
          |> maybe_send(endpoint)

        {:ok, flux_conn, {endpoint, opts}}
    end
  end

  defp maybe_send(%Plug.Conn{state: :unset}, _plug), do: raise(Plug.Conn.NotSentError)
  defp maybe_send(%Plug.Conn{state: :set} = conn, _plug), do: Plug.Conn.send_resp(conn)
  defp maybe_send(%Plug.Conn{} = conn, _plug), do: conn

  defp maybe_send(other, plug) do
    raise "Cowboy2 adapter expected #{inspect(plug)} to return Plug.Conn but got: " <>
            inspect(other)
  end

  ## Websocket callbacks

  def websocket_init([handler | state]) do
    {:ok, state} = handler.init(state)
    {:ok, [handler | state]}
  end

  def websocket_handle({opcode, payload}, [handler | state]) when opcode in [:text, :binary] do
    handle_reply(handler, handler.handle_in({payload, opcode: opcode}, state))
  end

  def websocket_handle(_other, handler_state) do
    {:ok, handler_state}
  end

  def websocket_info(message, [handler | state]) do
    handle_reply(handler, handler.handle_info(message, state))
  end

  def terminate(_reason, _req, {_handler, _state}) do
    :ok
  end

  def terminate({:error, :closed}, _req, [handler | state]) do
    handler.terminate(:closed, state)
  end

  def terminate({:remote, :closed}, _req, [handler | state]) do
    handler.terminate(:closed, state)
  end

  def terminate({:remote, code, _}, _req, [handler | state])
      when code in 1000..1003 or code in 1005..1011 or code == 1015 do
    handler.terminate(:closed, state)
  end

  def terminate(:remote, _req, [handler | state]) do
    handler.terminate(:closed, state)
  end

  def terminate(reason, _req, [handler | state]) do
    handler.terminate(reason, state)
  end

  defp handle_reply(handler, {:ok, state}), do: {:ok, [handler | state]}
  defp handle_reply(handler, {:push, data, state}), do: {:reply, data, [handler | state]}

  defp handle_reply(handler, {:reply, _status, data, state}),
    do: {:reply, data, [handler | state]}

  defp handle_reply(handler, {:stop, _reason, state}), do: {:stop, [handler | state]}
end
