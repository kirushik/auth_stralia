defmodule AuthStralia.Storage.User do
  use Ecto.Model

  queryable "user" do
    field :user_id
    
    field :salt
    field :password_hash
  end
end