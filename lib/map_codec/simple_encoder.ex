defmodule MapCodec.SimpleEncoder do
  @moduledoc """
  Simply converts all vals to strings and tuples to lists.
  """

  @behaviour MapCodec.Encoder

  defguard is_scalar(val)
           when is_binary(val) or is_nil(val) or is_number(val) or is_boolean(val)

  @impl true
  def encode(data) do
    {:ok, convert(data)}
  end

  defp convert(data) when is_scalar(data), do: data

  defp convert(data) when is_list(data) do
    Enum.map(data, &convert/1)
  end

  defp convert(data) when is_map(data) do
    data
    |> Enum.map(fn {k, v} -> {stringify(k), convert(v)} end)
    |> Map.new()
  end

  defp convert(data) when is_atom(data), do: to_string(data)

  defp convert(data) when is_tuple(data) do
    data
    |> Tuple.to_list()
    |> convert()
  end

  defp stringify(val) when is_binary(val), do: val
  defp stringify(val) when is_atom(val), do: to_string(val)
  defp stringify(val), do: :erlang.term_to_binary(val)
end
