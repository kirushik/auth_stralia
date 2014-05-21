Code.load_file("settings.ex")

defmodule AuthStralia.Mixfile do
  use Mix.Project

  def project do
    [
      app: :auth_stralia,
      version: "0.0.1",
      elixir: "0.13.1",
      deps: deps
    ]
  end

  def application do
    [
      applications: [:inets, :crypto, :exredis],
      registered: [:auth_stralia],
      mod: {AuthStralia, []},

      env: Config.get(Mix.env)
    ]
  end

  defp deps do
    [
      {:elli_http_handler, github: "kirushik/ellihandler"},
      {:ejwt, github: "kato-im/ejwt"},
      {:amrita, github: "josephwilk/amrita"},
      {:exredis, github: "artemeff/exredis"},
      {:uuid, github: "avtobiff/erlang-uuid", tag: "v0.4.6"},
      {:json, github: "cblage/elixir-json"},
      {:postgrex, github: "ericmj/postgrex", tag: "v0.5.0", override: true},
      {:ecto, "0.1.0"}
    ]
  end
end
