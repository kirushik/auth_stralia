defmodule AuthStralia.Storage.DB.Migrations.CreateTags do
  use Ecto.Migration

  def up do
    [
      "CREATE TABLE tags(title TEXT PRIMARY KEY)",
      "CREATE TABLE tag_to_user_mappings(
        tag_id TEXT REFERENCES tags,
        user_id TEXT REFERENCES users
        )",
      # If one is cautious, this can be optimised to a multi-column index
      "CREATE INDEX ON tag_to_user_mappings (tag_id)",
      "CREATE INDEX ON tag_to_user_mappings (user_id)"
    ]
  end

  def down do
    [
      "DROP TABLE IF EXISTS tag_to_user_mappings",
      "DROP TABLE IF EXISTS tags"
    ]
  end
end
