defmodule ElRedis.TcpServer do
  @moduledoc """
  The TCP Server for the application
  """
  use GenServer
  alias ElRedis.Handler

  @doc """
  Starts the TCPServer
  """
  def start_link(_args) do
    GenServer.start_link(__MODULE__, name: __MODULE__)
  end

  @doc """
  Uses ranch which creates a pool of actors which will accept incoming connections
  and spawn ElRedis.Handler [Protocol] to handle these connections
  """
  def init(_args) do
    port = Application.get_env(:elredis, :port)
    max_connections = Application.get_env(:elredis, :max_connections)
    connection_backlog = Application.get_env(:elredis, :connection_backlog)
    args = [{:port, port}, {:max_connections, max_connections}, {:backlog, connection_backlog}]
    {:ok, pid} = :ranch.start_listener(:ElRedis, :ranch_tcp, args, Handler, [])
  end
end
