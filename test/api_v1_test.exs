defmodule ApiV1Test do
  use Amrita.Sweet
  use Localhost
  import TokenOperations

  defp get_new_token, do: post('/login', %{:user_id => correct_id, :password => correct_password })

  setup_all do
    AuthStralia.Storage.DB.delete_all AuthStralia.Storage.TagToUserMapping
    AuthStralia.Storage.DB.delete_all AuthStralia.Storage.User
    AuthStralia.Storage.DB.delete_all AuthStralia.Storage.Tag
    tag1_entity = AuthStralia.Storage.Tag.create(tag1)
    tag2_entity = AuthStralia.Storage.Tag.create(tag2)
    AuthStralia.Storage.User.create(correct_id, correct_password, [tag1_entity, tag2_entity])
    :ok
  end

  describe "/login" do
    it "returns correct JSON web token" do
      response = post('/login', %{:user_id => correct_id, :password => correct_password })
      parsed = Token.parse(response)
      parsed |> ! :invalid
      is_list(parsed) |> truthy
    end

    it "returns 401 when incorrect password" do
      post_http_code('/login', %{:user_id => correct_id, :password => "Incorrect password"}) |> 401
    end

    it "returns token with tags" do
      response = post('/login', %{:user_id => correct_id, :password => correct_password })
      tags = Token.extract(response, "tags")
      [tag1, tag2] |> tags
    end
  end

  describe "/verify_token" do
    it "returns '0' for empty token" do
      get('/verify_token?token=') |> "0"
    end

    it "returns '1' for correct token" do
      token = get_new_token
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
      token = get_new_token
      post('/session/invalidate', %{}, [{'bearer', token}]) |> "1"
    end

    it "invalidates token" do
      token = get_new_token
      get('/verify_token?token=#{token}') |> "1"
      post('/session/invalidate', %{}, [{'bearer', token}]) |> "1"
      post('/session/invalidate', %{}, [{'bearer', token}]) |> "0"
      get('/verify_token?token=#{token}') |> "0"
    end

    it "invalidates other tokes by 'jti' value" do
      token1 = get_new_token
      token2 = post('/login', %{:user_id => correct_id, :password => correct_password })
      jti = Token.extract(token2, "jti")

      get('/verify_token?token=#{token2}') |> "1"
      post('/session/invalidate', %{jti: jti}, [{'bearer', token2}]) |> "1"
      get('/verify_token?token=#{token1}') |> "1"
      get('/verify_token?token=#{token2}') |> "0"
    end
  end

  describe "/session/invalidate/all" do
    it "invalidates two tokens at once" do
      token0 = get_new_token
      post('/session/invalidate/all', %{}, [{'bearer', token0}])

      token1 = get_new_token
      token2 = get_new_token
      get('/verify_token?token=#{token1}') |> "1"
      get('/verify_token?token=#{token2}') |> "1"

      post('/session/invalidate/all', %{}, [{'bearer', token1}]) |> "2"

      get('/verify_token?token=#{token1}') |> "0"
      get('/verify_token?token=#{token2}') |> "0"
    end

    it "fails without proper token" do
      post_http_code('/session/invalidate/all') |> 401
    end
  end

  describe "/session/list" do
    it "fails without proper token" do
      get_http_code('/session/list') |> 401
    end

    it "lists all sessions" do
      token0 = get_new_token
      # Ensure there are no sessions for our user
      post('/session/invalidate/all', %{}, [{'bearer', token0}])


      token1 = get_new_token
      token2 = get_new_token

      {:ok, sessions} = JSON.decode get('/session/list', [{'bearer', token1}])
      length(sessions) |> 2
      sessions |> contains Token.extract(token1, "jti")
      sessions |> contains Token.extract(token2, "jti")
    end
  end

  describe "/session/update" do
    it "fails without proper token" do
      post_http_code('/session/update') |> 401
    end

    it "updates token expiration time" do
      token = get_new_token
      token = Token.update_expiration_time(token, 3)
      new_token = post('/session/update', %{}, [{'bearer', token}])
      (Token.extract(new_token, "exp") > 3) |> truthy # Not the best way, certainly
    end
  end
end
