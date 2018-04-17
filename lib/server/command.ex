defmodule ElRedis.Command do
  alias ElRedis.NodeManager

  def handle_command(["SET", key, value] = command) do
    NodeManager.queue_command(key, command)
  end

  def handle_command(["GET", key] = command) do
    NodeManager.queue_command(key, command) 
  end

  def handle_command(["SETNX", key, _] = command) do
    NodeManager.queue_command(key, command) 
  end

  def handle_command(["DEL", key] = command) do
    NodeManager.queue_command(key, command) 
  end

end