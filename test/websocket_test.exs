defmodule WebsocketTest do
  use ExUnit.Case
  use WebSockex

  def handle_connect(_conn, state) do
    send(state, :connected)
    {:ok, state}
  end

  def handle_frame({:text, msg}, state) do
    msg_json = Jason.decode!(Jason.decode!(msg))
    arr = msg_json["messages"] |> Enum.at(0)
    arr = Map.put(arr, "send_time", "time")
    send(state, {:message, Map.put(msg_json, "messages", arr)})
    {:ok, state}
  end

  def handle_disconnect(%{reason: {:local, _reason}}, state) do
    send(state, :disconnected)
    {:ok, state}
  end

  test "websocket_test" do
    {:ok, conn} = WebSockex.start_link("ws://127.0.0.1:8080/ws?chatroom_id=2&username=Guoguang", __MODULE__, self())
    assert_receive :connected
    WebSockex.send_frame(conn, {:text, Jason.encode!(%{
      message: "Hello"
    })})
    assert_receive {:message, %{"code" => 200, "messages" => %{"message" => "Hello", "send_time" => "time", "sender" => "Guoguang"}, "msg" => "新消息"}}
  end
end
