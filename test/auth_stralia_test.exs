defmodule AuthStraliaTest do
  use Amrita.Sweet
  use Localhost

  defp correct_id, do: "alice@example.com"
  defp correct_password, do: "Correct password"

  defp key do
    {:ok, key} = :application.get_env(:auth_stralia, :jwt_secret)
    key
  end

  defp generate_token(contents \\ { sub: correct_id,
                                    iss: "auth.example.com",
                                    jti: "1282423E-D5EE-11E3-B368-4F7D74EB0A54" },
                      timeout \\ 86400) do
    :ejwt.jwt("HS256", contents, timeout, key)
  end

  describe "/login" do
    it "returns correct JSON web token" do
      response = post('/login', %{:user_id => correct_id, :password => correct_password })
      {_claims} = :ejwt.parse_jwt(response, key)
    end
  
    it "returns 401 when incorrect password" do
      post_http_code('/login', %{:user_id => correct_id, :password => "Incorrect password"}) |> 401
    end
  end

  describe "/verify_token" do
    it "returns '0' for empty token" do
      get('/verify_token?token=') |> "0"
    end

    it "returns '1' for correct token" do
      token = bitstring_to_list(post('/login', %{:user_id => correct_id, :password => correct_password }))
      get('/verify_token?token=#{token}') |> "1"
    end

    it "returns '0' for incorrect token" do
      token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE0MDAwOTQ3NDF9.P9QOLoJg4MCnHeb3WTceFL-_fdHlkH1dJJzKwW-OHD"
      get('/verify_token?token=#{token}') |> "0"
    end

    it "returns '0' for expired token" do
      token = generate_token({[]}, -1)
      get('/verify_token?token=#{token}') |> "0"
    end

    it "returns '0' for nonexisting token" do
      token = generate_token
      get('/verify_token?token=#{token}') |> "0"
    end
  end

  describe "/session/invalidate" do
    it "fails to work without the token" do
      post_http_code('/session/invalidate') |> 401
    end

    it "works with correct token in Bearer" do
      token = bitstring_to_list(post('/login', %{:user_id => correct_id, :password => correct_password }))
      post('/session/invalidate', %{}, [{'bearer', token}]) |> "1"
    end

    it "invalidates token" do
      token = bitstring_to_list(post('/login', %{:user_id => correct_id, :password => correct_password }))
      get('/verify_token?token=#{token}') |> "1"
      post('/session/invalidate', %{}, [{'bearer', token}]) |> "1"
      post('/session/invalidate', %{}, [{'bearer', token}]) |> "0"
      get('/verify_token?token=#{token}') |> "0"
    end
  end

  describe "/sessions/invalidate/all" do
    it "invalidates two tokens at once" do
      token1 = bitstring_to_list(post('/login', %{:user_id => correct_id, :password => correct_password }))
      token2 = bitstring_to_list(post('/login', %{:user_id => correct_id, :password => correct_password }))
      get('/verify_token?token=#{token1}') |> "1"
      get('/verify_token?token=#{token2}') |> "1"

      post('/session/invalidate/all', %{}, [{'bearer', token1}]) |> "1"

      get('/verify_token?token=#{token1}') |> "0"
      get('/verify_token?token=#{token2}') |> "0"
    end
  end
end
