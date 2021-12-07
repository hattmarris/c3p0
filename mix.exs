defmodule C3p0.MixProject do
  use Mix.Project

  def project do
    [
      app: :c3p0,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      escript: [main_module: C3p0.Cli],
      deps: deps()
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
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:git_cli, "~> 0.3"},
      {:jason, "~> 1.2"},
      {:tentacat, "~> 2.0"}
    ]
  end
end
