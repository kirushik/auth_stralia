defmodule AuthStralia.Storage.DB do
  use Ecto.Repo, adapter: Ecto.Adapters.Postgres

  def conf do
    parse_url Settings.db_url
  end

  def priv do
    app_dir(:auth_stralia, "db")
  end
end