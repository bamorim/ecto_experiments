defmodule EctoEmbettered.Type do
  defmacro __using__(schema: schema) do
    quote do
      @behaviour Ecto.Type
      def type, do: :map

      def cast(%unquote(schema){} = value), do: {:ok, value}
      def cast(_), do: :error

      def load(data) do
        EctoEmbettered.Codec.decode(unquote(schema), data)
      end

      def dump(%unquote(schema){} = value) do
        EctoEmbettered.Codec.encode(value)
      end

      def dump(_), do: :error
    end
  end
end
