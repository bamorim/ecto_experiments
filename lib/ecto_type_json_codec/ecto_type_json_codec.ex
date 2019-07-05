defmodule EctoTypeJSONCodec do
  @moduledoc """
  Encodes and decodes an ecto type into a JSON data type. That is, a type consisting only of JSON
  valid types, such as numbers, booleans, strings, arrays and maps with string keys, as defined by
  type `t:json/1`.

  ## Encoding transformations

  Depending on the `Ecto.Type` underlying type, it may apply some transformations:

  - `:binary` - Encodes using base 64 with padding
  - `:date` - Encodes into a ISO8601 string
  - `:utc_datetime` - Encodes into a ISO8601 string
  - `:naive_datetime` - Encodes into a ISO8601 string
  - `:date` - Encodes into a ISO8601 string
  - `:time` - Encodes into a ISO8601 string
  - `:utc_datetime_usec` - Encodes into a ISO8601 string
  - `:naive_datetime_usec` - Encodes into a ISO8601 string
  - `:time_usec` - Encodes into a ISO8601 string

  Unknown types will not be converted and are expected to be already represented by a JSON value. If
  not, it not be encoded.
  """

  @typedoc """
  Represents a JSON type. That is, some JSON scalar such as number, boolean or string, or some
  composite types such as an array or a string-keyed map.
  """
  @type json :: String.t() | number() | boolean() | %{required(String.t()) => json()} | [json()]

  @doc """
  Encodes a loaded and casted value into a JSON value by dumping and applying required encoding
  rules.

  ## Examples

  It works with all native types

      iex> EctoTypeJSONCodec.encode(:integer, 1)
      {:ok, 1}

      iex> EctoTypeJSONCodec.encode(:boolean, true)
      {:ok, true}

      iex> EctoTypeJSONCodec.encode(:string, "string")
      {:ok, "string"}

      iex> EctoTypeJSONCodec.encode(:naive_datetime, ~N[2019-01-01 00:00:00])
      {:ok, "2019-01-01T00:00:00"}

      iex> EctoTypeJSONCodec.encode(:naive_datetime_usec, ~N[2019-01-01 00:00:00.000001])
      {:ok, "2019-01-01T00:00:00.000001"}

      iex> EctoTypeJSONCodec.encode(:date, ~D[2019-01-01])
      {:ok, "2019-01-01"}

      iex> EctoTypeJSONCodec.encode(:time, ~T[00:00:00])
      {:ok, "00:00:00"}

      iex> EctoTypeJSONCodec.encode(:time_usec, ~T[00:00:00.000001])
      {:ok, "00:00:00.000001"}

      iex> EctoTypeJSONCodec.encode(
      ...>   :utc_datetime,
      ...>   DateTime.from_naive!(~N[2019-01-01 00:00:00], "Etc/UTC")
      ...> )
      {:ok, "2019-01-01T00:00:00Z"}

      iex> EctoTypeJSONCodec.encode(
      ...>   :utc_datetime_usec,
      ...>   DateTime.from_naive!(~N[2019-01-01 00:00:00.000001], "Etc/UTC")
      ...> )
      {:ok, "2019-01-01T00:00:00.000001Z"}

      iex> EctoTypeJSONCodec.encode(:binary, <<1::8>>)
      {:ok, "AQ=="}

  It also works for composite types such as `{:array, type}` and `{:map, type}` and `:map`

      iex> EctoTypeJSONCodec.encode({:array, :date}, [~D[2019-01-01], ~D[2019-01-02]])
      {:ok, ["2019-01-01", "2019-01-02"]}

      iex> EctoTypeJSONCodec.encode(
      ...>   {:map, :date},
      ...>   %{today: ~D[2019-01-01], tomorrow: ~D[2019-01-02]}
      ...> )
      {:ok, %{"today" => "2019-01-01", "tomorrow" => "2019-01-02"}}

      iex> EctoTypeJSONCodec.encode(:map, %{foo: 1, bar: true})
      {:ok, %{"foo" => 1, "bar" => true}}

  It does not convert map values to json

      iex> EctoTypeJSONCodec.encode(:map, %{foo: :bar})
      :error

  It works with custom types, as long as the underlying type is supported.

  ```
  defmodule MyCustomEctoType do
    @behaviour Ecto.Type

    def type, do: :map
    def dump(value), do: {:ok, %{"value" => value}}
    def cast(value), do: {:ok, value}
    def load(%{"value" => value}), do: value
  end
  ```

      iex> EctoTypeJSONCodec.encode(MyCustomEctoType, "foo")
      {:ok, %{"value" => "foo"}}

  """
  @spec encode(Ecto.Type.t(), term()) :: {:ok, json()} | :error
  defdelegate encode(type, value), to: EctoTypeJSONCodec.Encoder

  @doc """
  Encodes a loaded and casted value into a JSON value by dumping and applying required encoding
  rules.

  ## Examples

  It works with all native types

      iex> EctoTypeJSONCodec.decode(:integer, 1)
      {:ok, 1}

      iex> EctoTypeJSONCodec.decode(:boolean, true)
      {:ok, true}

      iex> EctoTypeJSONCodec.decode(:string, "string")
      {:ok, "string"}

      iex> EctoTypeJSONCodec.decode(:naive_datetime, "2019-01-01T00:00:00")
      {:ok, ~N[2019-01-01 00:00:00]}

      iex> EctoTypeJSONCodec.decode(:naive_datetime_usec, "2019-01-01T00:00:00.000001")
      {:ok, ~N[2019-01-01 00:00:00.000001]}

      iex> EctoTypeJSONCodec.decode(:date, "2019-01-01")
      {:ok, ~D[2019-01-01]}

      iex> EctoTypeJSONCodec.decode(:time, "00:00:00")
      {:ok, ~T[00:00:00]}

      iex> EctoTypeJSONCodec.decode(:time_usec, "00:00:00.000001")
      {:ok, ~T[00:00:00.000001]}

      iex> EctoTypeJSONCodec.decode(:utc_datetime, "2019-01-01T00:00:00Z")
      {:ok, DateTime.from_naive!(~N[2019-01-01 00:00:00], "Etc/UTC")}

      iex> EctoTypeJSONCodec.decode(:utc_datetime_usec, "2019-01-01T00:00:00.000001Z")
      {:ok, DateTime.from_naive!(~N[2019-01-01 00:00:00.000001], "Etc/UTC")}

      iex> EctoTypeJSONCodec.decode(:binary, "AQ==")
      {:ok, <<1::8>>}

  It also works for composite types such as `{:array, type}` and `{:map, type}` and `:map`

      iex> EctoTypeJSONCodec.decode({:array, :date}, ["2019-01-01", "2019-01-02"])
      {:ok, [~D[2019-01-01], ~D[2019-01-02]]}

      iex> EctoTypeJSONCodec.decode({:array, {:array, :date}}, [["2019-01-01"], ["2019-01-02"]])
      {:ok, [[~D[2019-01-01]], [~D[2019-01-02]]]}

      iex> EctoTypeJSONCodec.decode(
      ...>   {:map, :date},
      ...>   %{"today" => "2019-01-01", "tomorrow" => "2019-01-02"}
      ...> )
      {:ok, %{"today" => ~D[2019-01-01], "tomorrow" => ~D[2019-01-02]}}

      iex> EctoTypeJSONCodec.decode(:map, %{"foo" => 1, "bar" => true})
      {:ok, %{"foo" => 1, "bar" => true}}

  It works with custom types, as long as the underlying type is supported.

  ```
  defmodule MyCustomEctoType do
    @behaviour Ecto.Type

    def type, do: :map
    def dump(value), do: {:ok, %{"value" => value}}
    def cast(value), do: {:ok, value}
    def load(%{"value" => value}), do: value
  end
  ```

      iex> EctoTypeJSONCodec.decode(MyCustomEctoType, %{"value" => "foo"})
      {:ok, "foo"}

  """
  @spec decode(Ecto.Type.t(), EctoTypeJSONCodec.json()) :: {:ok, term()} | :error
  defdelegate decode(type, value), to: EctoTypeJSONCodec.Decoder
end
