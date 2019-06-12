defmodule EctoEmbettered.TestRepo.Migrations.CreateComplexIdTable do
  use Ecto.Migration

  def change do
    create table("complex_id", primary_key: false) do
      add(:id, :map, primary_key: true)
    end
  end
end
