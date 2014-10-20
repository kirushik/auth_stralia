defmodule AuthStralia.API.V1.Router do
  use Plug.Router

  plug :match
  plug :dispatch

  forward "login", to: AuthStralia.API.V1.LoginController
  forward "verify_token", to: AuthStralia.API.V1.VerifyTokenController
  forward "session", to: AuthStralia.API.V1.SessionController
end
