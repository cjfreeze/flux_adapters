defmodule Flux.Adapters.Websocket do
  # Implementation of the WebSocket transport for Flux.
  @moduledoc false
  def init(_conn, [handler | state]) do
    {:ok, state} = handler.init(state)
    {:ok, [handler | state]}
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

  def handle_frame(opcode, payload, req, [handler | state]) when opcode in [:text, :binary] do
    handle_reply(req, handler, handler.handle_in({payload, opcode: opcode}, state))
  end

  def handle_frame(_, _payload, req, handler_state) do
    {:ok, req, handler_state}
  end

  def handle_push(message, req, [handler | state]) do
    handle_reply(req, handler, handler.handle_info(message, state))
  end

  def handle_info(message, req, [handler | state]) do
    handle_reply(req, handler, handler.handle_info(message, state))
  end

  def handle_terminate({:error, :closed}, _req, [handler | state]) do
    handler.terminate(:closed, state)
    :ok
  end

  def handle_terminate({:remote, :closed}, _req, [handler | state]) do
    handler.terminate(:remote, state)
    :ok
  end

  def handle_terminate({:remote, code, _}, _req, [handler | state])
      when code in 1000..1003 or code in 1005..1011 or code == 1015 do
    handler.terminate(:closed, state)
    :ok
  end

  def handle_terminate(reason, _req, [handler | state]) do
    handler.terminate(reason, state)
    :ok
  end

  defp handle_reply(req, handler, {:ok, state}) do
    {:ok, req, [handler | state]}
  end

  defp handle_reply(req, handler, {:push, data, state}) do
    do_reply(data, req, [handler | state])
  end

  defp handle_reply(req, handler, {:reply, _status, data, state}) do
    do_reply(data, req, [handler | state])
  end

  defp handle_reply(req, handler, {:stop, _reason, state}) do
    {:shutdown, req, [handler | state]}
  end

  defp do_reply({opcode, payload}, req, handler_state) do
    frame = Flux.Websocket.Frame.build_frame(opcode, payload)
    Flux.Websocket.send_frame(req, frame)
    {:ok, req, handler_state}
  end
end
