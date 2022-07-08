defmodule RouterTest do
  use ExUnit.Case
  use Plug.Test

  setup_all do
    {:ok, db} = Mongo.start_link(url: "mongodb://127.0.0.1:27017/imdb")
    on_exit(fn ->
      Mongo.delete_one(db, "users", %{username: "test_user_router"})
      Mongo.delete_many(db, "chatrooms", %{manager: "test_user_router"})
    end)
  end

  test "test_404" do
    resp = conn(:get, "/aosiudhiuyduguay7ufyaw")
    |> PlugRouter.call([])
    assert resp.resp_body == "{\"code\":404,\"msg\":\"API not found.\"}"
  end

  test "test_functions" do
    resp = conn(:post, "/user/login")
    |> put_req_header("content-type", "application/json")
    |> Map.put(:body_params, %{
      "username" => "test_user_router",
      "password" => "123123"
    })
    |> PlugRouter.call([])
    assert resp.resp_body == "{\"code\":200,\"msg\":\"登录成功\"}"

    resp = conn(:post, "/user/login")
    |> put_req_header("content-type", "application/json")
    |> Map.put(:body_params, %{
      "username" => "test_user_router",
      "password" => "******"
    })
    |> PlugRouter.call([])
    assert resp.resp_body == "{\"code\":403,\"msg\":\"用户名或密码不正确\"}"

    resp = conn(:post, "/user/login")
    |> put_req_header("content-type", "application/json")
    |> Map.put(:body_params, %{
      "username" => "test_user_router",
      "password" => "123123"
    })
    |> PlugRouter.call([])
    assert resp.resp_body == "{\"code\":200,\"msg\":\"登录成功\"}"
    cookies = resp.resp_cookies

    resp = conn(:post, "/chatroom/create")
    |> put_req_header("content-type", "application/json")
    |> PlugRouter.call([])
    assert resp.resp_body == "{\"code\":403,\"msg\":\"请先登录\"}"

    resp = conn(:post, "/chatroom/create")
    |> put_req_header("content-type", "application/json")
    |> put_req_cookie("e_session", cookies["e_session"][:value])
    |> PlugRouter.call([])
    fields = ["chatroom_id", "code", "create_time", "msg"]
    assert Enum.all?(Jason.decode!(resp.resp_body) |> Map.keys(), fn i->i in fields end)
    chatroom_id = Jason.decode!(resp.resp_body)["chatroom_id"]

    resp = conn(:post, "/chatroom/delete")
    |> put_req_header("content-type", "application/json")
    |> put_req_cookie("e_session", cookies["e_session"][:value])
    |> Map.put(:body_params, %{
      "chatroom_id" => chatroom_id
    })
    |> PlugRouter.call([])
    assert resp.resp_body == "{\"code\":200,\"msg\":\"删除成功\"}"

    resp = conn(:get, "/chatroom/my")
    |> put_req_header("content-type", "application/json")
    |> put_req_cookie("e_session", cookies["e_session"][:value])
    |> PlugRouter.call([])
    fields = resp.resp_body |> Jason.decode! |> Map.keys
    assert Enum.all?(["code", "msg", "chatrooms"], fn i->i in fields end)

    resp = conn(:get, "/chatroom/history?chatroom_id=#{chatroom_id}")
    |> PlugRouter.call([])
    fields = Jason.decode!(resp.resp_body) |> Map.keys()
    assert Enum.all?(["code", "msg", "messages"], fn i->i in fields end)
  end
end
