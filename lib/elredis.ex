defmodule ElRedis do
  @moduledoc """
  Entrypoint for the Application. Starts the app Supervisor
  """
  use Application
  require Logger
  alias ElRedis.Supervisor

  def start(_type, _args) do
    Logger.info("Booted ElRedis")
    Supervisor.start_link()
  end
end
