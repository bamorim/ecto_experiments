defmodule EctoValueObjectTest do
  use ExUnit.Case

  defmodule TupleType do
    @behaviour Ecto.Type

    def type, do: {:array, :integer}

    def cast({x, y}), do: {:ok, {x, y}}
    def cast([x, y]), do: {:ok, {x, y}}
    def cast(_), do: :error

    def dump({x, y}), do: {:ok, [x, y]}
    def dump(_), do: :error

    def load([x, y]), do: {:ok, {x, y}}
    def load(_), do: :error
  end

  defmodule MyValueObject do
    use EctoValueObject,
      simple: :string,
      custom: TupleType,
      date: :date
  end

  describe "generated type/0" do
    test "the generated type has underlying type of map" do
      assert MyValueObject.type() == :map
    end
  end

  describe "generated dump/1" do
    test "dumps underlying fields" do
      assert MyValueObject.dump(%MyValueObject{
               simple: "mystring",
               custom: {1, 2},
               date: ~D[2019-01-01]
             }) ==
               {:ok,
                %{
                  "simple" => "mystring",
                  "custom" => [1, 2],
                  "date" => "2019-01-01"
                }}
    end
  end

  describe "generated cast/1" do
    test "casts underlying fields" do
      assert MyValueObject.cast(%MyValueObject{
               simple: "mystring",
               custom: [1, 2],
               date: "2019-01-01"
             }) ==
               {:ok,
                %MyValueObject{
                  simple: "mystring",
                  custom: {1, 2},
                  date: ~D[2019-01-01]
                }}
    end

    test "allows receiving a simple map" do
      assert MyValueObject.cast(%{
               simple: "mystring",
               custom: [1, 2],
               date: "2019-01-01"
             }) ==
               {:ok,
                %MyValueObject{
                  simple: "mystring",
                  custom: {1, 2},
                  date: ~D[2019-01-01]
                }}
    end

    test "allows receiving a map with keyed structs" do
      assert MyValueObject.cast(%{
               "simple" => "mystring",
               "custom" => [1, 2],
               "date" => "2019-01-01"
             }) ==
               {:ok,
                %MyValueObject{
                  simple: "mystring",
                  custom: {1, 2},
                  date: ~D[2019-01-01]
                }}
    end

    test "discards non used keys" do
      assert MyValueObject.cast(%{
               "simple" => "mystring",
               "custom" => [1, 2],
               "date" => "2019-01-01",
               "extra" => "anything"
             }) ==
               {:ok,
                %MyValueObject{
                  simple: "mystring",
                  custom: {1, 2},
                  date: ~D[2019-01-01]
                }}
    end

    test "defaults values to nil" do
      assert MyValueObject.cast(%{}) ==
               {:ok,
                %MyValueObject{
                  simple: nil,
                  custom: nil,
                  date: nil
                }}
    end
  end

  describe "generated load/1" do
    test "works with simple types" do
      assert MyValueObject.load(%{
               "simple" => "mystring",
               "custom" => [1, 2],
               "date" => "2019-01-01"
             }) ==
               {:ok,
                %MyValueObject{
                  simple: "mystring",
                  custom: {1, 2},
                  date: ~D[2019-01-01]
                }}
    end
  end
end
