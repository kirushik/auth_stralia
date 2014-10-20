defmodule AuthStralia.API.V1.Router do
  use Plug.Router

  import Plug.Conn

  plug :match
  plug :dispatch

  forward "/login", to: AuthStralia.API.V1.Login
end
