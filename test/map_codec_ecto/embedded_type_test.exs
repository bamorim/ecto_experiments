defmodule MapCodecEcto.EmbeddedTypeTest do
  use ExUnit.Case

  defmodule Schema do
    use Ecto.Schema

    @primary_key false
    embedded_schema do
      field(:x, :string)
    end
  end

  defmodule OtherSchema do
    use Ecto.Schema

    @primary_key false
    embedded_schema do
      field(:x, :string)
    end
  end

  defmodule MyType do
    use MapCodecEcto.EmbeddedType, schema: Schema
  end

  describe "generated type/0" do
    test "it is a map" do
      assert MyType.type() == :map
    end
  end

  describe "generated dump/1" do
    test "saves the value as the encoded value" do
      assert MapCodecEcto.EmbeddedSchemaCodec.encode(%Schema{x: "x"}) ==
               MyType.dump(%Schema{x: "x"})
    end

    test "it returns an error for other values" do
      assert :error = MyType.dump(%OtherSchema{x: "x"})
    end
  end

  describe "dumping and loading" do
    test "we can dump and load correctly" do
      {:ok, dumped} = MyType.dump(%Schema{x: "x"})
      assert {:ok, %Schema{x: "x"}} == MyType.load(dumped)
    end
  end
end
