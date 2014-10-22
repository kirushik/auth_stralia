defmodule ApiV1Test do
  use Amrita.Sweet
  use Localhost

  alias AuthStralia.Storage.User,  as: User

  import TokenOperations

  defp get_new_token, do: post('/login', %{user_id: correct_id, password: correct_password })

  setup_all do
    AuthStralia.Storage.DB.delete_all AuthStralia.Storage.TagToUserMapping
    AuthStralia.Storage.DB.delete_all AuthStralia.Storage.User
    AuthStralia.Storage.DB.delete_all AuthStralia.Storage.Tag
    tag1_entity = AuthStralia.Storage.Tag.create(tag1)
    tag2_entity = AuthStralia.Storage.Tag.create(tag2)

    User.create(correct_id, correct_password, [tag1_entity, tag2_entity])
    :ok
  end

  setup do
    incorrect_user = User.find_by_uid(incorrect_id)
    if incorrect_user, do: AuthStralia.Storage.DB.delete incorrect_user
    :ok
  end

  describe "/login" do
    it "returns correct JSON web token" do
      response = post('/login', %{user_id: correct_id, password: correct_password })
      parsed = Token.parse(response)
      parsed |> ! :invalid
      is_list(parsed) |> truthy
    end

    it "returns 401 when incorrect password" do
      post_http_code('/login', %{user_id: correct_id, password: incorrect_password}) |> 401
    end

    it "returns token with tags" do
      response = post('/login', %{user_id: correct_id, password: correct_password })
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
      post('/session/invalidate', %{}, [{'Authorization', 'Bearer #{token}'}]) |> "1"
    end

    it "invalidates token" do
      token = get_new_token
      get('/verify_token?token=#{token}') |> "1"
      post('/session/invalidate', %{}, [{'Authorization', 'Bearer #{token}'}]) |> "1"
      post('/session/invalidate', %{}, [{'Authorization', 'Bearer #{token}'}]) |> "0"
      get('/verify_token?token=#{token}') |> "0"
    end

    it "invalidates other tokes by 'jti' value" do
      token1 = get_new_token
      token2 = post('/login', %{user_id: correct_id, password: correct_password })
      jti = Token.extract(token2, "jti")

      get('/verify_token?token=#{token2}') |> "1"
      post('/session/invalidate', %{jti: jti}, [{'Authorization', 'Bearer #{token2}'}]) |> "1"
      get('/verify_token?token=#{token1}') |> "1"
      get('/verify_token?token=#{token2}') |> "0"
    end
  end

  describe "/session/invalidate/all" do
    it "invalidates two tokens at once" do
      token0 = get_new_token
      post('/session/invalidate/all', %{}, [{'Authorization', 'Bearer #{token0}'}])

      token1 = get_new_token
      token2 = get_new_token
      get('/verify_token?token=#{token1}') |> "1"
      get('/verify_token?token=#{token2}') |> "1"

      post('/session/invalidate/all', %{}, [{'Authorization', 'Bearer #{token1}'}]) |> "2"

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
      post('/session/invalidate/all', %{}, [{'Authorization', 'Bearer #{token0}'}])


      token1 = get_new_token
      token2 = get_new_token

      {:ok, sessions} = JSON.decode get('/session/list', [{'Authorization', 'Bearer #{token1}'}])
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
      new_token = post('/session/update', %{}, [{'Authorization', 'Bearer #{token}'}])
      (Token.extract(new_token, "exp") > 3) |> truthy # Not the best way, certainly
    end
  end

  describe "CORS" do
    it "should be enabled for POST" do
      headers = post_headers('/login', %{user_id: correct_id, password: correct_password })
      headers |> contains {'access-control-allow-origin', 'http://localhost:9000'}
    end
    it "should be enabled for GET" do
      headers = fetch_headers(:get, '/verify_token?token=#{get_new_token}')
      headers |> contains {'access-control-allow-origin', 'http://localhost:9000'}
    end
    it "should be enabled for OPTIONS" do
      headers = fetch_headers(:options, '/login')
      headers |> contains {'access-control-allow-origin', 'http://localhost:9000'}
      # Not the best way, but should work
      Enum.find(headers, &(match?({'access-control-allow-methods', _}, &1))) |> equals {'access-control-allow-methods', 'GET, OPTIONS, POST'}
      Enum.find(headers, &(match?({'access-control-allow-headers', _}, &1))) |> equals {'access-control-allow-headers', 'accept, authorization, content-type, origin, x-requested-with'}
    end
  end

  describe "/user/new" do
    it "should return error for existing user" do
      post_http_code('/user/new', %{user_id: correct_id, password: correct_password })|> 409
    end

    it "should create new user" do
      User.find_by_uid(incorrect_id) |> nil
      post_http_code('/user/new', %{user_id: incorrect_id, password: incorrect_password })|> 201
      User.find_by_uid(incorrect_id) |> ! nil
    end

    it "should provide a verification token" do
      # FIXME It's almost the point when Localhost macros should be rewritten in a better fashion
      params = Localhost.params_to_string %{user_id: incorrect_id, password: incorrect_password }
      {:ok, {{_,201,_},_,code}} = Localhost.make_post_request('/user/new', "V1", [], params)
      Token.parse(to_string(code))
    end
  end
end
