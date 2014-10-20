defmodule AuthStralia.Storage do  
  defmodule Tag do
    use Ecto.Model
    alias AuthStralia.Storage.DB, as: DB

    schema "tags", primary_key: {:title, :string, []} do
      has_many :tag_to_user_mappings, TagToUserMapping, [foreign_key: :tag_id]
    end

    def create(title) do
      DB.insert %Tag{title: title}
    end
  end

  defmodule TagToUserMapping do
    use Ecto.Model

    schema "tag_to_user_mappings", primary_key: false do
      belongs_to :tag, Tag, [references: :title, type: :string]
      belongs_to :user, User, [references: :user_id, type: :string]
    end
  end
end