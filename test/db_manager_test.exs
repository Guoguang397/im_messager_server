defmodule DbManagerTest do

  use ExUnit.Case
  doctest DbManager

  setup_all do
    {:ok, db} = Mongo.start_link(url: "mongodb://127.0.0.1:27017/imdb")
    on_exit(fn ->
      Mongo.delete_one(db, "users", %{username: "test_user"})
      Mongo.delete_many(db, "chatrooms", %{manager: "test_user"})
    end)
  end


  test "user_login" do
    assert DbManager.user_login(%{
      "username" => "test_user",
      "password" => "123456"
    }) == :ok
    assert DbManager.user_login(%{
      "username" => "test_user",
      "password" => "******"
    }) == :error_invalid_password
    assert DbManager.user_login(%{
      "username" => "test_user",
      "password" => "123456"
    }) == :ok
  end

  test "chatroom" do
    {:ok, result} = DbManager.add_chatroom(%{
      manager: "test_user",
      create_time: DateTime.utc_now |> DateTime.to_unix
    })
    chatroom_id = result[:_id]
    assert is_integer(chatroom_id)
    assert DbManager.chatroom_exists?(chatroom_id)

    message = %{
      sender: "test_user",
      send_time: DateTime.utc_now |> DateTime.to_unix,
      message: "test_message"
    }

    db_message = DbManager.get_history(chatroom_id)["messages"]
    assert is_list(db_message)
    assert length(db_message) == 0
    {:ok, _} = DbManager.add_message(chatroom_id, message)
    db_message = DbManager.get_history(chatroom_id)["messages"]
    assert is_list(db_message)
    assert length(db_message) == 1

    assert DbManager.del_chatroom(chatroom_id) == :ok
    refute DbManager.chatroom_exists?(chatroom_id)
  end
end
