defmodule ElRedis.Resp do
    @moduledoc """
    This module allows for the encoding and decoding functions
    to work with RESP (REdis Binary Protocol). Much of the parsing code in this module
    is from: Redix https://hexdocs.pm/redix/Redix.html [MIT License] which is a redis client
    """

    @crlf "\r\n"
    @simple_string "+"
    @bulk_string "$"
    @error_string "-"
    @null_string "$-1\r\n"

    def parse("+" <> rest), do: parse_simple_string(rest)
    def parse(":" <> rest), do: parse_integer(rest)
    def parse("$" <> rest), do: parse_bulk_string(rest)
    def parse("*" <> rest), do: parse_array(rest)
    def parse(""), do: {:continuation, &parse/1}

    def parse(<<byte>> <> _),
        do: raise(ParseError, message: "invalid type specifier (#{inspect(<<byte>>)})")

    def parse_multi(data, nelems)

    def parse_multi(data, 1) do
        resolve_cont(parse(data), &{:ok, [&1], &2})
    end

    def parse_multi(data, n) do
        take_elems(data, n, [])
    end

    # Type parsers

    defp parse_simple_string(data) do
        until_crlf(data)
    end

    defp parse_integer(""), do: {:continuation, &parse_integer/1}

    defp parse_integer("-" <> rest),
        do: resolve_cont(parse_integer_without_sign(rest), &{:ok, -&1, &2})

    defp parse_integer(bin), do: parse_integer_without_sign(bin)

    defp parse_integer_without_sign("") do
        {:continuation, &parse_integer_without_sign/1}
    end

    defp parse_integer_without_sign(<<digit, _::binary>> = bin) when digit in ?0..?9 do
        resolve_cont(parse_integer_digits(bin, 0), fn i, rest ->
        resolve_cont(until_crlf(rest), fn
            "", rest ->
            {:ok, i, rest}

            <<char, _::binary>>, _rest ->
            raise ParseError, message: "expected CRLF, found: #{inspect(<<char>>)}"
        end)
        end)
    end

    defp parse_integer_without_sign(<<non_digit, _::binary>>) do
        raise ParseError, message: "expected integer, found: #{inspect(<<non_digit>>)}"
    end

    defp parse_integer_digits(<<digit, rest::binary>>, acc) when digit in ?0..?9,
        do: parse_integer_digits(rest, acc * 10 + (digit - ?0))

    defp parse_integer_digits(<<_non_digit, _::binary>> = rest, acc), do: {:ok, acc, rest}
    defp parse_integer_digits(<<>>, acc), do: {:continuation, &parse_integer_digits(&1, acc)}

    defp parse_bulk_string(rest) do
        resolve_cont(parse_integer(rest), fn
        -1, rest ->
            {:ok, nil, rest}

        size, rest ->
            parse_string_of_known_size(rest, size)
        end)
    end

    defp parse_string_of_known_size(data, size) do
        case data do
        <<str::bytes-size(size), @crlf, rest::binary>> ->
            {:ok, str, rest}

        _ ->
            {:continuation, &parse_string_of_known_size(data <> &1, size)}
        end
    end

    defp parse_array(rest) do
        resolve_cont(parse_integer(rest), fn
        -1, rest ->
            {:ok, nil, rest}

        size, rest ->
            take_elems(rest, size, [])
        end)
    end

    defp until_crlf(data, acc \\ "")

    defp until_crlf(<<@crlf, rest::binary>>, acc), do: {:ok, acc, rest}
    defp until_crlf(<<>>, acc), do: {:continuation, &until_crlf(&1, acc)}
    defp until_crlf(<<?\r>>, acc), do: {:continuation, &until_crlf(<<?\r, &1::binary>>, acc)}
    defp until_crlf(<<byte, rest::binary>>, acc), do: until_crlf(rest, <<acc::binary, byte>>)

    defp take_elems(data, 0, acc) do
        {:ok, Enum.reverse(acc), data}
    end

    defp take_elems(<<_, _::binary>> = data, n, acc) when n > 0 do
        resolve_cont(parse(data), fn elem, rest ->
        take_elems(rest, n - 1, [elem | acc])
        end)
    end

    defp take_elems(<<>>, n, acc) do
        {:continuation, &take_elems(&1, n, acc)}
    end

    defp resolve_cont({:ok, val, rest}, ok) when is_function(ok, 2), do: ok.(val, rest)

    defp resolve_cont({:continuation, cont}, ok),
        do: {:continuation, fn new_data -> resolve_cont(cont.(new_data), ok) end}

    @doc """
    If it is an error message
    """
    def encode(["Error", error_type, error_message] = message) do
        @error_string <> error_type <> " " <> error_message <> @crlf
    end

    @doc """
    If a single binary-safe message, encode as a bulk string
    """
    def encode([messsage]) do
        @bulk_string <> (String.length(messsage) |> Integer.to_string) <> @crlf <> messsage <> @crlf
    end

    @doc """
    A Null Bulk reply
    """
    def encode("") do
        @null_string
    end

    @doc """
    If an array encode as RESP array
    """
    def encode(items) when is_list(items) do
        {packed, size} =
        Enum.map_reduce(items, 0, fn item, acc ->
            string = to_string(item)
            packed_item = [?$, Integer.to_string(byte_size(string)), @crlf, string, @crlf]
            {packed_item, acc + 1}
        end)
    
        [?*, Integer.to_string(size), @crlf, packed]
    end

    @doc """
    If the message is an Integer
    """
    def encode(message) when is_integer(message) do
        ":#{message}" <> @crlf
    end
    @doc """
    Encode as a simple RESP string
    """
    def encode(message) do
        @simple_string <> message <> @crlf
    end
end