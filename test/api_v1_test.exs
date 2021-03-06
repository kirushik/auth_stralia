defmodule ApiV1Test do
  use Amrita.Sweet
  use Localhost

  alias AuthStralia.Storage.User
  alias AuthStralia.Redis.Session
  alias AuthStralia.Redis.VerificationSession

  import TokenOperations

  defp get_new_token(expiration_time \\ Settings.expiresIn) do
    Session.new(correct_id, expiration_time)
  end

  setup_all do
    AuthStralia.Storage.DB.delete_all AuthStralia.Storage.TagToUserMapping
    AuthStralia.Storage.DB.delete_all AuthStralia.Storage.User
    AuthStralia.Storage.DB.delete_all AuthStralia.Storage.Tag
    tag1_entity = AuthStralia.Storage.Tag.create(tag1)
    tag2_entity = AuthStralia.Storage.Tag.create(tag2)

    user = User.create(correct_id, correct_password, [tag1_entity, tag2_entity])
    User.verify user

    Exredis.start |> Exredis.query ["FLUSHALL"]

    :ok
  end

  setup do
    VerificationSession.delete incorrect_id

    incorrect_user = User.find_by_uid(incorrect_id)
    if incorrect_user, do: AuthStralia.Storage.DB.delete incorrect_user

    :ok
  end

  describe "/login" do
    it "returns correct JSON web token" do
      response = post('/login', %{user_id: correct_id, password: correct_password })
      parsed = Token.parse(response)
      parsed |> ! :invalid
      is_map(parsed) |> truthy
    end

    it "returns 401 when incorrect password" do
      post_http_code('/login', %{user_id: correct_id, password: incorrect_password}) |> 401
    end

    it "returns 401 for incorrect username" do
      post_http_code('/login', %{user_id: incorrect_id, password: incorrect_password}) |> 401
    end

    it "returns token with tags" do
      response = post('/login', %{user_id: correct_id, password: correct_password })
      tags = Token.extract(response, :tags)
      [tag1, tag2] |> tags
    end

    it "shouldn't login unverified users" do
      User.create(incorrect_id, incorrect_password)
      post_http_code('/login', %{user_id: incorrect_id, password: incorrect_password}) |> 401
    end

    it "returns token with the same TTL as in Redis" do
      claims = post('/login', %{user_id: correct_id, password: correct_password }) |> Token.parse
      Session.get_ttl(claims.sub, claims.jti) |> equals to_string(claims.exp - epoch())
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
      token = generate_token(%{}, -1)
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
      jti = Token.extract(token2, :jti)

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
      sessions |> contains Token.extract(token1, :jti)
      sessions |> contains Token.extract(token2, :jti)
    end
  end

  describe "/session/update" do
    it "fails without proper token" do
      post_http_code('/session/update') |> 401
    end

    it "updates token expiration time" do
      old_token = get_new_token(1)
      new_token = post('/session/update', %{}, [{'Authorization', 'Bearer #{old_token}'}])
      (Token.extract(new_token, :exp) > 3) |> truthy # Not the best way, certainly
      Token.extract(new_token, :jti) |> equals Token.extract(old_token, :jti)
    end

    it "updates session expiration time in Redis" do
      raw_token = get_new_token(10)
      token = Token.parse(raw_token)
      Session.get_ttl(token.sub, token.jti) |> "10"

      post('/session/update', %{}, [{'Authorization', 'Bearer #{raw_token}'}])

      Session.get_ttl(token.sub, token.jti) |> equals to_string(Settings.expiresIn)
    end
  end

  # FIXME CORS need to be implemented correctly, by one who knows what he's doing;)
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
      #TODO Not the best way, but should work
      Enum.find(headers, &(match?({'access-control-allow-methods', _}, &1))) |> equals {'access-control-allow-methods', 'GET, OPTIONS, POST'}
      Enum.find(headers, &(match?({'access-control-allow-headers', _}, &1))) |> equals {'access-control-allow-headers', 'accept, authorization, content-type, origin, x-requested-with'}
    end
  end

  describe "/user/new" do
    it "should return error for existing user" do
      post_http_code('/user/new', %{user_id: correct_id, password: correct_password }) |> 409
    end

    it "should create new user" do
      User.find_by_uid(incorrect_id) |> nil
      post_http_code('/user/new', %{user_id: incorrect_id, password: incorrect_password }) |> 201
      User.find_by_uid(incorrect_id) |> ! nil
    end

    it "should provide a verification token" do
      token = post_201_response('/user/new', %{user_id: incorrect_id, password: incorrect_password })
      Token.parse(to_string(token))
    end

    it "should return 409 for subsequent registration requests" do
      post_http_code('/user/new', %{user_id: incorrect_id, password: incorrect_password }) |> 201
      post_http_code('/user/new', %{user_id: incorrect_id, password: incorrect_password }) |> 409
    end

    it "should return token with TTL same as in Redis" do
      claims = post_201_response('/user/new', %{user_id: incorrect_id, password: incorrect_password }) |> Token.parse
      VerificationSession.get_ttl(incorrect_id) |> equals to_string(claims.exp - epoch())
    end
  end

  describe "/user/verify" do
    it "should return 400 for malformed token" do
      get_http_code('/user/verify?token=QQQQiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE0MDAwOTQ3NDF9.P9QOLoJg4MCnHeb3WTceFL-_fdHlkH1dJJzKwW-OHD') |> 400
    end

    it "should return 400 for correct non-verification type token" do
      token = generate_token(%{ sub: incorrect_id,
                                typ: "some_other_token" })
      get_http_code('/user/verify?token=#{token}') |> 400
    end

    it "should return 404 for valid token for nonexistent user" do
      token = Token.generate_verification_token(incorrect_id, "")
      get_http_code('/user/verify?token=#{token}') |> 404
    end

    it "should return 409 if user is already verified" do
      token = Token.generate_verification_token(correct_id, "")
      get_http_code('/user/verify?token=#{token}') |> 409
    end

    it "should return 419 for an expired verification token" do
      post_http_code('/user/new', %{user_id: incorrect_id, password: incorrect_password }) |> 201
      token = Token.generate_verification_token(incorrect_id, "", -Settings.expiresIn - 1)
      get_http_code('/user/verify?token=#{token}') |> 401 #NOTE see helpers.ex:38
    end

    it "should return 200 for correct verification request" do
      token = post_201_response('/user/new', %{user_id: incorrect_id, password: incorrect_password })
      code = get_http_code('/user/verify?token=#{token}')
      code |> 200
    end

    it "should allow user to login after the verification" do
      token = post_201_response('/user/new', %{user_id: incorrect_id, password: incorrect_password })
      code = get_http_code('/user/verify?token=#{token}')
      code |> 200

      code = post_http_code('/login', %{user_id: incorrect_id, password: incorrect_password})
      code |> 200
    end

    it "fails to validate without proper ValidationSession present in Redis" do
      token = post_201_response('/user/new', %{user_id: incorrect_id, password: incorrect_password })
      AuthStralia.Redis.VerificationSession.delete incorrect_id

      code = get_http_code('/user/verify?token=#{token}')
      # When macros are used in amrita matcher directly, they are being called twice for some reason
      # TODO So all the tests should be rewritten to avoid those duplications
      # Or maybe ditch Amrita altogether in favor of bare ExUnit?
      code |> 401
    end

    it "shouldn't allow verification with mismatched jti" do
      token = post_201_response('/user/new', %{user_id: incorrect_id, password: incorrect_password })
      Exredis.start |> Exredis.query ["SETEX", "verification_session:#{incorrect_id}", Settings.expiresIn, ""]
      code = get_http_code('/user/verify?token=#{token}')
      code |> 401
    end

    it "should provide correct session token after successful verification" do
      verification_token = post_201_response('/user/new', %{user_id: incorrect_id, password: incorrect_password })
      session_token = get('/user/verify?token=#{verification_token}')
      get('/verify_token?token=#{session_token}') |> "1"
    end
  end

  describe "/user/proof_token" do
    it "should not work for a validated user" do
      get_http_code('/user/proof_token?user_id=#{correct_id}') |> 403
    end

    it "should not work for an non-existing user" do
      get_http_code('/user/proof_token?user_id=#{incorrect_id}') |> 404
    end

    it "should prolong non-expired token" do
      User.create(incorrect_id, incorrect_password)
      # Brutal, but I can't invent anything better. No Timecop for Elixir at the moment
      old_claims = User.verification_token_for(incorrect_id, Settings.expiresIn-1)|> Token.parse

      new_claims = get('/user/proof_token?user_id=#{incorrect_id}') |> Token.parse

      old_claims.jti |> equals new_claims.jti
      (old_claims.exp < new_claims.exp) |> truthy
    end

    it "should reissue expired token" do
      User.create(incorrect_id, incorrect_password)
      old_claims = Token.generate_verification_token(incorrect_id, "", - Settings.expiresIn - 1)|> Token.parse(:force)

      new_claims = get('/user/proof_token?user_id=#{incorrect_id}') |> Token.parse

      old_claims.jti |> ! equals new_claims.jti
    end

    it "renews expiration of the verification_session in Redis" do
      User.create(incorrect_id, incorrect_password)
      User.verification_token_for(incorrect_id, Settings.expiresIn-1)|> Token.parse
      VerificationSession.get_ttl(incorrect_id) |> ! equals to_string(Settings.expiresIn)


      get('/user/proof_token?user_id=#{incorrect_id}') |> Token.parse

      VerificationSession.get_ttl(incorrect_id) |> equals to_string(Settings.expiresIn)
      VerificationSession.get_ttl(incorrect_id) |> equals to_string(Settings.expiresIn)
    end
  end
end
