defmodule EctoEmbettered.TypeAsIdTest do
  use ExUnit.Case

  alias EctoEmbettered.{TestRepo, ComplexIdSchema, ComplexId}

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(TestRepo)

    id = %ComplexId{a: 1, b: 2}
    schema = %ComplexIdSchema{id: id}

    %{id: id, schema: schema}
  end

  test "we can save it to the database", ctx do
    assert {:ok, _} = TestRepo.insert(ctx.schema)
  end

  test "we can retrieve using the complex id", ctx do
    assert is_nil(TestRepo.get(ComplexIdSchema, ctx.id))
  end

  test "it retrieves successfully if it was inserted previously", ctx do
    TestRepo.insert(ctx.schema)
    assert %ComplexIdSchema{id: id} = TestRepo.get(ComplexIdSchema, ctx.id)
    assert id == ctx.id
  end
end
