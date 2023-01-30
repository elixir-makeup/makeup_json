defmodule Makeup.Lexers.JsonLexer.Application do
  @moduledoc false

  use Application

  alias Makeup.Registry

  def start(_type, _args) do
    Registry.register_lexer(Makeup.Lexers.JsonLexer, names: ["json"], extensions: ["json"])
    Supervisor.start_link([], strategy: :one_for_one)
  end
end