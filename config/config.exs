import Config

config :im_homework,
  nodes: [:c1@localhost, :c2@localhost],
  ports: %{
    c1@localhost: 8001,
    c2@localhost: 8002
  }
