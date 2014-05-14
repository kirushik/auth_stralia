defmodule AuthStraliaTest do
  use Amrita.Sweet
  use Localhost

  def correct_id, do: "alice@example.com"
  def correct_password, do: "Correct password"

  def key do
    {:ok, key} = :application.get_env(:auth_stralia, :jwt_secret)
    key
  end

  describe "/login" do
    it "returns correct JSON web token" do
      response = post('/login', %{:user_id => correct_id, :password => correct_password })
      {_claims} = :ejwt.parse_jwt(response, key)
    end
  
    it "returns 401 when incorrect password" do
      post_http_code('/login', %{:user_id => "alice@example.com", :password => "Incorrect password"}) |> 401
    end
  end

  describe "/verify_token" do
    it "returns '0' for empty token" do
      get('/verify_token?token=') |> "0"
    end

    it "returns '1' for correct token" do
      token = :ejwt.jwt("HS256", {[]}, 86400, key)
      get('/verify_token?token=#{token}') |> "1"
    end

    it "returns '0' for incorrect token" do
      token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE0MDAwOTQ3NDF9.P9QOLoJg4MCnHeb3WTceFL-_fdHlkH1dJJzKwW-OHD"
      get('/verify_token?token=#{token}') |> "0"
    end

    it "returns '0' for expired token" do
      token = :ejwt.jwt("HS256", {[]}, -1, key)
      get('/verify_token?token=#{token}') |> "0"
    end
  end

  # describe "/session/invalidate" do
  #   it "fails to work without the token" do
  #     post_http_code('/session/invalidate', %{}) |> 401
  #   end
  # end
end
