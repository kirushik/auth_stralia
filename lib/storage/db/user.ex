defmodule AuthStralia.Storage.User do
  use Ecto.Model
  alias AuthStralia.Storage.DB, as: DB

  queryable "users", primary_key: { :user_id, :string, [] } do
    #TODO Validations and defaults
    field :salt
    field :password_hash
  end

  def find_by_uid(uid) do
    query = from u in AuthStralia.Storage.User, where: u.user_id==^uid
    case DB.all(query) do
      [user] -> user
      [] -> nil
    end
  end
  
  def check_password(user_id, password) do
    user = find_by_uid(user_id)
    #TODO Crypto string comparison
    user.password_hash == hash_password(password, user.salt)
  end

  defp hash_password(password, salt) do
    {:ok, raw} = :pbkdf2.pbkdf2(:sha, password, salt, 4096, 32)
    :pbkdf2.to_hex(raw)
  end
end