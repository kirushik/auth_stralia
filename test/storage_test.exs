defmodule StorageTest do
  use Amrita.Sweet

  alias AuthStralia.Storage.DB, as: DB
  alias AuthStralia.Storage.User, as: User

  defp user_id, do: "bob@example.com"

  setup do
    DB.delete_all User
    :ok
  end

  describe "User model" do
    it "can be saved and restored" do
      DB.insert User.new(user_id: user_id)

      u = User.find_by_uid(user_id)
      user_id |> u.user_id # Because fails when function is on the right side
    end

    it "fails to overwrite user with same uid" do
      User.create(user_id)

      # Workaround for failing `rescues` matcher
      try do
        User.create(user_id)
      rescue
        Postgrex.Error -> :gotcha
      end |> :gotcha
    end

    it "generates salt automagically" do
      User.create(user_id)
      u = User.find_by_uid(user_id)
      u.salt |> truthy
    end

    it "saves password as a hash" do
    end

    it "can check the password" do
    end
  end
end