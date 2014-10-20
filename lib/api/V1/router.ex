defmodule AuthStralia.API.V1.Router do
  use Plug.Router

  plug :match
  plug :dispatch

  forward "login", to: AuthStralia.API.V1.Login
  forward "verify_token", to: AuthStralia.API.V1.VerifyToken
end
