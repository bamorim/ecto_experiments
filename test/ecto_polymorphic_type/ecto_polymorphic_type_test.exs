defmodule EctoPolymorphicTypeTest do
  use ExUnit.Case

  defmodule TupleType do
    @behaviour Ecto.Type

    def type, do: {:array, :integer}

    def cast({x, y}), do: {:ok, {x, y}}
    def cast(_), do: :error

    def dump({x, y}), do: {:ok, [x, y]}
    def dump(_), do: :error

    def load([x, y]), do: {:ok, {x, y}}
    def load(_), do: :error
  end

  defmodule MyPolymorphicType do
    use EctoPolymorphicType,
      simple: :string,
      custom: TupleType,
      date: :date
  end

  describe "generated type/0" do
    test "the generated type has underlying type of map" do
      assert MyPolymorphicType.type() == :map
    end
  end

  describe "generated dump/1" do
    test "works with simple types" do
      assert MyPolymorphicType.dump({:simple, "mystring"}) ==
               {:ok,
                %{
                  "type" => "simple",
                  "data" => "mystring"
                }}
    end

    test "works with custom types" do
      assert MyPolymorphicType.dump({:custom, {1, 2}}) ==
               {:ok,
                %{
                  "type" => "custom",
                  "data" => [1, 2]
                }}
    end

    test "works with types that require json encoding" do
      assert MyPolymorphicType.dump({:date, ~D[2019-01-01]}) ==
               {:ok,
                %{
                  "type" => "date",
                  "data" => "2019-01-01"
                }}
    end

    test "validates the type" do
      assert MyPolymorphicType.dump({:invalid, "any"}) == :error
    end
  end

  describe "generated cast/1" do
    test "casts the underlying type" do
      assert MyPolymorphicType.cast({:date, "2019-01-01"}) == {:ok, {:date, ~D[2019-01-01]}}
    end

    test "propagates the error" do
      assert MyPolymorphicType.cast({:custom, {1, 2, 3}}) == :error
    end
  end

  describe "generated load/1" do
    test "works with simple types" do
      assert MyPolymorphicType.load(%{
               "type" => "simple",
               "data" => "mystring"
             }) == {:ok, {:simple, "mystring"}}
    end

    test "works with custom types" do
      assert MyPolymorphicType.load(%{
               "type" => "custom",
               "data" => [1, 2]
             }) == {:ok, {:custom, {1, 2}}}
    end

    test "works with types that require json encoding" do
      assert MyPolymorphicType.load(%{
               "type" => "date",
               "data" => "2019-01-01"
             }) == {:ok, {:date, ~D[2019-01-01]}}
    end

    test "validates the type" do
      assert MyPolymorphicType.load(%{
               "type" => "invalid",
               "data" => "any"
             }) == :error
    end
  end
end
