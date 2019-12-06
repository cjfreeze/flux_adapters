defmodule Flux.Adapter do
  @moduledoc false

  @handler Flux.Handler

  @doc false
  def child_spec(scheme, endpoint, opts) do
    if scheme == :https do
      Application.ensure_all_started(:ssl)
    end

    Flux.Handler.child_spec([scheme: scheme, endpoint: {endpoint, []}, handler: @handler] ++ opts)
  end

  @doc false
  def info(scheme, endpoint, ref) do
    server = "flux #{Application.spec(:flux)[:vsn]}"
    "Running #{inspect(endpoint)} with #{server} at #{uri(scheme, ref)}"
  end

  defp uri(_scheme, _ref) do
    raise "Flux.Adapter.uri/2 Not implemented"
  end
end
