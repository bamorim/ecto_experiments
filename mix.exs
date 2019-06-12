defmodule EctoExperiments.MixProject do
  use Mix.Project

  def project do
    [
      app: :ecto_experiments,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto, "~> 3.1.5"},
      {:jason, "~> 1.1.2"},
      {:ecto_sql, "~> 3.1.4", only: :test},
      {:postgrex, "~> 0.14.3", only: :test}
    ]
  end

  defp elixirc_paths(:test) do
    ["lib" | Path.wildcard("test/*/support")]
  end

  defp elixirc_paths(_), do: ["lib"]
end
