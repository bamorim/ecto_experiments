defmodule MapCodecEcto.EmbeddedSchemaCodec do
  @behaviour MapCodec.Encoder
  @behaviour MapCodec.Decoder

  @impl true
  @spec encode(value :: any()) :: {:ok, MapCodec.encoded_map()} | :error
  def encode(%{__struct__: schema} = value) do
    type = {:embed, Ecto.Embedded.struct(__MODULE__, :field, cardinality: :one, related: schema)}

    with {:ok, data} <- dump_embed(type, value) do
      MapCodec.SimpleEncoder.encode(data)
    end
  end

  @impl true
  @spec decode(type :: any(), MapCodec.encoded_map()) :: {:ok, any()} | :error
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
end
