defmodule AuthStralia.Storage.User do
  use Ecto.Model
  alias AuthStralia.Storage.DB, as: DB
  alias AuthStralia.Storage.TagToUserMapping, as: TTUM

  schema "users", primary_key: { :user_id, :string, [] } do
    #TODO Validations
    field :salt
    field :password_hash
    field :verified, :boolean
    has_many :tag_to_user_mappings, AuthStralia.Storage.TagToUserMapping, [foreign_key: :user_id]
  end


  #TODO We could do better than defaulting to empty passwords
  def create(user_id, password \\ "", tags \\ []) do
    salt = generate_salt
    hash = hash_password(password, salt)
    user = DB.insert %AuthStralia.Storage.User{user_id: user_id, salt: salt, password_hash: hash}
    Enum.map(tags,
      fn(tag) ->
        DB.insert %TTUM{tag_id: tag.title, user_id: user_id}
      end)
    user
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
    if user==nil do
      false
    else
      hash = hash_password(password, user.salt)
      #TODO Crypto string comparison
      match?( %AuthStralia.Storage.User{password_hash: ^hash, verified: true}, user)
    end
  end

  def tags(user_id) when is_bitstring(user_id) do
    DB.all(from ttum in TTUM, where: ttum.user_id==^user_id) |> Enum.map &(&1.tag_id)
  end
  def tags(user) do
    user.tag_to_user_mappings.all |> Enum.map &(&1.tag_id)
  end

  def verify(user) do
    user = %{user | verified: true}
    DB.update user
  end

  defp hash_password(password, salt) do
    {:ok, raw} = :pbkdf2.pbkdf2(:sha, password, salt, 4096, 32)
    :pbkdf2.to_hex(raw)
  end
  defp generate_salt, do: :crypto.rand_bytes(16) |> :base64.encode_to_string |> to_string
end
