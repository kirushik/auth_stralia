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
      {:ejwt, github: "kato-im/ejwt"},
      {:amrita, github: "josephwilk/amrita"}
    ]
  end

  def env(:dev) do
    [
      listen_on: 8080,
      jwt_secret: "56972e4ddccbab39a5966e79ec2ddcc556a6775d89ad9478c5bfd5ec012618e6703ec98ab29eeb0b9105f6050246b1885a2849fb3fc30c8ee276581b49f6e712"
    ]
  end
  def  env(:test) do
    [
      listen_on: 3000,
      jwt_secret: "secret"
    ]
  end
end
