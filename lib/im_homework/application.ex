defmodule ImHomework.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      DbManager,
      ClientManager,
      {Plug.Cowboy, scheme: :http, plug: PlugRouter, options: [
        dispatch: dispatch(),
        port: 8080
      ]}
      # Starts a worker by calling: ImHomework.Worker.start_link(arg)
      # {ImHomework.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ImHomework.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp dispatch do
    [
      {:_, [
        {"/ws", WebsocketHandler, []},
        {:_, Plug.Cowboy.Handler, {PlugRouter, []}}
      ]}
    ]
  end
end
