defmodule AuthStralia do
  use Application.Behaviour

  def start(_type, _args) do
    { :ok, _pid } = AuthStralia.Supervisor.start_link([])  
  end
end

defmodule AuthStralia.Supervisor do
  use Supervisor.Behaviour

  alias Settings, as: S

  defp elli_options do
    [ 
      callback: :elli_middleware, 
      callback_args: [
        mods: [
          {AuthStralia.API.V1.TokenValidator, [prefix: "/api/V1/session"]}, 
          {AuthStralia.API.V1.Handler, [prefix: "/api/V1/"]}
        ]
      ], 
      port: S.port
    ]
  end

  def start_link([]) do
    :supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    tree = [ 
             worker(:elli, [elli_options]) ,
             worker(AuthStralia.Storage.DB, [])
           ]
    supervise(tree, strategy: :one_for_one)
  end
end
