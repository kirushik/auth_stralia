defmodule AuthStralia do
  use Application.Behaviour

  def start(_type, _args) do
    { :ok, _pid } = AuthStralia.Supervisor.start_link([])  
  end
end

defmodule AuthStralia.Supervisor do
  use Supervisor.Behaviour

  defp elli_options do
    {:ok, port} = :application.get_env(:auth_stralia, :listen_on)
    [ 
      callback: :elli_middleware, 
      callback_args: [
        mods: [
          {AuthStralia.API.V1.TokenValidator, [prefix: "/api/V1/session"]}, 
          {AuthStralia.API.V1.Handler, [prefix: "/api/V1/"]}
        ]
      ], 
      port: port
    ]
  end

  def start_link([]) do
    :supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    tree = [ 
             worker(:elli, [elli_options]) 
           ]
    supervise(tree, strategy: :one_for_one)
  end
end
