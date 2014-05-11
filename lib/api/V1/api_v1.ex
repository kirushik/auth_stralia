defmodule AuthStralia.API.V1 do
  defmodule Handler do
    use Elli.Handler

    get "/token/new" do
      data = { sub: "alice@example.com",
               iss: "auth.example.com",
               jti: "1282423E-D5EE-11E3-B368-4F7D74EB0A54" }
      expiresIn = 86400
      {:ok, key} = :application.get_env(:auth_stralia, :jwt_secret)
      http_ok :ejwt.jwt("HS256",data, expiresIn, key)
    end
  end
end