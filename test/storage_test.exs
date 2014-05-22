defmodule StorageTest do
  use Amrita.Sweet

  alias AuthStralia.Storage.DB, as: DB
  alias AuthStralia.Storage.User, as: User
  alias AuthStralia.Storage.Tag, as: Tag

  defp user_id, do: "bob@example.com"
  defp password, do: "qwerty123"

  setup do
    DB.delete_all AuthStralia.Storage.TagToUserMapping
    DB.delete_all User
    DB.delete_all Tag
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
      User.create(user_id, password)
      u = User.find_by_uid(user_id)
      u.password_hash |> truthy
      u.password_hash |> ! password
    end

    it "can check the password" do
      User.create(user_id, password)
      User.check_password(user_id, "qweqweqwe") |> falsey
      User.check_password(user_id, password) |> truthy
    end
  end

  describe "Tags model" do
    it "is an array on User model" do
      User.create(user_id, password, [])
      u = User.find_by_uid(user_id)
      User.tags(u) |> []
    end

    it "can be created" do
      Tag.create("aaa")
    end

    it "can be listed" do
      Tag.create("bbb")
      Tag.create("ccc")

      tags = DB.all Tag
      length(tags) |> 2
    end

    it "stores only unique tags" do
      Tag.create("aaa")
      try do
        Tag.create("aaa")
      rescue
        Postgrex.Error -> :gotcha
      end |> :gotcha
    end
  end

  describe "Tags and Users relations" do
    it "stores tag for user" do
      tag = Tag.create("aaa")
      User.create(user_id, password, [tag])
      u = User.find_by_uid(user_id)
      User.tags(u) |> [tag]
    end

    it "stores multiple tags for user" do
      tag1 = Tag.create("aaa")
      tag2 = Tag.create("bbb")
      User.create(user_id, password, [tag1, tag2])
      u = User.find_by_uid(user_id)
      User.tags(u) |> [tag1, tag2]
    end
  end
end