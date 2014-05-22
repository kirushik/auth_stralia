defmodule StorageTest do
  use Amrita.Sweet

  alias AuthStralia.Storage.DB, as: DB
  alias AuthStralia.Storage.User, as: User

  setup do
    DB.delete_all User
    :ok
  end

  describe "User model" do
    it "can be saved and restored" do
      user_id = "aaa"
      DB.insert User.new(user_id: user_id)

      u = User.find_by_uid(user_id)
      u.user_id |> user_id
    end

    it "fails to overwrite user with same uid" do
    end

    it "generates salt automagically" do
    end

    it "saves password as a hash" do
    end

    it "can check the password" do
    end
  end
end