defmodule FluxAdapters.Websocket do
  # Implementation of the WebSocket transport for Flux.
  @moduledoc false

  def init(_flux_conn, {plug_conn, module, opts}) do
    case module.init(plug_conn, opts) do
      {:ok, _, {handler, args}} ->
        {:ok, state, _} = handler.ws_init(args)
        {:ok, {handler, state}}
      {:error, _} ->
        :error
    end
  end

  def resume(module, fun, args) do
    try do
      apply(module, fun, args)
    catch
      kind, [{:reason, reason}, {:mfa, _mfa}, {:stacktrace, stack} | _rest] ->
        reason = format_reason(kind, reason, stack)
        exit({reason, {__MODULE__, :resume, []}})
    else
      {:suspend, module, fun, args} ->
        {:suspend, __MODULE__, :resume, [module, fun, args]}
      _ ->
        # We are forcing a shutdown exit because we want to make
        # sure all transports exits with reason shutdown to guarantee
        # all channels are closed.
        exit(:shutdown)
    end
  end

  defp format_reason(:exit, reason, _), do: reason
  defp format_reason(:throw, reason, stack), do: {{:nocatch, reason}, stack}
  defp format_reason(:error, reason, stack), do: {reason, stack}

  def handle_frame(:text, payload, req, {handler, state}) do
    handle_reply req, handler, handler.ws_handle(:text, payload, state)
  end
  def handle_frame(:binary, payload, req, {handler, state}) do
    handle_reply req, handler, handler.ws_handle(:binary, payload, state)
  end
  def handle_frame(_, _payload, req, {handler, state}) do
    {:ok, req, {handler, state}}
  end

  def handle_info(message, req, {handler, state}) do
    handle_reply req, handler, handler.ws_info(message, state)
  end

  def handle_terminate({:error, :closed}, _req, {handler, state}) do
    handler.ws_close(state)
    :ok
  end
  def handle_terminate({:remote, :closed}, _req, {handler, state}) do
    handler.ws_close(state)
    :ok
  end
  def handle_terminate({:remote, code, _}, _req, {handler, state})
      when code in 1000..1003 or code in 1005..1011 or code == 1015 do
    handler.ws_close(state)
    :ok
  end
  def handle_terminate(reason, _req, {handler, state}) do
    handler.ws_terminate(reason, state)
    :ok
  end

  defp handle_reply(req, handler, {:shutdown, new_state}) do
    {:shutdown, req, {handler, new_state}}
  end
  defp handle_reply(req, handler, {:ok, new_state}) do
    {:ok, req, {handler, new_state}}
  end
  defp handle_reply(req, handler, {:reply, {opcode, payload}, new_state}) do
    frame = Flux.Websocket.Frame.build_frame(opcode, payload)
    Flux.Websocket.send_frame(req, frame)
    {:ok, req, {handler, new_state}}
  end
end
