defmodule EctoPolymorphicType do
  @moduledoc """
  Creates a polymorphic Ecto.Type using the idea of a tagged union type.
  The reasoning is that for each type, you define a "tag" that will be saved along with it.

  Here, we use atoms as tags (that are saved as strings). To define a type you just need to:

  ## Basic Usage

  ```elixir
  defmodule MyPolymorphicType do
    use EctoPolymorphicType,
      type1: :string,
      type2: {:array, :integer}
  end
  ```

  Basically you pass a keyword list where the key is the tag that will be saved on the database and
  the right side is the actual `t:Ecto.Type.t()` that will be used.

  ## Reasoning

  The reason why we require a key is to, when using custom `t:Ecto.Type.t()` you don't have to
  serialize the module name, because that would couple your module name to your data, which is bad.

  By doing this way, we allow developers to change the implementation module name but still not
  change the database tag.

  The `Ecto.Type.t()` **must** be JSON-serializable (through EctoTypeJSONCodec) and the resulting
  dumped value will be a JSON like:

  ```json
  {
    "type": "type1",
    "value" "mystring"
  }

  ## With custom types

  Let's say you define your own `Ecto.Type.t()`, you can then use it directly

  ```elixir
  defmodule MyCustomType do
    @behaviour Ecto.Type

    # implement all callbacks...
  end

  defmodule MyPolymorphicType do
    use EctoPolymorphicType,
      type1: :string,
      type2: MyCustomType
  end
  ```

  In order to have the tag in runtime, the values are persisted as tuples, where the first element
  is the type tag and the second is the value itself.

  So a valid value for that type would be `{:type1, "some_string"}` or `{:type2, some_value}`.
  """

  defmacro __using__(types_by_tag) do
    load_fns =
      Enum.map(types_by_tag, fn {tag, type} ->
        quote do
          def load(%{"type" => unquote(to_string(tag)), "data" => encoded}) do
            with {:ok, decoded} <- EctoTypeJSONCodec.decode(unquote(type), encoded) do
              {:ok, {unquote(tag), decoded}}
            end
          end
        end
      end)

    dump_fns =
      Enum.map(types_by_tag, fn {tag, type} ->
        quote do
          def dump({unquote(tag), decoded}) do
            with {:ok, encoded} <- EctoTypeJSONCodec.encode(unquote(type), decoded) do
              {:ok, %{"type" => unquote(to_string(tag)), "data" => encoded}}
            end
          end
        end
      end)

    cast_fns =
      Enum.map(types_by_tag, fn {tag, type} ->
        quote do
          def cast({unquote(tag), value}) do
            with {:ok, casted} <- Ecto.Type.cast(unquote(type), value) do
              {:ok, {unquote(tag), casted}}
            end
          end
        end
      end)

    quote do
      @behaviour Ecto.Type
      def type, do: :map

      unquote(cast_fns)
      def cast(_), do: :error

      unquote(load_fns)
      def load(_), do: :error

      unquote(dump_fns)
      def dump(_), do: :error
    end
  end
end
