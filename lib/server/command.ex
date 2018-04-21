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

  def handle_command(["EXISTS", key] = command) do
    NodeManager.queue_command(key, command) 
  end

  def handle_command(["SETEX", key, time, value] = command) do
    time = String.to_integer(time)
    command = ["SETEX", key, time, value]
    NodeManager.queue_command(key, command) 
  end

  def handle_command(["TTL", key] = command) do
    NodeManager.queue_command(key, command) 
  end

  def handle_command(["APPEND", key, value] = command) do
    NodeManager.queue_command(key, command) 
  end

  def handle_command(["INCRBY", key, value] = command) do
    value = String.to_integer(value)
    command = ["INCRBY", key, value]
    NodeManager.queue_command(key, command) 
  end

  def handle_command(["INCR", key] = command) do
    command = ["INCRBY", key, 1]
    NodeManager.queue_command(key, command) 
  end

  def handle_command(["DECRBY", key, value] = command) do
    value = String.to_integer(value)
    command = ["DECRBY", key, value]
    NodeManager.queue_command(key, command) 
  end

  def handle_command(["DECR", key] = command) do
    command = ["DECRBY", key, 1]
    NodeManager.queue_command(key, command) 
  end
end