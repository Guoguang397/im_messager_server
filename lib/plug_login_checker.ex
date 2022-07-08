defmodule PlugLoginChecker do
  use Plug.Builder

  def init(options), do: options

  def call(%Plug.Conn{request_path: path} = conn, opts) do
    if path in opts[:paths] do
      check_login(conn)
    else
      conn
    end
  end

  defp check_login(conn) do
    username = Plug.Conn.get_session(conn, "username")
    password = Plug.Conn.get_session(conn, "password")
    if username == nil || password == nil do
      conn = Plug.Conn.resp(conn, 403, Jason.encode!(%{
        code: 403,
        msg: "请先登录"
      }))
      Plug.Conn.halt(conn)
    else
      conn
    end
  end
end
