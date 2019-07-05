defmodule EctoTypeJSONCodec.Decoder do
  @moduledoc false

  import EctoTypeJSONCodec.Utils

  @spec decode(Ecto.Type.t(), EctoTypeJSONCodec.json()) :: {:ok, term()} | :error
  def decode(type, value) do
    with {:ok, decoded} <- decode_underlying(Ecto.Type.type(type), value),
         {:ok, loaded} <- Ecto.Type.load(type, decoded),
         {:ok, casted} <- Ecto.Type.cast(type, loaded) do
      {:ok, casted}
    else
      _ -> :error
    end
  end

  # No need to handle iso8601 because `Ecto.Type.cast/2` will handle that for us
  defp decode_underlying(:binary, value), do: Base.decode64(value)
  defp decode_underlying(:naive_datetime, value), do: NaiveDateTime.from_iso8601(value)
  defp decode_underlying(:naive_datetime_usec, value), do: NaiveDateTime.from_iso8601(value)
  defp decode_underlying(:utc_datetime, value), do: date_time_from_iso8601(value)
  defp decode_underlying(:utc_datetime_usec, value), do: date_time_from_iso8601(value)
  defp decode_underlying(:time, value), do: Time.from_iso8601(value)
  defp decode_underlying(:time_usec, value), do: Time.from_iso8601(value)
  defp decode_underlying(:date, value), do: Date.from_iso8601(value)

  defp decode_underlying({:array, type}, value) do
    maybe_map(value, &decode_underlying(type, &1))
  end

  defp decode_underlying({:map, type}, value) do
    with {:ok, kw} <- maybe_map(value, &decode_keypair(type, &1)) do
      {:ok, Map.new(kw)}
    end
  end

  defp decode_underlying(_, value), do: {:ok, value}

  defp date_time_from_iso8601(dt) do
    with {:ok, dt, _offset} <- DateTime.from_iso8601(dt), do: {:ok, dt}
  end

  defp decode_keypair(type, {key, val}) do
    with {:ok, decoded} <- decode_underlying(type, val) do
      {:ok, {key, decoded}}
    end
  end
end
