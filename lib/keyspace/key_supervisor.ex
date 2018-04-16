defmodule ElRedis.KeySpaceSupervisor do
  @moduledoc """
  The main supervisor for the keyspace. Will dynamically start any K/V children pairs
  """
  use DynamicSupervisor
  require Logger
  alias ElRedis.KeyValue

  def start_link do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    Logger.info("Starting KeySpace Supervisor")
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Adds a new KeyValue node to the keyspace.
  """
  def add_node(key) do
    child_spec = {KeyValue, [key]}
    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end
end