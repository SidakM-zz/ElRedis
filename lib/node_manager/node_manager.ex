defmodule ElRedis.NodeManager do
  use GenServer
  require Logger
    
  def start_link do
    name = get_manager_name()
    Logger.info("Starting Node Manager: #{inspect name}")
    GenServer.start_link(__MODULE__, %{}, name: {:global, name})
  end

  def handle_call(command, _from, state) do
    Logger.info("recived call")
    {:reply, :ok, state}
  end

  def get_manager_name do
    Atom.to_string(Node.self) <> ":Manager"
      |> String.to_atom
  end
end
