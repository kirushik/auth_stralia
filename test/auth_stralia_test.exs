defmodule AuthStraliaTest do
  use Amrita.Sweet
  use Localhost

  facts "about /login" do
    fact "returns correct JSON web token" do
      response = post('/login', %{:user_id => "alice@example.com", :password => "Correct password"})
      {:ok, key} = :application.get_env(:auth_stralia, :jwt_secret)
      {_claims} = :ejwt.parse_jwt(response, key)
    end
  
    fact "returns 401 when incorrect password" do
      post_http_code('/login', %{:user_id => "alice@example.com", :password => "Incorrect password"}) |> 401
    end
  end

  facts "about /verify_token" do
    fact "returns '0' for empty token" do
      get('/verify_token?token=') |> "0"
    end

    fact "returns '1' for correct token" do
      {:ok, key} = :application.get_env(:auth_stralia, :jwt_secret)
      token = :ejwt.jwt("HS256", {[]}, 86400, key)
      get('/verify_token?token=#{token}') |> "1"
    end
  end
end
