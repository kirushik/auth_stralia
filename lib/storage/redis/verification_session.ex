defmodule AuthStralia.Redis.VerificationSession do
  use Exredis

  alias Settings, as: S

  # Key format is 'verification_session:user_id'
  # Value format is session_id of verification session

  def get(user_id) do
    key = "verification_session:#{user_id}"
    redis = start

    session_id =  if redis |> query ["EXISTS", key] do
                    redis |> query ["GET", key]
                  else
                    UUID.generate
                  end
    redis |> query ["SETEX", key, S.expiresIn, session_id]
  end
  def check(user_id, session_id) do
    key = "verification_session:#{user_id}"
    value = start |> query ["GET", key]
    value == session_id
  end
  def get_ttl(user_id) do
    key = "verification_session:#{user_id}"
    start |> query ["TTL", key]
  end
  def delete(user_id) do
    key = "verification_session:#{user_id}"
    start |> query ["DEL", key]
  end

end
