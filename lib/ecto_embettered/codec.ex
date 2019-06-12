defmodule EctoEmbettered.Codec do
  @type encoded_map ::
          %{required(String.t()) => encoded_map()}
          | [encoded_map()]
          | String.t()
          | number()
          | boolean()
          | nil

  @spec encode(value :: any()) :: {:ok, encoded_map()} | :error
  def encode(%{__struct__: schema} = value) do
    type = {:embed, Ecto.Embedded.struct(__MODULE__, :field, cardinality: :one, related: schema)}

    with {:ok, data} <- dump_embed(type, value) do
      {:ok, ensure_encoded(data)}
    end
  end

  @spec decode(type :: any(), encoded_map()) :: {:ok, any()} | :error
  def decode(schema, value) do
    type = {:embed, Ecto.Embedded.struct(__MODULE__, :field, cardinality: :one, related: schema)}
    load_embed(type, value)
  end

  defp dump_embed(type, value) do
    Ecto.Type.dump(type, value, fn
      {:embed, _} = type, value -> dump_embed(type, value)
      _type, value -> {:ok, value}
    end)
  end

  defp load_embed(type, value) do
    Ecto.Type.load(type, value, fn
      {:embed, _} = type, value ->
        load_embed(type, value)

      type, value ->
        case Ecto.Type.cast(type, value) do
          {:ok, _} = ok -> ok
          _ -> :error
        end
    end)
  end

  defguard is_scalar(val)
           when is_binary(val) or is_nil(val) or is_number(val) or is_boolean(val)

  defp ensure_encoded(data) when is_scalar(data), do: data

  defp ensure_encoded(data) when is_list(data) do
    Enum.map(data, &ensure_encoded/1)
  end

  defp ensure_encoded(data) when is_map(data) do
    data
    |> Enum.map(fn {k, v} -> {stringify(k), ensure_encoded(v)} end)
    |> Map.new()
  end

  defp ensure_encoded(data) when is_atom(data), do: to_string(data)

  defp ensure_encoded(data) when is_tuple(data) do
    data
    |> Tuple.to_list()
    |> ensure_encoded()
  end

  defp stringify(val) when is_binary(val), do: val
  defp stringify(val) when is_atom(val), do: to_string(val)
  defp stringify(val), do: :erlang.term_to_binary(val)
end
