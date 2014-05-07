defmodule AuthStralia do
  use Application.Behaviour

  def start(_type, _args) do
    { :ok, _pid } = AuthStralia.Supervisor.start_link([])  
  end
end

defmodule AuthStralia.Supervisor do
  use Supervisor.Behaviour

  defp elli_options do
    [ 
      callback: :elli_middleware, 
      callback_args: [
        mods: [
          {AuthStralia.API.V1.Handler, [prefix: "/api/V1/"]}, 
        ]
      ], 
      port: 3000
    ]
  end

  def start_link(stack) do
    # FIXME: Run elli correctly using supervisor
    :elli.start_link elli_options
    
    :supervisor.start_link(__MODULE__, stack)
  end

  def init([]) do
    tree = [ 
             # worker(:elli, elli_options) 
           ]
    supervise(tree, strategy: :one_for_one)
  end
end
