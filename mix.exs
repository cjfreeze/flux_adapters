defmodule Flux.MixProject do
  use Mix.Project

  def project do
    [
      app: :flux_phoenix,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      package: package(),
      deps: deps(),
      description: """
      A lightweight and functional http server designed from the ground up to work with plug.
      """
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug, "~> 1.3.3 or ~> 1.4"},
      {:flux, path: "../Flux"},
      {:ex_doc, "~> 0.19.1", only: :dev}
    ]
  end

  defp package do
    [
      maintainers: [
        "Chris Freeze"
      ],
      licenses: ["MIT"],
      # These are the default files included in the package
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      links: %{"GitHub" => "https://github.com/cjfreeze/flux_phoenix"}
    ]
  end
end
