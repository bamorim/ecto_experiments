defmodule MyCustomEctoType do
  @behaviour Ecto.Type

  def type, do: :map
  def dump(value), do: {:ok, %{"value" => value}}
  def cast(value), do: {:ok, value}
  def load(%{"value" => value}), do: {:ok, value}
end
