defmodule ElRedis.RingManager do
  alias ElRedis.NodeDiscovery
  def start_link do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    nodes = NodeDiscovery.cluster_nodes
    |> Enum.map(&(String.to_atom &1))
    |> Enum.map(&(get_manager_name(&1)))
    ring = HashRing.new()
      |> HashRing.add_nodes(nodes)
    {:ok, ring}
  end

  def handle_call({:get, key}, _from, ring) do
    {:reply, HashRing.key_to_node(ring, key), ring}
  end

  def get_node(key) do
    GenServer.call(__MODULE__ , {:get, key})
  end

  @doc """
  Returns the NodeManager name given the host
  """
  def get_manager_name(host \\ Node.self) do
    Atom.to_string(host) <> ":Manager"
      |> String.to_atom
  end
end