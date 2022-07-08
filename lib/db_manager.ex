defmodule DbManager do
  use GenServer
  @moduledoc """
  Database Manager.
  """

  @doc """
  GenServer.init/1 callback
  """
  def init(state) do
    {:ok, db} = Mongo.start_link(url: "mongodb://127.0.0.1:27017/imdb")
    {:ok, %{db: db, state_list: state}}
  end

  def handle_call({:get_history, chatroom_id}, _from, state) do
    result = Mongo.find_one(state.db, "chatrooms", %{_id: chatroom_id}, [projection: %{messages: 1}, limit: 100])
    {:reply, result, state}
  end

  def handle_call({:add_message, chatroom_id, message_data}, _from, state) do
    result = Mongo.find_one_and_update(state.db, "chatrooms", %{_id: chatroom_id}, %{"$push": %{messages: message_data}})
    {:reply, result, state}
  end

  def handle_call({:add_chatroom, chatroom_data}, _from, state) do
    {:ok, num} = Mongo.count_documents(state.db, "chatrooms", %{})
    data = Map.merge(chatroom_data, %{
      _id: num + 1,
      status: "CREATED",
      delete_time: nil,
      messages: []
    })
    case Mongo.insert_one(state.db, "chatrooms", data) do
      {:ok, _} -> {:reply, {:ok, data}, state}
      _ -> :error
    end

  end

  def handle_call({:chatroom_exists, chatroom_id}, _from, state) do
    result = Mongo.find_one(state.db, "chatrooms", %{_id: chatroom_id})
    {:reply, result != nil && result["status"] == "CREATED", state}
  end

  def handle_call({:del_chatroom, chatroom_id}, _from, state) do
    case Mongo.update_one(state.db, "chatrooms", %{_id: chatroom_id}, %{"$set": %{status: "DELETED", delete_time: DateTime.to_unix(DateTime.utc_now)}}) do
      {:ok, %{modified_count: 1}} -> {:reply, :ok, state}
      {:ok, %{modified_count: 0}} -> {:reply, :error, state}
      _ -> {:reply, :error, state}
    end
  end

  def handle_call({:get_my_chatrooms, username}, _from, state) do
    result = Mongo.find(
      state.db,
      "chatrooms",
      %{manager: username, status: "CREATED"},
      [projection: %{create_time: 1}]
    )
    {:reply, result, state}
  end

  def handle_call({:user_login, user_credentials}, _from, state) do
    case Mongo.find_one(state.db, "users", %{"username" => user_credentials["username"]}) do
      nil ->
        {:ok, num} = Mongo.count_documents(state.db, "chatrooms", %{})
        Mongo.insert_one!(state.db, "users", %{
          _id: num + 1,
          username: user_credentials["username"],
          password: user_credentials["password"],
          reg_time: DateTime.to_unix(DateTime.utc_now),
          chatrooms: []
        })
        {:reply, :ok, state}
      %{"password" => password} ->
        case password == user_credentials["password"] do
          true -> {:reply, :ok, state}
          false -> {:reply, :error_invalid_password, state}
        end
      _ -> {:reply, :error_db_error, state}
    end
  end

  ### Client API

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(state \\ %{}) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def get_history(chatroom_id), do: GenServer.call(__MODULE__, {:get_history, chatroom_id})

  def add_message(chatroom_id, message_data = %{
    sender: _,
    send_time: _,
    message: _
  }), do: GenServer.call(__MODULE__, {:add_message, chatroom_id, message_data})
  def add_message(_), do: :error

  def add_chatroom(chatroom_data = %{
    manager: _,
    create_time: _,
  }), do: GenServer.call(__MODULE__, {:add_chatroom, chatroom_data})

  def add_chatroom(_), do: :error

  def del_chatroom(chatroom_id), do: GenServer.call(__MODULE__, {:del_chatroom, chatroom_id})

  def user_login(user_credentials), do: GenServer.call(__MODULE__, {:user_login, user_credentials})

  def get_my_chatrooms(username), do: GenServer.call(__MODULE__, {:get_my_chatrooms, username})

  def chatroom_exists?(chatroom_id), do: GenServer.call(__MODULE__, {:chatroom_exists, chatroom_id})
end
