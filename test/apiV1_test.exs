defmodule ApiV1Test do
  use Amrita.Sweet
  use Localhost

  defp correct_id, do: "alice@example.com"
  defp correct_password, do: "Correct password"
  defp get_new_token, do: post('/login', %{:user_id => correct_id, :password => correct_password })

  alias Settings, as: S

  # Can be better. Borrowed from EJWT code itself
  defp epoch do
    :calendar.datetime_to_gregorian_seconds(:calendar.now_to_universal_time(:os.timestamp())) - 719528 * 24 * 3600
  end

  defp generate_token(contents \\ { sub: correct_id,
                                    iss: "auth.example.com",
                                    jti: "1282423E-D5EE-11E3-B368-4F7D74EB0A54" },
                      timeout \\ 86400) do
    :ejwt.jwt("HS256", contents, timeout, S.jwt_secret)
  end

  defp set_expiration_time(token, new_timeout) do
    {parsed_token} = :ejwt.parse_jwt(token, S.jwt_secret)
    contents = :lists.map(
      fn({a,b})->
        {binary_to_atom(a),b }; 
      end, parsed_token)
    contents = {:proplists.delete(:exp, contents)}
    generate_token(contents, new_timeout)
  end
  defp get_expiration_time(token) do
    {parsed_token} = :ejwt.parse_jwt(token, S.jwt_secret)
    :proplists.get_value("exp", parsed_token) - epoch()
  end

  defp extract_jti_from_token(token) do
    {parsed_token} = :ejwt.parse_jwt(token, S.jwt_secret)
    :proplists.get_value("jti", parsed_token)
  end

  describe "/login" do
    it "returns correct JSON web token" do
      response = post('/login', %{:user_id => correct_id, :password => correct_password })
      {_claims} = :ejwt.parse_jwt(response, S.jwt_secret)
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
      jti = extract_jti_from_token(token2)

      get('/verify_token?token=#{token2}') |> "1"
      post('/session/invalidate', %{:jti => jti}, [{'bearer', token1}]) |> "1"
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
      post_http_code('/session/list') |> 401
    end

    it "lists all sessions" do
      token0 = get_new_token
      # Ensure there are no sessions for our user
      post('/session/invalidate/all', %{}, [{'bearer', token0}])


      token1 = get_new_token
      token2 = get_new_token

      {:ok, sessions} = JSON.decode get('/session/list', [{'bearer', token1}])
      length(sessions) |> 2
      sessions |> contains extract_jti_from_token(token1)
      sessions |> contains extract_jti_from_token(token2)
    end
  end

  describe "/session/update" do
    it "fails without proper token" do
      post_http_code('/session/update') |> 401
    end

    it "updates token expiration time" do
      token = get_new_token
      token = set_expiration_time(token, 3)
      new_token = post('/session/update', %{}, [{'bearer', token}])
      (get_expiration_time(new_token) > 3) |> truthy # Not the best way, certainly
    end
  end
end
