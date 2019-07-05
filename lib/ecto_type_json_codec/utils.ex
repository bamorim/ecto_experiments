defmodule EctoTypeJSONCodec.Utils do
  @moduledoc false
  def maybe_map(list, fun) do
    list
    |> Enum.reverse()
    |> Enum.reduce_while({:ok, []}, fn value, {:ok, values} ->
      case fun.(value) do
        {:ok, value} ->
          {:cont, {:ok, [value | values]}}

        _ ->
          {:halt, :error}
      end
    end)
  end
end
