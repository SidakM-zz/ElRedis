defmodule ElRedis.Supervisor do
  @moduledoc """
  The main supervisor for the application. Will start necessary workers and supervisors
  """
  use Supervisor
  require Logger

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    Logger.info("Starting ELRedis Supervisor")

    children = [
      {ElRedis.TcpServer, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
