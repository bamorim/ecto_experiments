defmodule EctoEmbettered.PolymorphicTypeTest do
  use ExUnit.Case

  defmodule Schema1 do
    use Ecto.Schema

    @primary_key false
    embedded_schema do
      field(:x, :string)
    end
  end

  defmodule Schema2 do
    use Ecto.Schema

    @primary_key false
    embedded_schema do
      field(:y, :string)
    end
  end

  defmodule MyType do
    use EctoEmbettered.PolymorphicType,
      s1: Schema1,
      s2: Schema2
  end

  describe "generated type/0" do
    test "it is a map" do
      assert MyType.type() == :map
    end
  end

  describe "generated dump/1" do
    test "saves the atom as the type" do
      assert {:ok, %{"type" => "s1"}} = MyType.dump(%Schema1{x: "x"})
      assert {:ok, %{"type" => "s2"}} = MyType.dump(%Schema2{y: "y"})
    end

    test "saves the value as the encoded value" do
      assert {:ok, %{"data" => encoded}} = MyType.dump(%Schema1{x: "x"})
      assert {:ok, encoded} == EctoEmbettered.Codec.encode(%Schema1{x: "x"})
    end
  end

  describe "dumping and loading" do
    test "we can dump and load correctly" do
      {:ok, dumped} = MyType.dump(%Schema1{x: "x"})
      assert {:ok, %Schema1{x: "x"}} == MyType.load(dumped)

      {:ok, dumped} = MyType.dump(%Schema2{y: "y"})
      assert {:ok, %Schema2{y: "y"}} == MyType.load(dumped)
    end
  end
end
