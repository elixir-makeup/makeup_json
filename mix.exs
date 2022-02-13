defmodule MakeupJson.MixProject do
  use Mix.Project

  def project do
    [
      app: :makeup_json,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:makeup, "~> 1.0"},
      # {:makeup_elixir, "~> 0.15"},
      {:nimble_parsec, "~> 1.1"},
      # {:jason, "~> 1.2"},
      # Generate unicode character lists
      {:unicode_set, "~> 1.1.0", only: :dev},
      # Benchmarking utilities
      {:benchee, "~> 1.0", only: :dev},
      {:benchee_markdown, "~> 0.2", only: :dev}
    ]
  end
end
