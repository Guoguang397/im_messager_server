defmodule WebsocketHandler do
  defmodule PeerInfo do
    defstruct username: nil,
              chatroom_id: nil,
              pid: nil
  end

  def get_peer_info(_, map \\ %PeerInfo{})
  def get_peer_info([[k, v]| tail], map), do: get_peer_info(tail, Map.put(map, String.to_atom(k), v))
  def get_peer_info([], map), do: map
  def init(req, _state) do
    peer_info =
      String.split(req.qs, "&")
      |> Enum.map(fn s -> String.split(s, "=") end)
      |> get_peer_info()
      |> Map.to_list()
    chatroom_id = case Integer.parse(peer_info[:chatroom_id]) do
      {chatroom_id, _} -> chatroom_id
      :error -> nil
    end
    state = struct(PeerInfo, peer_info)
      |> Map.put(:chatroom_id, chatroom_id)
      |> Map.put(:pid, req.pid)
    case state do
      %PeerInfo{chatroom_id: nil} -> {:ok, req, state}
      %PeerInfo{username: nil} -> {:ok, req, state}
      _ -> if DbManager.chatroom_exists?(state.chatroom_id) do
        ClientManager.user_enter(state.chatroom_id, req.pid)
        {:cowboy_websocket, req, state, %{idle_timeout: 60*60*1000}}
      else
        {:ok, req, state}
      end
    end
  end

  def websocket_init(state) do
    {:ok, state}
  end

  def websocket_handle({:text, message}, state) do
    with {:ok, json} <- Jason.decode(message) do
      websocket_handle({:json, json}, state)
    else
      _ -> {:stop, "Invalid argument.", state}
    end
  end

  def websocket_handle({:json, msg}, state) do
    msg = %{
      sender: state.username,
      send_time: DateTime.to_unix(DateTime.utc_now),
      message: msg["message"]
    }
    DbManager.add_message(state.chatroom_id, msg)
    message = %{
      code: 200,
      msg: "新消息",
      messages: [msg]
    }
    ClientManager.broadcast_message(state.chatroom_id, Jason.encode!(message))
    {:ok, state}
  end

  def websocket_info(info={:text, _msg}, state) do
    {:reply, info, state}
  end

  def terminate(_reason, _req, state) do
    ClientManager.user_leave(state.chatroom_id, state.pid)
    :ok
  end
end
