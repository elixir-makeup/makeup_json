defmodule MakeupJsonTest do
  use ExUnit.Case
  alias Makeup.Lexers.JsonLexer

  test "expected token types" do
    # integers
    [{type, _, _}] = JsonLexer.lex("0")
    assert type == :number_integer
    [{type, _, _}] = JsonLexer.lex("-1")
    assert type == :number_integer
    [{type, _, _}] = JsonLexer.lex("1234567890")
    assert type == :number_integer
    [{type, _, _}] = JsonLexer.lex("-1234567890")
    assert type == :number_integer

    # Floats, including scientific notation
    [{type, _, _}] = JsonLexer.lex("123456789.0123456789")
    assert type == :number_float
    [{type, _, _}] = JsonLexer.lex("-123456789.0123456789")
    assert type == :number_float
    [{type, _, _}] = JsonLexer.lex("1e10")
    assert type == :number_float
    [{type, _, _}] = JsonLexer.lex("-1E10")
    assert type == :number_float
    [{type, _, _}] = JsonLexer.lex("1e-10")
    assert type == :number_float
    [{type, _, _}] = JsonLexer.lex("-1E+10")
    assert type == :number_float
    [{type, _, _}] = JsonLexer.lex("1.0e10")
    assert type == :number_float
    [{type, _, _}] = JsonLexer.lex("-1.0E10")
    assert type == :number_float
    [{type, _, _}] = JsonLexer.lex("1.0e-10")
    assert type == :number_float
    [{type, _, _}] = JsonLexer.lex("-1.0E+10")
    assert type == :number_float

    # strings (escapes are tested elsewhere)
    [{type, _, _}] = JsonLexer.lex(~s{""})
    assert type == :string_double
    [{type, _, _}] = JsonLexer.lex(~s{"abc"})
    assert type == :string_double
    [{type, _, _}] = JsonLexer.lex(~s{"ひらがな"})
    assert type == :string_double
    [{type, _, _}] = JsonLexer.lex(~s{"123"})
    assert type == :string_double
    [{type, _, _}] = JsonLexer.lex(~s{"[]"})
    assert type == :string_double
    [{type, _, _}] = JsonLexer.lex(~s("{}"))
    assert type == :string_double
    [{type, _, _}] = JsonLexer.lex(~s{"true"})
    assert type == :string_double
    [{type, _, _}] = JsonLexer.lex(~s{"false"})
    assert type == :string_double
    [{type, _, _}] = JsonLexer.lex(~s{"null"})
    assert type == :string_double
    [{type, _, _}] = JsonLexer.lex(~s{":,\"})
    assert type == :string_double

    # constants
    [{type, _, _}] = JsonLexer.lex("true")
    assert type == :keyword_constant
    [{type, _, _}] = JsonLexer.lex("false")
    assert type == :keyword_constant
    [{type, _, _}] = JsonLexer.lex("null")
    assert type == :keyword_constant

    # arrays
    [{type, _, _}, {type, _, _}] = JsonLexer.lex("[]")
    assert type == :punctuation

    types =
      JsonLexer.lex(~s{["a", "b"]})
      |> Enum.map(fn {type, _, _} -> type end)

    assert types == [
             :punctuation,
             :string_double,
             :punctuation,
             :whitespace,
             :string_double,
             :punctuation
           ]

    # objects
    [{type, _, _}, {type, _, _}] = JsonLexer.lex("{}")
    assert type == :punctuation

    types =
      JsonLexer.lex(~s({"a": "b"}))
      |> Enum.map(fn {type, _, _} -> type end)

    assert types == [
             :punctuation,
             :name_tag,
             :punctuation,
             :whitespace,
             :string_double,
             :punctuation
           ]
  end
end
