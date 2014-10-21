require Logger

defmodule AuthStralia do
  use Application

  def start(_type, _args) do
    Logger.info "Starting Cowboy on port #{Settings.port}"
    Plug.Adapters.Cowboy.http(AuthStralia.Router, [], port: Settings.port)
    AuthStralia.Supervisor.start_link
  end
end

defmodule AuthStralia.Supervisor do
  use Supervisor

  # {AuthStralia.API.V1.ProtectByBearer, [prefix: "/api/V1/session"]}, 
  # {AuthStralia.API.V1.Handler, [prefix: "/api/V1/"]}

  def start_link() do
    Supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    tree = [ 
             worker(AuthStralia.Storage.DB, [])
           ]
    supervise(tree, strategy: :one_for_one)
  end
end
