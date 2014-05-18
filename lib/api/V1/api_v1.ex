defmodule AuthStralia.API.V1 do
  defmodule Handler do
    use Elli.Handler

    alias AuthStralia.Caching.Sessions, as: Sessions

    post "/login" do
      uid = req.post_arg("user_id")
      session_id = generate_uuid()

      if (!check_credentials(uid,req.post_arg("password"))) do
        {401, [], "Authorization failed"}
      else
        data = { sub: uid,
                 iss: "auth.example.com",
                 jti: session_id }
        expiresIn = 86400
        {:ok, key} = :application.get_env(:auth_stralia, :jwt_secret)

        Sessions.add(uid, session_id)

        http_ok :ejwt.jwt("HS256",data, expiresIn, key)
      end
    end

    get "/verify_token", with_params token do
      {:ok, key} = :application.get_env(:auth_stralia, :jwt_secret)    

      res = case :ejwt.parse_jwt(token, key) do
        { [value|_] } when is_tuple(value) -> Sessions.check(get_token_field(token, "sub"), get_token_field(token, "jti"))
        _ -> "0"
      end
      http_ok res
    end

    post "/session/invalidate" do
      token = req.get_header("Bearer")

      sub = get_token_field(token, "sub")
      jti = req.post_arg("jti")
      if jti==:undefined do
        jti = get_token_field(token, "jti")
      end
      http_ok Sessions.remove(sub, jti)
    end

    post "/session/invalidate/all" do
      token = req.get_header("Bearer")
      sub = get_token_field(token, "sub")
      http_ok Sessions.remove_all(sub)
    end

    get "/session/list" do
      token = req.get_header("Bearer")
      sub = get_token_field(token, "sub")
      http_ok JSON.encode!(Sessions.list(sub))
    end
################################################################################################################################
## PRIVATE
################################################################################################################################

    #TODO Here goes our database stuff
    defp check_credentials(user_id, password) do
      ("alice@example.com" == user_id) and ("Correct password" == password)
    end

    defp get_token_field(token, name) do
      {parsed_token} = :ejwt.parse_jwt(token, key)
      :proplists.get_value(name, parsed_token)
    end

    #TODO It should come in separate module to be included everywhere
    defp key do
      {:ok, key} = :application.get_env(:auth_stralia, :jwt_secret)
      key
    end
    defp generate_uuid do
      list_to_bitstring( :uuid.to_string(:uuid.uuid4()))
    end
  end

  defmodule TokenValidator do
    use Elli.Handler

    defp key do
      {:ok, key} = :application.get_env(:auth_stralia, :jwt_secret)
      key
    end
    defp protect_by_token(req) do
      token = req.get_header("Bearer")

      if (token != :undefined) and (:ejwt.parse_jwt(token, key)) do
        elli_ignore
      else
        {401, [], "Token incorrect"}
      end
    end

    post "/:action" do
      protect_by_token(req)
    end
    post "/:action/all" do
      protect_by_token(req)
    end
  end
end