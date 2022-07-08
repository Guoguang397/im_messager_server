defmodule ChatroomEntity do
  use GenServer

  defmodule Chatroom do
    defstruct id: 1,
              manager: "Guoguang",
              create_time: 1657180805,
              delete_time: nil,
              status: "CREATED"
    end

  def init(state \\ []) do
    {:ok, %{
      chatroom_info: %Chatroom{},
      chatroom_member: state
    }}
  end

  def handle_call({:chatroom_init, chatroom_id}, _from, state) do
    case DbManager.get_chatroom_info(chatroom_id) do
      nil -> {:stop, :error_no_chatroom, state}
      result ->
        chatroom_info = result
          |> Map.to_list()
          |> Enum.map(fn {k,v} -> {String.to_atom(k), v} end)
        {:reply, :ok, Map.put(state, :chatroom_info, struct(Chatroom, chatroom_info))}
    end
  end

  def handle_call({:user_enter, pid}, _from, state) do
    {:reply, :ok, Map.put(state, :chatroom_member, state[:chatroom_member] ++ [pid])}
  end

  def handle_call({:user_leave, pid}, _from, state) do
    {:reply, :ok, Map.put(state, :chatroom_member, state[:chatroom_member] -- [pid])}
  end

  def handle_call({:broadcast_message, message}, _from, state) do
    for pid <- state[:chatroom_member] do
      send(pid, {:text, message})
    end
    {:reply, :ok, state}
  end

  def start_link(state) do
    GenServer.start_link(__MODULE__, [], name: String.to_atom("Chatroom #{state}"))
  end

  # ### Client API
  # def chatroom_init(chatroom_id), do: GenServer.call(__MODULE__, {:chatroom_init, chatroom_id})
  # def user_enter(pid), do: GenServer.call(__MODULE__, {:user_enter, pid})
  # def user_leave(pid), do: GenServer.call(__MODULE__, {:user_leave, pid})
end
