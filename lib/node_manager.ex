defmodule NodeManager do
  def notify_nodes(data) do
    nodes = Application.get_env(:im_homework, :nodes, [])
    for node <- nodes do
      if node != Node.self() && Node.ping(node) == :pong do
        Node.spawn_link(node, fn -> NodeManager.message_received(data) end)
      end
    end
  end

  def message_received(data) do
    case data do
      {:message, chatroom_id, message} ->
        ClientManager.broadcast_message(chatroom_id, message, true)
        :ok
      _ ->
        :error
    end
  end
end
