# defmodule AuthStralia.API.V1 do
#   defmodule Handler do
#     alias AuthStralia.Redis.Session, as: Session
#     alias AuthStralia.Storage.User, as: User
#     alias Settings, as: S

#     post "/login" do
#       uid = req.post_arg("user_id")
#       session_id = UUID.generate

#       # IO.inspect req
      
#       if (!User.check_password(uid,req.post_arg("password"))) do
#         {401, [], "Authorization failed"}
#       else
#         data = [ sub: uid,
#         #TODO We should introduce hostname setting here
#                  iss: "auth.example.com",
#                  jti: session_id,
#                  tags: User.tags(uid) ]

#         Session.new(uid, session_id)

#         http_ok Token.compose(data)
#       end
#     end

#     get "/verify_token", with_params token do
#       res = case Token.parse(token) do
#         :invalid -> "0"
#         parsed when is_list(parsed) -> 
#           Session.check(Token.get(parsed, "sub"), Token.get(parsed, "jti"))
#         _ -> "0"
#       end
#       http_ok res
#     end

#     post "/session/invalidate" do
#       token = req.get_header("Bearer")

#       sub = Token.extract(token, "sub")
#       jti = req.post_arg("jti")
#       if jti==:undefined do
#         jti = Token.extract(token, "jti")
#       end
#       http_ok Session.remove(sub, jti)
#     end

#     post "/session/invalidate/all" do
#       token = req.get_header("Bearer")
#       sub = Token.extract(token, "sub")
#       http_ok Session.remove_all(sub)
#     end

#     get "/session/list" do
#       token = req.get_header("Bearer")
#       sub = Token.extract(token, "sub")
#       http_ok JSON.encode!(Session.list(sub))
#     end

#     post "/session/update" do
#       token = req.get_header("Bearer")
#       http_ok Token.update_expiration_time(token)
#     end
#   end

#   defmodule ProtectByBearer do
#     # Handle every request — typical 'post' macro is not useful
#     def handle(:POST, _path, req) do
#       token = req.get_header("Bearer")

#       if (token != :undefined) and (Token.parse(token)) do
#         elli_ignore
#       else
#         {401, [], "Token incorrect"}
#       end
#     end
#   end
# end