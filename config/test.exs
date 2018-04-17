use Mix.Config
import_config "tcp_server.exs"

config :elredis,
  num_hosts: 1,
  host1: "nonode@nohost",
  accept_client_connections: System.get_env("ELREDIS_CLIENT_CONN") || "true"


