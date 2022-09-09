defmodule MakeupJsonTest do
  use ExUnit.Case
  alias Makeup.Lexers.JsonLexer

  describe "Expected Token Types" do
    test "Integers" do
      [{type, _, _}] = JsonLexer.lex("0")
      assert type == :number_integer
      [{type, _, _}] = JsonLexer.lex("-1")
      assert type == :number_integer
      [{type, _, _}] = JsonLexer.lex("1234567890")
      assert type == :number_integer
      [{type, _, _}] = JsonLexer.lex("-1234567890")
      assert type == :number_integer
    end

    test "Floats, including scientific notation" do
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
    end

    test "Strings (escapes are tested elsewhere)" do
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
    end

    test "Constants" do
      [{type, _, _}] = JsonLexer.lex("true")
      assert type == :keyword_constant
      [{type, _, _}] = JsonLexer.lex("false")
      assert type == :keyword_constant
      [{type, _, _}] = JsonLexer.lex("null")
      assert type == :keyword_constant
    end

    test "Arrays" do
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
    end

    test "Objects" do
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

    test "Whitespace" do
      # space
      [{type, _, _}] = JsonLexer.lex("\u0020")
      assert type == :whitespace
      [{type, _, _}] = JsonLexer.lex("\u0020\u0020 ")
      assert type == :whitespace

      # newline
      [{type, _, _}] = JsonLexer.lex("\u000a")
      assert type == :whitespace
      [{type, _, _}] = JsonLexer.lex("\u000a\u000a ")
      assert type == :whitespace

      # carriage return
      [{type, _, _}] = JsonLexer.lex("\u000d")
      assert type == :whitespace
      [{type, _, _}] = JsonLexer.lex("\u000d\u000d ")
      assert type == :whitespace

      # tab
      [{type, _, _}] = JsonLexer.lex("\u0009")
      assert type == :whitespace
      [{type, _, _}] = JsonLexer.lex("\u0009\u0009 ")
      assert type == :whitespace
    end
  end
end
