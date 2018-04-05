use Mix.Config

config :elredis,
  port: 6379,
  max_connections: 512,
  connection_backlog: 1024
