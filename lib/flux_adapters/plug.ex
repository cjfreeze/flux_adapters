defmodule FluxAdapters.Plug do
  @behaviour Plug.Conn.Adapter

  def upgrade(conn, endpoint) do
    %Plug.Conn{
      adapter: {__MODULE__, conn},
      host: conn.host,
      method: "#{conn.method}",
      owner: self(),
      path_info: split_path(conn.uri),
      peer: conn.peer,
      port: conn.port,
      remote_ip: conn.remote_ip,
      query_string: conn.query || "",
      req_headers: conn.req_headers,
      request_path: IO.iodata_to_binary(conn.uri),
      scheme: conn.opts.scheme
    }
    |> endpoint.call([])
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
    |> Flux.Conn.put_status(status)
    |> Flux.Conn.put_resp_headers(headers)
    |> Flux.Conn.put_resp_body(body)
    |> Flux.HTTP.send_response()
  end

  def send_file(conn, status, headers, file, offset, length) do
    conn
    |> Flux.Conn.put_status(status)
    |> Flux.Conn.put_resp_headers(headers)
    |> Flux.HTTP.send_file(file, offset, length)
  end

  def send_chunked(_conn, _arg1, _arg2) do

  end

  def chunk(_conn, _arg) do

  end

  def read_req_body(_conn, _arg) do

  end
end
