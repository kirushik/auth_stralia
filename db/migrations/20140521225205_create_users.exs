defmodule AuthStralia.Storage.DB.Migrations.CreateUsers do
  use Ecto.Migration

  def up do
    "CREATE TABLE users(user_id TEXT PRIMARY KEY, salt TEXT, password_hash TEXT)"
  end

  def down do
    "DROP TABLE IF EXISTS users CASCADE"
  end
end
