defmodule MapCodecEcto.EmbeddedSchemaCodecTest do
  use ExUnit.Case

  alias MapCodecEcto.EmbeddedSchemaCodec

  defmodule NestedSchema do
    use Ecto.Schema

    @primary_key false
    embedded_schema do
      field(:foo, :string)
    end
  end

  defmodule EmbeddedSchema do
    use Ecto.Schema

    @primary_key false
    embedded_schema do
      field(:foo, :string)
      field(:bar, :integer)
      embeds_one(:ns, NestedSchema)
      embeds_many(:nss, NestedSchema)
    end
  end

  setup do
    %{
      schema: %EmbeddedSchema{
        foo: "foo_val",
        bar: 1,
        ns: %NestedSchema{foo: "ns_foo_val"},
        nss: [
          %NestedSchema{foo: "nss_1_foo_val"},
          %NestedSchema{foo: "nss_2_foo_val"}
        ]
      },
      encoded: %{
        "foo" => "foo_val",
        "bar" => 1,
        "ns" => %{"foo" => "ns_foo_val"},
        "nss" => [
          %{"foo" => "nss_1_foo_val"},
          %{"foo" => "nss_2_foo_val"}
        ]
      }
    }
  end

  describe "encode/1" do
    test "encodes into a JSON-like map", ctx do
      assert {:ok, ctx.encoded} == EmbeddedSchemaCodec.encode(ctx.schema)
    end
  end

  describe "decode/2" do
    test "decodes back to the schema struct", ctx do
      assert {:ok, ctx.schema} == EmbeddedSchemaCodec.decode(EmbeddedSchema, ctx.encoded)
    end
  end
end
