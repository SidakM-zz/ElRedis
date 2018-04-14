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
  1) KeySpaceSupervisor: DynamicSupervisor that supervises K/V nodes
  2) Registry: Used as the named registry for the K/V pairs
  3) NodeDiscovery: Attempts to check and connect to other nodes in the cluster
  4) TCP Server: If enabled in config
  """
  def init(:ok) do
    Logger.info("Starting ELRedis Supervisor")

    children = [
      supervisor(ElRedis.KeySpaceSupervisor, []),
      supervisor(Registry, [:unique, :key_registry]),
      worker(ElRedis.NodeDiscovery, [])
    ]

    # start tcp server if indicated in the configuration
    if (Application.get_env(:elredis, :accept_client_connections)) do
      children = children ++ [{ElRedis.TcpServer, []}]
    end
    Supervisor.init(children, strategy: :one_for_one)
  end
end
