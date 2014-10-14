Code.load_file("settings.ex")

defmodule AuthStralia.Mixfile do
  use Mix.Project

  def project do
    [
      app: :auth_stralia,
      version: "0.0.1",
      elixir: "1.0.0",
      deps: deps
    ]
  end

  def application do
    [
      applications: [:inets, :crypto, :exredis, :postgrex, :ecto],
      registered: [:auth_stralia],
      mod: {AuthStralia, []},

      env: Config.get(Mix.env)
    ]
  end

  defp deps do
    [
      {:elli_http_handler, github: "kirushik/ellihandler"},
      {:ejwt, github: "kato-im/ejwt"},
      {:amrita, github: "josephwilk/amrita", branch: "chasing-elixir-master"},
      {:exredis, github: "artemeff/exredis"},
      {:uuid, github: "avtobiff/erlang-uuid", tag: "v0.4.6"},
      {:json, github: "cblage/elixir-json"},
      {:postgrex, github: "ericmj/postgrex", tag: "v0.6.0", override: true},
      {:ecto, "0.2.5"},
      {:pbkdf2, github: "basho/erlang-pbkdf2", tag: "2.0.0"}
    ]
  end
end
