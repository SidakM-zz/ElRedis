defmodule ElRedis.Supervisor do
  @moduledoc """
  The main supervisor for the application. Will start necessary workers and supervisors
  """
  use Supervisor
  require Logger

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc """
  Assembles the children to be started. 
  1) TCP Server: If enabled in config
  2) KeySpaceSupervisor: DynamicSupervisor that supervises K/V nodes
  3) Registry: Used as the named registry for the K/V pairs
  """
  def init(:ok) do
    Logger.info("Starting ELRedis Supervisor")

    children = [
      supervisor(ElRedis.KeySpaceSupervisor, []),
      supervisor(Registry, [:unique, :key_registry])
    ]

    # start tcp server if indicated in the configuration
    if (Application.get_env(:elredis, :accept_client_connections)) do
      children = children ++ [{ElRedis.TcpServer, []}]
    end

    Supervisor.init(children, strategy: :one_for_one)
  end
end
