defmodule PlugRouter do
  use Plug.Router
  use Plug.ErrorHandler

  plug :match
  plug CORSPlug, origin: "http://127.0.0.1:3000"
  plug Plug.Session,
    store: :cookie,
    key: "e_session",
    signing_salt: "hFaY7T3hM",
    secret_key_base: "a6Hus7HTuhs8d5HtISNd2g6sRj95HDtewWT63HkTYYra1aKBvuh5ej75Vg83khfv",
    same_site: "lax"
  plug :fetch_session
  plug PlugLoginChecker,
    paths: [
      "/chatroom/my",
      "/chatroom/delete",
      "/chatroom/create"
    ]
  plug Plug.Parsers,
    parsers: [:urlencoded, :json],
    pass: ["text/*"],
    json_decoder: Jason
  plug :dispatch

  post "/user/login" do
    result = conn.body_params
    |> Map.put("password", Base.encode64(:crypto.hash(:md5, conn.body_params["password"])))
    |> DbManager.user_login()
    case result do
      :ok ->
        conn = put_session(conn, "username", conn.body_params["username"])
        conn = put_session(conn, "password", conn.body_params["password"])
        send_resp(conn, 200, Jason.encode!(%{
          code: 200,
          msg: "登录成功"
        }))
      :error_invalid_password -> send_resp(conn, 200, Jason.encode!(%{
          code: 403,
          msg: "用户名或密码不正确"
        }))
    end
  end

  post "/chatroom/create" do
    username = get_session(conn, "username")
    {:ok, result} = DbManager.add_chatroom(%{
      manager: username,
      create_time: DateTime.to_unix(DateTime.utc_now)
    })
    send_resp(conn, 200, Jason.encode!(%{
      code: 200,
      msg: "创建成功",
      chatroom_id: result[:_id],
      create_time: result[:create_time]
    }))
  end

  post "/chatroom/delete" do
    chatroom_id = conn.body_params["chatroom_id"]
    if chatroom_id == nil, do: raise "No chatroom_id specified."
    if DbManager.del_chatroom(chatroom_id) == :ok do
      send_resp(conn, 200, Jason.encode!(%{
        code: 200,
        msg: "删除成功"
      }))
    else
      send_resp(conn, 400, Jason.encode!(%{
        code: 400,
        msg: "聊天室不存在"
      }))
    end
  end

  get "chatroom/history" do
    {chatroom_id, _} =
      conn.query_params["chatroom_id"]
      |> Integer.parse()
    result = DbManager.get_history(chatroom_id)
    send_resp(conn, 200, Jason.encode!(%{
      code: 200,
      msg: "查询成功",
      messages: result["messages"]
    }))
  end

  get "chatroom/my" do
    username = get_session(conn, "username")
    %{docs: docs} = DbManager.get_my_chatrooms(username)
    send_resp(conn, 200, Jason.encode!(%{
      code: 200,
      msg: "查询成功",
      chatrooms: docs
    }))
  end

  get "/observer" do
    case :observer.start() do
      :ok -> send_resp(conn, 200, Jason.encode!(%{
        code: 200,
        msg: "ok."
      }))
      {:error, _} -> send_resp(conn, 400, Jason.encode!(%{
        code: 400,
        msg: "Observer already started."
      }))
    end
  end

  match _ do
    send_resp(conn, 404, Jason.encode!(%{
      code: 404,
      msg: "API not found."
    }))
  end

  defp handle_errors(conn, %{kind: _kind, reason: _reason, stack: _stack}) do
    {:ok, resp} = Jason.encode(%{"code" => 400, "msg" => "Bad Request."})
    send_resp(conn, 400, resp)
  end
end
