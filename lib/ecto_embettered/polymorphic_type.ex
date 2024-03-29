defmodule EctoEmbettered.PolymorphicType do
  @moduledoc """
  Creates a new `Ecto.Type` that is saved as a tagged union type where possible types are embedded
  schemas. Sicne all possible types are embedded_schemas, in runtime they are structs. And since
  structs are already "tagged" in runtime, the loaded value of this type is the struct itself.
  """

  defmacro __using__(schemas_by_name) do
    schemas = schemas_by_name |> Keyword.values()

    load_fns =
      Enum.map(schemas_by_name, fn {name, schema} ->
        quote do
          def load(%{"type" => unquote(to_string(name)), "data" => data}) do
            EctoEmbettered.Codec.decode(unquote(schema), data)
          end
        end
      end)

    dump_fns =
      Enum.map(schemas_by_name, fn {name, schema} ->
        quote do
          def dump(%unquote(schema){} = value) do
            with {:ok, dumped} <- EctoEmbettered.Codec.encode(value) do
              {:ok, %{"type" => unquote(to_string(name)), "data" => dumped}}
            end
          end
        end
      end)

    quote do
      @behaviour Ecto.Type
      def type, do: :map

      def cast(%mod{} = value) when mod in unquote(schemas), do: {:ok, value}
      def cast(_), do: :error

      unquote(load_fns)
      def load(_), do: :error

      unquote(dump_fns)
      def dump(_), do: :error
    end
  end
end
