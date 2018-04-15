defmodule ElRedis.KeySpaceSupervisor do
  @moduledoc """
  The main supervisor for the keyspace. Will dynamically start any K/V children pairs
  """
  use DynamicSupervisor
  require Logger

  def start_link do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    Logger.info("Starting KeySpace Supervisor")
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end