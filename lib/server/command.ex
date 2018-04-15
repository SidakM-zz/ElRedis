defmodule ElRedis.Command do
  alias ElRedis.NodeDiscovery
  alias ElRedis.NodeManager

  @ring HashRing.new()
  def handle_command(["SET", key, value] = command) do
    key |> get_node |> queue_command(command)    
  end
  def handle_command(["GET", key] = command) do
    key |> get_node |> queue_command(command)
  end

  defp get_node(key) do
    nodes = NodeDiscovery.cluster_nodes
              |> Enum.map(&(String.to_atom &1))
              |> Enum.map(&(NodeManager.get_manager_name(&1)))
    ring = HashRing.new()
            |> HashRing.add_nodes(nodes)
    HashRing.key_to_node(ring, key)
  end

  defp queue_command(node, command) do
    GenServer.call({:global, node}, command)
  end
end