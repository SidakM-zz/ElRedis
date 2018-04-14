use Mix.Config

config :elredis,
  port: 6379,
  max_connections: 512,
  connection_backlog: 1024,
  accept_client_connections: System.get_env("ELREDIS_CLIENT_CONN") || true

