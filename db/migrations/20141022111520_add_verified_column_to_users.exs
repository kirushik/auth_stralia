defmodule AuthStralia.Storage.DB.Migrations.AddVerifiedColumnToUsers do
  use Ecto.Migration

  def up do
    [
      "ALTER TABLE users ADD COLUMN verified boolean NOT NULL DEFAULT false"
    ]
  end

  def down do
    "ALTER TABLE users DROP COLUMN verified"
  end
end
