defmodule MakeupJsonTest do
  use ExUnit.Case
  alias Makeup.Lexers.JsonLexer

  describe "Expected Token Types" do
    test "Integers" do
      assert [{:number_integer, _, _}] = JsonLexer.lex("0")
      assert [{:number_integer, _, _}] = JsonLexer.lex("-1")
      assert [{:number_integer, _, _}] = JsonLexer.lex("1234567890")
      assert [{:number_integer, _, _}] = JsonLexer.lex("-1234567890")
    end

    test "Floats, including scientific notation" do
      assert [{:number_float, _, _}] = JsonLexer.lex("123456789.0123456789")
      assert [{:number_float, _, _}] = JsonLexer.lex("-123456789.0123456789")
      assert [{:number_float, _, _}] = JsonLexer.lex("1e10")
      assert [{:number_float, _, _}] = JsonLexer.lex("-1E10")
      assert [{:number_float, _, _}] = JsonLexer.lex("1e-10")
      assert [{:number_float, _, _}] = JsonLexer.lex("-1E+10")
      assert [{:number_float, _, _}] = JsonLexer.lex("1.0e10")
      assert [{:number_float, _, _}] = JsonLexer.lex("-1.0E10")
      assert [{:number_float, _, _}] = JsonLexer.lex("1.0e-10")
      assert [{:number_float, _, _}] = JsonLexer.lex("-1.0E+10")
    end

    test "Strings (escapes are tested elsewhere)" do
      assert [{:string_double, _, _}] = JsonLexer.lex(~s{""})
      assert [{:string_double, _, _}] = JsonLexer.lex(~s{"abc"})
      assert [{:string_double, _, _}] = JsonLexer.lex(~s{"ひらがな"})
      assert [{:string_double, _, _}] = JsonLexer.lex(~s{"123"})
      assert [{:string_double, _, _}] = JsonLexer.lex(~s{"[]"})
      assert [{:string_double, _, _}] = JsonLexer.lex(~s("{}"))
      assert [{:string_double, _, _}] = JsonLexer.lex(~s{"true"})
      assert [{:string_double, _, _}] = JsonLexer.lex(~s{"false"})
      assert [{:string_double, _, _}] = JsonLexer.lex(~s{"null"})
      assert [{:string_double, _, _}] = JsonLexer.lex(~s{":,\"})
    end

    test "Constants" do
      assert [{:keyword_constant, _, _}] = JsonLexer.lex("true")
      assert [{:keyword_constant, _, _}] = JsonLexer.lex("false")
      assert [{:keyword_constant, _, _}] = JsonLexer.lex("null")
    end

    test "Arrays" do
      assert [{:punctuation, _, _}, {:punctuation, _, _}] = JsonLexer.lex("[]")

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
      assert [{:punctuation, _, _}, {:punctuation, _, _}] = JsonLexer.lex("{}")

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
      assert [{:whitespace, _, _}] = JsonLexer.lex("\u0020")
      assert [{:whitespace, _, _}] = JsonLexer.lex("\u0020\u0020 ")

      # newline
      assert [{:whitespace, _, _}] = JsonLexer.lex("\u000a")
      assert [{:whitespace, _, _}] = JsonLexer.lex("\u000a\u000a ")

      # carriage return
      assert [{:whitespace, _, _}] = JsonLexer.lex("\u000d")
      assert [{:whitespace, _, _}] = JsonLexer.lex("\u000d\u000d ")

      # tab
      assert [{:whitespace, _, _}] = JsonLexer.lex("\u0009")
      assert [{:whitespace, _, _}] = JsonLexer.lex("\u0009\u0009 ")
    end
  end

  test "Escape sequences in JSON object keys are parsed correctly" do
    strings = [
      "\"",
      "\\",
      "/",
      "b",
      "f",
      "n",
      "r",
      "t",
      "u0123",
      "u4567",
      "u89ab",
      "ucdef",
      "uABCD",
      "uEF01"
    ]

    for string <- strings do
      tokens = JsonLexer.lex(~s({"\\#{string}": 1}))

      assert length(tokens) == 8
      assert {:name_tag, _, ["\""]} = Enum.at(tokens, 1)
      assert {:string_escape, _, _} = Enum.at(tokens, 2)
      assert {:name_tag, _, ["\""]} = Enum.at(tokens, 3)

      # TODO: What this should be, according to the pygments tests:
      # https://github.com/pygments/pygments/blob/master/tests/test_data.py#L120
      #
      # assert length(tokens) == 6
      # assert {:name_tag, _, ^string} = Enum.at(tokens, 1)
    end
  end

  test "Escape sequences in JSON string values are parsed correctly" do
    strings = [
      "\"",
      "\\",
      "/",
      "b",
      "f",
      "n",
      "r",
      "t",
      "u0123",
      "u4567",
      "u89ab",
      "ucdef",
      "uABCD",
      "uEF01"
    ]

    for string <- strings do
      assert [{:string_double, _, ["\""]}, {:string_escape, _, _}, {:string_double, _, ["\""]}] =
               JsonLexer.lex(~s("\\#{string}"))

      # TODO: What this should be, according to the pygments tests:
      # https://github.com/pygments/pygments/blob/master/tests/test_data.py#L145
      #
      # assert [{:string_double, _, ^string}] = JsonLexer.lex(~s("\\#{string}"))
    end
  end

  test "Single-line comments are tokenized correctly" do
    text = ~s({"a//b"//C1\n:123/////C2\n}\n// // C3)
    tokens = JsonLexer.lex(text)

    assert {:comment_single, _, ["//", "C", "1"]} = Enum.at(tokens, 2)
    assert {:comment_single, _, ["//", "/", "/", "/", "C", "2"]} = Enum.at(tokens, 6)
    assert {:comment_single, _, ["//", " ", "/", "/", " ", "C", "3"]} = Enum.at(tokens, 10)

    assert tokens |> Enum.filter(fn {type, _, _} -> type == :comment_single end) |> length() == 3

    # Input and output texts must match!
    assert tokens |> Enum.map(fn {_, _, content} -> to_string(content) end) |> Enum.join() == text
  end

  test "Multi-line comments are tokenized correctly" do
    text = ~s(/** / **/{"a /**/ b"/* \n */:123})
    tokens = JsonLexer.lex(text)

    assert {:comment_multiline, _, "/** / *"} = Enum.at(tokens, 0)
    assert {:comment_multiline, _, "*/"} = Enum.at(tokens, 1)
    assert {:comment_multiline, _, "/* "} = Enum.at(tokens, 4)
    assert {:comment_multiline, _, " "} = Enum.at(tokens, 6)
    assert {:comment_multiline, _, "*/"} = Enum.at(tokens, 7)

    assert tokens |> Enum.filter(fn {type, _, _} -> type == :comment_multiline end) |> length() ==
             5

    # TODO: What those probably should be(?):
    # https://github.com/pygments/pygments/blob/master/tests/test_data.py#L179
    #
    # assert {:comment_multiline, _, "/** / **/"} = Enum.at(tokens, 0)
    # assert {:comment_multiline, _, "/* \n */"} = Enum.at(tokens, 3)
    # assert tokens |> Enum.filter(fn {type, _, _} -> type == :comment_multiline end) |> length() == 2

    # Input and output texts must match!
    assert tokens |> Enum.map(fn {_, _, content} -> to_string(content) end) |> Enum.join() == text
  end

  test "Unfinished or unclosed single-line comments are parsed as errors" do
    assert [{:error, _, ?/}] = JsonLexer.lex("/")
    assert [_number, {:error, _, ?/}] = JsonLexer.lex("1/")
    assert [{:error, _, ?/}, _number] = JsonLexer.lex("/1")
    assert [_string, {:error, _, ?/}] = JsonLexer.lex("\"\"/")
  end

  # TODO:
  @tag :skip
  test "Unfinished or unclosed multi-line comments are parsed as errors" do
    assert [{:error, _, _}] = JsonLexer.lex("/*")
    assert [{:error, _, _}] = JsonLexer.lex("/**")
    assert [{:error, _, _}] = JsonLexer.lex("/*/")
    assert [_number, {:error, _, _}] = JsonLexer.lex("1/*")
    assert [_string, {:error, _, _}] = JsonLexer.lex("\"\"/*")
    assert [_string, {:error, _, _}] = JsonLexer.lex("\"\"/**")
  end

  # TODO: Remove when there's no JSON-LD support planned
  @tag :skip
  test "JSON-LD keywords are parsed correctly" do
    keywords = [
      "base",
      "container",
      "context",
      "direction",
      "graph",
      "id",
      "import",
      "included",
      "index",
      "json",
      "language",
      "list",
      "nest",
      "none",
      "prefix",
      "propagate",
      "protected",
      "reverse",
      "set",
      "type",
      "value",
      "version",
      "vocab"
    ]

    for keyword <- keywords do
      key_string = ~s("@#{keyword}")
      tokens = JsonLexer.lex(~s({#{key_string}: ""}))

      assert length(tokens) == 6
      assert {:name_decorator, _, x} = Enum.at(tokens, 1)
      assert key_string == to_string(x)
    end
  end

  # TODO: Remove when there's no JSON-LD support planned
  test "JSON-LD non-keywords are parsed correctly" do
    examples = ["@bogus", "@bases", "container"]

    for example <- examples do
      key_string = ~s("@#{example}")
      tokens = JsonLexer.lex(~s({#{key_string}: ""}))

      assert length(tokens) == 6
      assert {:name_tag, _, x} = Enum.at(tokens, 1)
      assert key_string == to_string(x)
    end
  end
end
