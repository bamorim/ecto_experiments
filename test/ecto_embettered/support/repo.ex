defmodule EctoEmbettered.TestRepo do
  use Ecto.Repo,
    otp_app: :ecto_experiments,
    adapter: Ecto.Adapters.Postgres
end
