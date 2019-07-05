defmodule EctoTypeJSONCodec.Encoder do
  @moduledoc false

  import EctoTypeJSONCodec.Utils

  @spec encode(Ecto.Type.t(), term()) :: {:ok, EctoTypeJSONCodec.json()} | :error
  def encode(type, value) do
    with {:ok, dumped} <- Ecto.Type.dump(type, value) do
      type
      |> Ecto.Type.type()
      |> encode_underlying(dumped)
      |> ensure_json_types()
    else
      _ -> :error
    end
  end

  defp encode_underlying(:binary, value), do: Base.encode64(value)
  defp encode_underlying(:naive_datetime, value), do: NaiveDateTime.to_iso8601(value)
  defp encode_underlying(:naive_datetime_usec, value), do: NaiveDateTime.to_iso8601(value)
  defp encode_underlying(:utc_datetime, value), do: DateTime.to_iso8601(value)
  defp encode_underlying(:utc_datetime_usec, value), do: DateTime.to_iso8601(value)
  defp encode_underlying(:time, value), do: Time.to_iso8601(value)
  defp encode_underlying(:time_usec, value), do: Time.to_iso8601(value)
  defp encode_underlying(:date, value), do: Date.to_iso8601(value)
  defp encode_underlying({:array, type}, value), do: Enum.map(value, &encode_underlying(type, &1))

  defp encode_underlying({:map, type}, value) do
    value
    |> Enum.map(fn {key, val} -> {key, encode_underlying(type, val)} end)
    |> Map.new()
  end

  defp encode_underlying(_, value), do: value

  defguardp is_json_scalar(value) when is_boolean(value) or is_binary(value) or is_number(value)

  defp ensure_json_types(value) when is_json_scalar(value), do: {:ok, value}
  defp ensure_json_types(list) when is_list(list), do: maybe_map(list, &ensure_json_types/1)
  defp ensure_json_types(%{__struct__: _}), do: :error

  defp ensure_json_types(map) when is_map(map) do
    with {:ok, keyword} <- maybe_map(map, &ensure_json_keypair_type/1) do
      {:ok, Map.new(keyword)}
    end
  end

  defp ensure_json_types(_), do: :error

  defp ensure_json_keypair_type({key, value}) when is_atom(key) or is_number(key) do
    ensure_json_keypair_type({to_string(key), value})
  end

  defp ensure_json_keypair_type({key, value}) when is_binary(key) do
    with {:ok, new_value} <- ensure_json_types(value) do
      {:ok, {key, new_value}}
    end
  end

  defp ensure_json_keypair_type(_), do: :error
end
