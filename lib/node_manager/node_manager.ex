defmodule ElRedis.NodeManager do
  use GenServer
  require Logger

  alias ElRedis.StringValue
    
  def start_link do
    name = get_manager_name()
    Logger.info("Starting Node Manager: #{inspect name}")
    GenServer.start_link(__MODULE__, %{}, name: {:global, name})
  end

  def handle_call(command, from, state) do
    require IEx
    IEx.pry
    {:reply, :ok, state}
  end

  def get_manager_name(host \\ Node.self) do
    Atom.to_string(host) <> ":Manager"
      |> String.to_atom
  end
end

#GenServer.call({:global, :"host2@127.0.0.1:Manager"}, :GET)