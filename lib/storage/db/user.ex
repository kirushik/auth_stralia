defmodule AuthStralia.Storage.User do
  use Ecto.Model
  alias AuthStralia.Storage.DB, as: DB

  queryable "users", primary_key: { :user_id, :string, [] } do
    #TODO Validations
    field :salt
    field :password_hash
    has_many :tag_to_user_mappings, AuthStralia.Storage.TagToUserMapping, [foreign_key: :user_id]
  end

  #TODO We could do better than defaulting to empty passwords
  def create(user_id, password \\ "", tags \\ []) do
    salt = generate_salt
    hash = hash_password(password, salt)
    DB.insert new(user_id: user_id, salt: salt, password_hash: hash)
  end

  def find_by_uid(uid) do
    query = from u in AuthStralia.Storage.User, where: u.user_id==^uid , preload: [:tag_to_user_mappings]
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

  def tags(user) do
    user.tag_to_user_mappings.to_list
  end

  defp hash_password(password, salt) do
    {:ok, raw} = :pbkdf2.pbkdf2(:sha, password, salt, 4096, 32)
    :pbkdf2.to_hex(raw)
  end
  defp generate_salt, do: :crypto.rand_bytes(16) |> :base64.encode_to_string |> to_string
end