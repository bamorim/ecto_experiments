defmodule EctoEmbettered.ComplexId do
  use Ecto.Schema

  @primary_key false
  embedded_schema do
    field(:a, :integer)
    field(:b, :integer)
  end
end
