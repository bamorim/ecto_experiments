defmodule EctoValueObject do
  @moduledoc """
  A DSL to define a composite `t:Ecto.Type.t/0` that has many fields. It is like a subset of an
  `Ecto.Schema` embedded_schema, but it is way simpler.

  Since the idea of a value object is that everything is self-contained, it doesn't need to be able
  to keep changes to a specific part of it. This is, the value of the data is the whole data, so we
  don't need to keep track of changes. We just change everything.

  ## Usage

  You need to import this module and call `EctoValueObject.value_object/1` macro.

  ```elixir
  defmodule MyType do
    use EctoValueObject,
      a: :string,
      b: :integer
  end
  ```

  And then you can use on your `Ecto.Schema`

  ```elixir
  defmodule MySchema do
    use Ecto.Schema

    schema "table" do
      field(:val, MyType)
    end
  end
  ```
  """

  defmacro __using__(types_by_field) do
    fields = Keyword.keys(types_by_field)

    quote do
      @behaviour Ecto.Type
      defstruct unquote(fields)

      def type, do: :map
      def cast(value), do: EctoValueObject.__cast__(value, __MODULE__, unquote(types_by_field))
      def dump(value), do: EctoValueObject.__dump__(value, __MODULE__, unquote(types_by_field))
      def load(value), do: EctoValueObject.__load__(value, __MODULE__, unquote(types_by_field))
    end
  end

  def __cast__(%mod{} = struct, mod, fields) do
    struct
    |> Map.from_struct()
    |> map_fields(&Ecto.Type.cast(&1, &2), fields)
    |> ok_map(&struct(mod, &1))
  end

  def __cast__(values, mod, fields) when is_map(values) do
    values
    |> move_values_into_struct(mod)
    |> __cast__(mod, fields)
  end

  def __cast__(_, _, _), do: :error

  def __dump__(%mod{} = struct, mod, fields) do
    struct
    |> Map.from_struct()
    |> map_fields(&EctoTypeJSONCodec.encode(&1, &2), fields)
    |> ok_map(&Enum.map(&1, fn {k, v} -> {to_string(k), v} end))
    |> ok_map(&Map.new/1)
  end

  def __dump__(_, _, _), do: :error

  def __load__(values, mod, fields) when is_map(values) do
    values
    |> move_values_into_struct(mod)
    |> Map.from_struct()
    |> map_fields(&EctoTypeJSONCodec.decode(&1, &2), fields)
    |> ok_map(&struct(mod, &1))
  end

  def __load__(_, _, _), do: :error

  defp move_values_into_struct(values, mod) do
    atomized_kw =
      mod
      |> struct()
      |> Map.from_struct()
      |> Enum.map(fn {key, default} ->
        with nil <- Map.get(values, key),
             nil <- Map.get(values, to_string(key)) do
          {key, default}
        else
          value ->
            {key, value}
        end
      end)

    struct(mod, atomized_kw)
  end

  defp map_fields(field_kw, fun, types) do
    field_kw
    |> Enum.map(fn
      {key, val} ->
        with type when not is_nil(type) <- Keyword.get(types, key),
             {:ok, dumped} <- fun.(type, val) do
          {:ok, {key, dumped}}
        else
          _ ->
            :error
        end
    end)
    |> all_or_nothing()
  end

  defp all_or_nothing(list) do
    case Enum.group_by(list, &(&1 == :error)) do
      %{true => [_ | _]} ->
        :error

      %{false => values} ->
        {:ok, Enum.map(values, &elem(&1, 1))}
    end
  end

  defp ok_map({:ok, val}, fun), do: {:ok, fun.(val)}
  defp ok_map(:error, _), do: :error
end
