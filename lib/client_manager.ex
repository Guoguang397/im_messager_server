defmodule ClientManager do
  use GenServer

  def init(state \\ %{}), do: {:ok, state}

  def handle_call({:user_enter, chatroom_id, pid}, _from, state) do
    case Map.has_key?(state, chatroom_id) do
      true -> {:reply, GenServer.call(state[chatroom_id], {:user_enter, pid}), state}
      false ->
        {:ok, chatroom_pid} = DynamicSupervisor.start_child(ChatroomEntity.Supervisor, {ChatroomEntity, chatroom_id})
        GenServer.call(chatroom_pid, {:user_enter, pid})
        {:reply, :ok, Map.put(state, chatroom_id, chatroom_pid)}
    end
  end

  def handle_call({:user_leave, chatroom_id, pid}, _from, state) do
    case Map.has_key?(state, chatroom_id) do
      true -> {:reply, GenServer.call(state[chatroom_id], {:user_leave, pid}), state}
      false -> {:reply, :error, state}
    end
  end

  def handle_call({:broadcast_message, chatroom_id, message, self_only}, _from, state) do
    case Map.has_key?(state, chatroom_id) do
      true ->
        if !self_only do
          NodeManager.notify_nodes({:message, chatroom_id, message})
        end
        {:reply, GenServer.call(state[chatroom_id], {:broadcast_message, message}), state}
      false -> {:reply, :error, state}
    end
  end

  ### Client API
  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(_state) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end
  def user_enter(chatroom_id, pid), do: GenServer.call(__MODULE__, {:user_enter, chatroom_id, pid})
  def user_leave(chatroom_id, pid), do: GenServer.call(__MODULE__, {:user_leave, chatroom_id, pid})
  def broadcast_message(chatroom_id, message, self_only \\ false), do: GenServer.call(__MODULE__, {:broadcast_message, chatroom_id, message, self_only})
end
