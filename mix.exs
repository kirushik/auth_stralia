defmodule AuthStralia.Mixfile do
  use Mix.Project

  def project do
    [
      app: :auth_stralia,
      version: "0.0.1",
      elixir: "~> 0.13.1",
      deps: deps
    ]
  end

  def application do
    [
      applications: [:inets, :crypto],
      registered: [:auth_stralia],
      mod: {AuthStralia, []},

      env: env(Mix.env)
    ]
  end

  defp deps do
    [
      {:elli_http_handler, github: "kirushik/ellihandler"},
      {:ejwt, github: "kato-im/ejwt"}
    ]
  end

  def env(:dev) do
    [listen_on: 8080]
  end
  def  env(:test) do
    [listen_on: 3000]
  end
end
