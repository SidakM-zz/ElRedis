defmodule ElRedisTest do
  use ExUnit.Case
  doctest ElRedis
  
  setup_all do
    opts = [active: false]
    {:ok, socket} = :gen_tcp.connect('localhost', Application.get_env(:elredis, :port), opts)
    # 6379
    {:ok, socket: socket}
  end

  test "SET key value, sets key to value", state do
    :ok = :gen_tcp.send(state[:socket], "*3\r\n$3\r\nSET\r\n$15\r\nset_key_value_1\r\n$5\r\nvalue\r\n")
    {:ok, msg} = :gen_tcp.recv(state[:socket], 0)
    assert msg == '+OK\r\n'
  end

  test "GET key, gets value for key", state do
    :ok = :gen_tcp.send(state[:socket], "*3\r\n$3\r\nSET\r\n$15\r\nget_key_value_1\r\n$5\r\nvalue\r\n")
    :gen_tcp.recv(state[:socket], 0)
    :ok = :gen_tcp.send(state[:socket], "*2\r\n$3\r\nGET\r\n$15\r\nget_key_value_1\r\n")
    {:ok, msg} = :gen_tcp.recv(state[:socket], 0)
    assert msg == '$5\r\nvalue\r\n'
  end

  test "GET key, returns null bulk string when key is not set", state do
    :ok = :gen_tcp.send(state[:socket], "*2\r\n$3\r\nGET\r\n$15\r\nget_key_value_2\r\n")
    {:ok, msg} = :gen_tcp.recv(state[:socket], 0)
    assert msg == '$-1\r\n'
  end

  test "SETNX key value, sets key if key already exists", state do
    :ok = :gen_tcp.send(state[:socket], "*3\r\n$5\r\nSETNX\r\n$17\r\nsetnx_key_value_1\r\n$2\r\n15\r\n")
    {:ok, msg} = :gen_tcp.recv(state[:socket], 0)
    assert msg == ':1\r\n'
  end

  test "DEL key, deletes key if key is set", state do
    :ok = :gen_tcp.send(state[:socket], "*3\r\n$3\r\nSET\r\n$9\r\ndel_key_1\r\n$5\r\nvalue\r\n")
    {:ok, msg} = :gen_tcp.recv(state[:socket], 0)
    assert msg == '+OK\r\n'
    :ok = :gen_tcp.send(state[:socket], "*2\r\n$3\r\nDEL\r\n$9\r\ndel_key_1\r\n")
    {:ok, msg} = :gen_tcp.recv(state[:socket], 0)
    assert msg == ':1\r\n'
    :ok = :gen_tcp.send(state[:socket], "*2\r\n$3\r\nGET\r\n$9\r\ndel_key_1\r\n")
    {:ok, msg} = :gen_tcp.recv(state[:socket], 0)
    assert msg == '$-1\r\n'
  end

  test "DEL key, returns zero if key not set", state do
    :ok = :gen_tcp.send(state[:socket], "*2\r\n$3\r\nDEL\r\n$9\r\ndel_key_2\r\n")
    {:ok, msg} = :gen_tcp.recv(state[:socket], 0)
    assert msg == ':0\r\n'
  end
end
