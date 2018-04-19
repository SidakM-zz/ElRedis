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

  test "EXISTS key, returns one if key is set", state do
    :ok = :gen_tcp.send(state[:socket], "*3\r\n$3\r\nSET\r\n$12\r\nexists_key_1\r\n$5\r\nvalue\r\n")
    {:ok, msg} = :gen_tcp.recv(state[:socket], 0)
    assert msg == '+OK\r\n'
    :ok = :gen_tcp.send(state[:socket], "*2\r\n$6\r\nEXISTS\r\n$12\r\nexists_key_1\r\n")
    {:ok, msg} = :gen_tcp.recv(state[:socket], 0)
    assert msg == ':1\r\n'
  end 

  test "EXISTS key, returns zero if key not set", state do
    :ok = :gen_tcp.send(state[:socket], "*2\r\n$6\r\nEXISTS\r\n$12\r\nexists_key_2\r\n")
    {:ok, msg} = :gen_tcp.recv(state[:socket], 0)
    assert msg == ':0\r\n'
  end

  test "EXISTS key, deleted key does not exist", state do
    :ok = :gen_tcp.send(state[:socket], "*3\r\n$3\r\nSET\r\n$12\r\nexists_key_1\r\n$5\r\nvalue\r\n")
    {:ok, msg} = :gen_tcp.recv(state[:socket], 0)
    assert msg == '+OK\r\n'
    :ok = :gen_tcp.send(state[:socket], "*2\r\n$3\r\nDEL\r\n$12\r\nexists_key_1\r\n")
    {:ok, msg} = :gen_tcp.recv(state[:socket], 0)
    assert msg == ':1\r\n'
    :ok = :gen_tcp.send(state[:socket], "*2\r\n$6\r\nEXISTS\r\n$12\r\nexists_key_3\r\n")
    {:ok, msg} = :gen_tcp.recv(state[:socket], 0)
    assert msg == ':0\r\n'
  end

  test "SETEX key value time, key expires after given time", state do
    :ok = :gen_tcp.send(state[:socket], "*4\r\n$5\r\nSETEX\r\n$22\r\nsetex_key_time_value_1\r\n$1\r\n5\r\n$5\r\nvalue\r\n")
    {:ok, msg} = :gen_tcp.recv(state[:socket], 0)
    assert msg == '+OK\r\n'
    # it is assumed the following command will take less than 5 seconds (if it doesn't than something is probably wrong)
    :ok = :gen_tcp.send(state[:socket], "*2\r\n$3\r\nGET\r\n$22\r\nsetex_key_time_value_1\r\n")
    {:ok, msg} = :gen_tcp.recv(state[:socket], 0)
    assert msg == '$5\r\nvalue\r\n'
    # wait for timeout to finish
    :timer.sleep(5000);
    :ok = :gen_tcp.send(state[:socket], "*2\r\n$6\r\nEXISTS\r\n$22\r\nsetex_key_time_value_1\r\n")
    {:ok, msg} = :gen_tcp.recv(state[:socket], 0)
    assert msg == ':0\r\n'
  end

  test "SETEX key value time, can set new value before key expires", state do
    :ok = :gen_tcp.send(state[:socket], "*4\r\n$5\r\nSETEX\r\n$22\r\nsetex_key_time_value_2\r\n$1\r\n5\r\n$5\r\nvalue\r\n")
    {:ok, msg} = :gen_tcp.recv(state[:socket], 0)
    assert msg == '+OK\r\n'
    :ok = :gen_tcp.send(state[:socket], "*3\r\n$3\r\nSET\r\n$22\r\nsetex_key_time_value_2\r\n$6\r\nvalue2\r\n")
    {:ok, msg} = :gen_tcp.recv(state[:socket], 0)
    assert msg == '+OK\r\n'
    :ok = :gen_tcp.send(state[:socket], "*2\r\n$3\r\nGET\r\n$22\r\nsetex_key_time_value_2\r\n")
    {:ok, msg} = :gen_tcp.recv(state[:socket], 0)
    assert msg == '$6\r\nvalue2\r\n'
    # wait for timeout to finish
    :timer.sleep(5000);
    :ok = :gen_tcp.send(state[:socket], "*2\r\n$6\r\nEXISTS\r\n$22\r\nsetex_key_time_value_1\r\n")
    {:ok, msg} = :gen_tcp.recv(state[:socket], 0)
    assert msg == ':0\r\n'
  end

  test "TTL key, returns -2 if key does not exist", state do
    :ok = :gen_tcp.send(state[:socket], "*2\r\n$3\r\nTTL\r\n$9\r\nttl_key_1\r\n")
    {:ok, msg} = :gen_tcp.recv(state[:socket], 0)
    assert msg = ":-2\r\n"
  end

  test "TTL key, returns -1 if key exists but does not have a timer", state do
    :ok = :gen_tcp.send(state[:socket], "*3\r\n$3\r\nSET\r\n$9\r\nttl_key_2\r\n$5\r\nvalue\r\n")
    {:ok, msg} = :gen_tcp.recv(state[:socket], 0)
    assert msg = "+OK\r\n"
    :ok = :gen_tcp.send(state[:socket], "*2\r\n$3\r\nTTL\r\n$9\r\nttl_key_2\r\n")
    {:ok, msg} = :gen_tcp.recv(state[:socket], 0)
    assert msg = ":-1\r\n"
  end

  test "TTL key, returns time remaining when key and timer exists", state do
    :ok = :gen_tcp.send(state[:socket], "*4\r\n$5\r\nSETEX\r\n$9\r\nttl_key_3\r\n$1\r\n5\r\n$5\r\nvalue\r\n")
    {:ok, msg} = :gen_tcp.recv(state[:socket], 0)
    assert msg = "+OK\r\n"
    :ok = :gen_tcp.send(state[:socket], "*2\r\n$3\r\nTTL\r\n$9\r\nttl_key_3\r\n")
    {:ok, msg} = :gen_tcp.recv(state[:socket], 0)
    :timer.sleep(1000);
    assert msg = ":4\r\n"
  end

  test "APPEND key value, sets key to value when key doesn't exist", state do
    :ok = :gen_tcp.send(state[:socket], "*3\r\n$6\r\nAPPEND\r\n$18\r\nappend_key_value_1\r\n$5\r\nvalue\r\n")
    {:ok, msg} = :gen_tcp.recv(state[:socket], 0)
    assert msg = ":5\r\n"
    :ok = :gen_tcp.send(state[:socket], "*2\r\n$3\r\nGET\r\n$18\r\nappend_key_value_1\r\n")
    {:ok, msg} = :gen_tcp.recv(state[:socket], 0)
    assert msg = "$5\r\nvalue\r\n" 
  end

  test "APPEND key value, adds value to key if key already exists", state do
    :ok = :gen_tcp.send(state[:socket], "*3\r\n$3\r\nSET\r\n$18\r\nappend_key_value_2\r\n$5\r\nvalue\r\n")
    {:ok, msg} = :gen_tcp.recv(state[:socket], 0)
    assert msg = "+OK\r\n"
    :ok = :gen_tcp.send(state[:socket], "*3\r\n$6\r\nAPPEND\r\n$18\r\nappend_key_value_2\r\n$5\r\nvalue\r\n")
    {:ok, msg} = :gen_tcp.recv(state[:socket], 0)
    assert msg = ":10\r\n"
    :ok = :gen_tcp.send(state[:socket], "*2\r\n$3\r\nGET\r\n$18\r\nappend_key_value_2\r\n")
    {:ok, msg} = :gen_tcp.recv(state[:socket], 0)
    assert msg = "$10\r\nvaluevalue\r\n"
  end
end
