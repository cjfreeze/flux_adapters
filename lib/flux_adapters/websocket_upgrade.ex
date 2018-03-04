defmodule FluxAdapters.WebsocketUpgrade do
  import Plug.Conn
  alias Flux.Websocket

  def init({path, handler, user_socket}), do: {path, handler, user_socket}

  def call(%{path_info: path, adapter: {_, flux_conn}} = conn, {path, handler, user_socket}) do
    {transport, _} = user_socket.__transport__(:websocket)
    opts = {Phoenix.Controller.endpoint_module(conn), user_socket, :websocket}

    Websocket.upgrade(flux_conn, handler, {conn, transport, opts})
    conn
    |> hack_phoenix()
    |> halt()
  end
  def call(conn, _) do
    conn
  end

  defp hack_phoenix(conn), do: %{conn | state: :sent}
end