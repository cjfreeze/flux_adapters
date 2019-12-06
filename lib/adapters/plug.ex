defmodule Flux.Adapters.Plug do
  @behaviour Plug.Conn.Adapter
  alias Flux.{Conn, HTTP}

  def conn(conn) do
    %Plug.Conn{
      adapter: {__MODULE__, conn},
      host: conn.host,
      method: "#{conn.method}",
      owner: self(),
      path_info: split_path(conn.uri),
      port: conn.port,
      remote_ip: conn.remote_ip,
      query_string: conn.query || "",
      req_headers: conn.req_headers,
      request_path: IO.iodata_to_binary(conn.uri),
      scheme: conn.opts.scheme
    }
  end

  defp split_path(path) when is_list(path) do
    path
    |> IO.iodata_to_binary()
    |> split_path()
  end

  defp split_path(path) do
    segments = :binary.split(path, "/", [:global])
    for segment <- segments, segment != "", do: segment
  end

  def send_resp(conn, status, headers, body) do
    conn
    |> Conn.put_status(status)
    |> Conn.put_resp_headers(headers)
    |> Conn.put_resp_body(body)
    |> HTTP.send_response()
  end

  def send_file(conn, status, headers, file, offset, length) do
    HTTP.send_file(conn, status, headers, file, offset, length)
  end

  def send_chunked(conn, status, headers) do
    conn
    |> Conn.put_status(status)
    |> Conn.put_resp_headers(headers)
    |> HTTP.chunked_response()
  end

  def chunk(conn, payload) do
    HTTP.send_chunk(conn, payload)
  end

  def read_req_body(conn, opts) do
    length = Keyword.get(opts, :length, 8_000_000)
    read_length = Keyword.get(opts, :read_length, 1_000_000)
    read_timeout = Keyword.get(opts, :read_length, 15_000)

    Flux.HTTP.read_request_body(conn, length, read_length, read_timeout)
    |> case do
      {:ok, body, conn} when is_list(body) ->
        {:ok, IO.iodata_to_binary(body), conn}

      {:ok, body, conn} ->
        {:ok, body, conn}

      {:error, _} = error ->
        error
    end
  end

  def get_peer_data(%{peer: address}) do
    %{
      address: address,
      port: nil,
      ssl_cert: nil
    }
  end

  def get_http_protocol(conn) do
    conn.transport
  end

  def inform(_, _, _) do
    raise "TODO"
  end

  def push(_, _, _) do
    raise "TODO"
  end
end
