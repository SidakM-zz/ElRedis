defmodule ElRedis.NodeDiscovery do
  @moduledoc """
  Simple "heartbeat" for the entire cluster. Checks to see if the cluster nodes in the config can be contacted.
  """
  use GenServer
  require Logger
  @check_interval 10000

  def start_link do
    pid = :proc_lib.spawn_link(__MODULE__,:init, [])
    {:ok, pid}
  end

  @doc """
  Begins the process discover process
  """
  def init do
    discover
  end

  @doc """
  Pings Cluster Nodes
  """
  def check_cluster_nodes do
    cluster_nodes
      |> Enum.map(&(String.to_atom &1))
      |> Enum.map(&({&1, Node.connect(&1) == true}))
  end
    
  @doc """
  Returns a list of nodes which should be active from the application configuration
  """
  def cluster_nodes do
    active_nodes = Enum.to_list (1..Application.get_env(:elredis, :num_hosts))
      |> Enum.map(&(Integer.to_string(&1)))
      |> Enum.map(&("host") <> &1)
      |> Enum.map(&(String.to_atom(&1)))
      |> Enum.map(&(Application.get_env(:elredis, &1)))
    active_nodes
  end

  @doc """
  Periodically checks to see if cluster nodes are active
  """
  def discover do
    status = inspect(check_cluster_nodes)
    Logger.info(Atom.to_string(Node.self) <> status)
    :timer.sleep(@check_interval)
    discover
  end
end