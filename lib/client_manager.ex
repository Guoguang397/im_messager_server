defmodule ClientManager do
  use GenServer

  def init(state \\ %{}), do: {:ok, state}

  def handle_call({:user_enter, chatroom_id, pid}, _from, state) do
    case Map.has_key?(state, chatroom_id) do
      true -> {:reply, :ok, Map.put(state, chatroom_id, state[chatroom_id] ++ [pid])}
      false -> {:reply, :ok, Map.put(state, chatroom_id, [pid])}
    end
  end

  def handle_call({:user_leave, chatroom_id, pid}, _from, state) do
    case Map.has_key?(state, chatroom_id) do
      true -> {:reply, :ok, Map.put(state, chatroom_id, state[chatroom_id] -- [pid])}
      false -> {:reply, :error, state}
    end
  end

  def handle_call({:user_leave, pid}, _from, state) do
    {:reply, :ok, get_map(Enum.map(state, fn({k, v}) -> {k, v -- pid} end), %{})}
  end

  def handle_call({:broadcast_message, chatroom_id, message}, _from, state) do
    for pid <- state[chatroom_id] do
      send(pid, {:text, Jason.encode!(message)})
    end
    {:reply, :ok, state}
  end

  defp get_map([{k, v}| tail], map), do: get_map(tail, Map.put(map, k, v))
  defp get_map([], map), do: map

  ### Client API
  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(_state) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end
  def user_enter(chatroom_id, pid), do: GenServer.call(__MODULE__, {:user_enter, chatroom_id, pid})
  def user_leave(chatroom_id, pid), do: GenServer.call(__MODULE__, {:user_leave, chatroom_id, pid})
  def user_leave(pid), do: GenServer.call(__MODULE__, {:user_leave, pid})
  def broadcast_message(chatroom_id, message), do: GenServer.call(__MODULE__, {:broadcast_message, chatroom_id, message})
end
