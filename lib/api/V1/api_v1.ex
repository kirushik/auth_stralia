defmodule AuthStralia.API.V1 do
  defmodule Handler do
    use Elli.Handler

    alias AuthStralia.Redis.Session, as: Session
    alias Settings, as: S

    #TODO: Extract all token operations in separate module
    post "/login" do
      uid = req.post_arg("user_id")
      session_id = generate_uuid()

      if (!check_credentials(uid,req.post_arg("password"))) do
        {401, [], "Authorization failed"}
      else
        data = { sub: uid,
                 iss: "auth.example.com",
                 jti: session_id }

        Session.new(uid, session_id)

        http_ok :ejwt.jwt("HS256",data, S.expiresIn, S.jwt_secret)
      end
    end

    get "/verify_token", with_params token do
      res = case :ejwt.parse_jwt(token, S.jwt_secret) do
        { [value|_] } when is_tuple(value) -> Session.check(get_token_field(token, "sub"), get_token_field(token, "jti"))
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
      http_ok Session.remove(sub, jti)
    end

    post "/session/invalidate/all" do
      token = req.get_header("Bearer")
      sub = get_token_field(token, "sub")
      http_ok Session.remove_all(sub)
    end

    get "/session/list" do
      token = req.get_header("Bearer")
      sub = get_token_field(token, "sub")
      http_ok JSON.encode!(Session.list(sub))
    end

    post "/session/update" do
      token = req.get_header("Bearer")
      http_ok set_expiration_time(token, S.expiresIn)
    end

###################################################################################################
## PRIVATE
###################################################################################################

    #TODO: Here goes our database stuff
    defp check_credentials(user_id, password) do
      ("alice@example.com" == user_id) and ("Correct password" == password)
    end

    defp get_token_field(token, name) do
      {parsed_token} = :ejwt.parse_jwt(token, S.jwt_secret)
      :proplists.get_value(name, parsed_token)
    end

    defp generate_uuid do
      list_to_bitstring( :uuid.to_string(:uuid.uuid4()))
    end

    defp set_expiration_time(token, new_timeout) do
      {parsed_token} = :ejwt.parse_jwt(token, S.jwt_secret)
      contents = :lists.map(
        fn({a,b})->
          {binary_to_atom(a),b }; 
        end, parsed_token)
      contents = {:proplists.delete(:exp, contents)}
      :ejwt.jwt("HS256",contents, new_timeout, S.jwt_secret)
    end
  end

  defmodule TokenValidator do
    use Elli.Handler

    alias Settings, as: S

    defp protect_by_token(req) do
      token = req.get_header("Bearer")

      if (token != :undefined) and (:ejwt.parse_jwt(token, S.jwt_secret)) do
        elli_ignore
      else
        {401, [], "Token incorrect"}
      end
    end

    # Handle every request — typical 'post' macro is not useful
    def handle(:POST, _path, req) do
      protect_by_token(req)
    end
  end
end