defmodule AuthStralia.Storage.DB.Migrations.CreateUsers do
  use Ecto.Migration

  def up do
    "CREATE TABLE users(id SERIAL PRIMARY KEY, user_id TEXT UNIQUE, salt TEXT, password_hash TEXT)"
  end

  def down do
    "DROP TABLE IF EXISTS users CASCADE"
  end
end
