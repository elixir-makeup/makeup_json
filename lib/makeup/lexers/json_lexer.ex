defmodule Makeup.Lexers.JsonLexer do
  import NimbleParsec
  import Makeup.Lexer.Combinators
  import Makeup.Lexer.Groups

  @behaviour Makeup.Lexer

  # Note: Makeup.Lexers.JsonLexer lexer is derived from Makeup.Lexers.ElixirLexer. 
  # It contains code from Makeup.Lexers.ElixirLexer

  ###################################################################
  # Step #1: tokenize the input (into a list of tokens)
  ###################################################################

  whitespace = ascii_string([?\r, ?\s, ?\n, ?\f], min: 1) |> token(:whitespace)

  newlines =
    choice([string("\r\n"), string("\n")])
    |> optional(ascii_string([?\s, ?\n, ?\f, ?\r], min: 1))
    |> token(:whitespace)

  any_char = utf8_char([]) |> token(:error)

  # Numbers
  digits = ascii_string([?0..?9], min: 1)

  # bin_digits = ascii_string([?0..?1], min: 1)
  # hex_digits = ascii_string([?0..?9, ?a..?f, ?A..?F], min: 1)
  # oct_digits = ascii_string([?0..?7], min: 1)

  # # Tokens for the lexer
  # number_bin = string("0b") |> concat(bin_digits) |> token(:number_bin)
  # number_oct = string("0o") |> concat(hex_digits) |> token(:number_oct)
  # number_hex = string("0x") |> concat(oct_digits) |> token(:number_hex)

  integer = optional(string("-")) |> concat(digits)
  # Base 10
  number_integer = token(integer, :number_integer)

  # Floating point numbers
  float_scientific_notation_part =
    ascii_string([?e, ?E], 1)
    |> optional(string("-"))
    |> optional(string("+"))
    |> concat(integer)

  number_float =
    integer
    |> optional(string("."))
    |> concat(integer)
    |> optional(float_scientific_notation_part)
    |> token(:number_float)

  number_float2 =
    integer
    |> ascii_string([?e, ?E], 1)
    |> optional(string("-"))
    |> optional(string("+"))
    |> concat(integer)
    |> token(:number_float)

  normal_char =
    string("?")
    |> utf8_string([], 1)
    |> token(:string_char)

  unicode_char_in_string =
    string("\\u")
    |> ascii_string([?0..?9, ?a..?f, ?A..?F], 4)
    |> token(:string_escape)

  escaped_char =
    string("\\")
    |> utf8_string([], 1)
    |> token(:string_escape)

  punctuation =
    word_from_list(
      [":", ";", ","],
      :punctuation
    )

  # Combinators that highlight elixir expressions surrounded by a pair of delimiters.
  # Most of the time, the delimiters can be described by symple characters, but the
  # combinator that parses a struct is more complex
  combinators_inside_string = [
    unicode_char_in_string,
    escaped_char
  ]

  string_keyword =
    string_like("\"", "\"", combinators_inside_string, :name_tag)
    |> concat(token(string(":"), :punctuation))

  double_quoted_string_interpol =
    string_like("\"", "\"", combinators_inside_string, :string_double)

  object = many_surrounded_by(parsec(:root_element), "{", "}")

  array = many_surrounded_by(parsec(:root_element), "[", "]")

  multi_line_comment_root = many_surrounded_by(parsec(:root_element), "/*", "*/")

  line = repeat(lookahead_not(ascii_char([?\n])) |> utf8_string([], 1))
  multiple_lines = repeat(lookahead_not(string("*/")) |> utf8_string([], 1))

  inline_comment =
    string("//")
    |> concat(line)
    |> token(:comment_single)

  multi_line_comment =
    string("/*")
    |> concat(multiple_lines)
    |> token(:comment_multiline)

  multi_line_comment_end = string("*/") |> token(:comment_multiline)

  keyword_constants =
    word_from_list(
      ["true", "false", "null"],
      :keyword_constant
    )

  root_element_combinator =
    choice([
      whitespace,
      # Comments
      inline_comment,
      multi_line_comment,
      multi_line_comment_end,
      string_keyword,
      double_quoted_string_interpol,
      # Chars
      normal_char,
      multi_line_comment_root,
      object,
      array,
      # Numbers
      # number_bin,
      # number_oct,
      # number_hex,
      # Floats must come before integers
      number_float,
      number_float2,
      number_integer,
      keyword_constants,
      # punctuation
      punctuation,
      # If we can't parse any of the above, we highlight the next character as an error
      # and proceed from there.
      # A lexer should always consume any string given as input.
      any_char
    ])

  defp remove_initial_newline([{ttype, meta, text} | tokens]) do
    case to_string(text) do
      "\n" -> tokens
      "\n" <> rest -> [{ttype, meta, rest} | tokens]
    end
  end

  # By default, don't inline the lexers.
  # Inlining them increases performance by ~20%
  # at the cost of doubling the compilation times...
  @inline false

  @doc false
  def __as_json_language__({ttype, meta, value}) do
    {ttype, Map.put(meta, :language, :json), value}
  end

  @impl Makeup.Lexer
  defparsec(
    :root_element,
    root_element_combinator |> map({__MODULE__, :__as_json_language__, []}),
    inline: @inline
  )

  @impl Makeup.Lexer
  defparsec(
    :root,
    repeat(parsec(:root_element)),
    inline: @inline
  )

  ###################################################################
  # Step #2: postprocess the list of tokens
  ###################################################################

  defp postprocess_helper([]), do: []

  defp postprocess_helper([{:number_integer, %{language: :json}, [first, second]} | tokens]) do
    [{:number_integer, %{language: :json}, first <> second} | postprocess_helper(tokens)]
  end

  defp postprocess_helper([{:comment_multiline, %{language: :json}, "*/"} = token | tokens]),
    do: [token | postprocess_helper(tokens)]

  defp postprocess_helper([{:comment_multiline, %{language: :json}, str_list} | tokens]) do
    {curr, comment_tokens} =
      Enum.reduce(str_list, {"", []}, fn x, {curr, comment_tokens} ->
        if x in ["\n", "\r"] do
          curr_token = {:comment_multiline, %{language: :json}, curr}
          newline_token = {:whitespace, %{language: :json}, x}
          comment_tokens = comment_tokens ++ [curr_token, newline_token]
          {"", comment_tokens}
        else
          curr = curr <> x
          {curr, comment_tokens}
        end
      end)

    curr_token = {:comment_multiline, %{language: :json}, curr}
    comment_tokens = comment_tokens ++ [curr_token]
    comment_tokens ++ postprocess_helper(tokens)
  end

  defp postprocess_helper([token | tokens]), do: [token | postprocess_helper(tokens)]

  # Public API
  @impl Makeup.Lexer
  def postprocess(tokens, _opts \\ []), do: postprocess_helper(tokens)

  ###################################################################
  # Step #3: highlight matching delimiters
  ###################################################################

  @impl Makeup.Lexer
  defgroupmatcher(:match_groups,
    list: [
      open: [
        [{:punctuation, %{language: :json}, "["}]
      ],
      close: [
        [{:punctuation, %{language: :json}, "]"}]
      ]
    ],
    tuple: [
      open: [
        [{:punctuation, %{language: :json}, "{"}]
      ],
      close: [
        [{:punctuation, %{language: :json}, "}"}]
      ]
    ]
  )

  # Finally, the public API for the lexer
  @impl Makeup.Lexer
  def lex(text, opts \\ []) do
    group_prefix = Keyword.get(opts, :group_prefix, random_prefix(10))
    match_groups = Keyword.get(opts, :match_groups, true)
    {:ok, tokens, "", _, _, _} = root("\n" <> text)

    tokens =
      tokens
      |> remove_initial_newline()
      |> postprocess([])

    case match_groups do
      true ->
        match_groups(tokens, group_prefix)

      _ ->
        tokens
    end
  end
end
