defmodule MakeupJson.MixProject do
  use Mix.Project

  @version "0.1.1"
  @url "https://github.com/elixir-makeup/makeup_json"

  def project do
    [
      app: :makeup_json,
      version: @version,
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: [main: "Makeup.Lexers.JsonLexer", source_url: @url],
      description: "JSON lexer for makeup"
    ]
  end

  defp package do
    [
      name: :makeup_json,
      licenses: ["BSD-2-Clause"],
      maintainers: ["Kartheek L"],
      links: %{"GitHub" => @url}
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Makeup.Lexers.JsonLexer.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:makeup, "~> 1.0"},
      {:nimble_parsec, "~> 1.1"},
      # Docs
      {:ex_doc, "~> 0.27", only: :dev, runtime: false}
    ]
  end
end
