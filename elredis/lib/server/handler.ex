defmodule ElRedis.Handler do
  @moduledoc """
  A TCP Protocol handler which will handle incoming conenctions and parse them using the ElRedis.Resp
  """
  use GenServer
  require Logger

  alias ElRedis.Resp

  @doc """
  Starts the handler. Implements the ranch_protocol behaviour
  """
  def start_link(ref, socket, transport, opts) do
    pid = :proc_lib.spawn_link(__MODULE__, :init, [ref, socket, transport, opts])
    {:ok, pid}
  end

  @doc """
  Initiates the handler. And Enters the receive loop.
  """
  def init(ref, socket, transport, _opts) do
    client = get_client(socket)
    Logger.info("#{client} connecting")
    :ok = :ranch.accept_ack(ref)
    :ok = transport.setopts(socket, [{:active, true}])

    :gen_server.enter_loop(__MODULE__, [], %{
      socket: socket,
      transport: transport,
      client: client
    })
  end

  # Message CallBacks When Transport/:gen_tcp is in Active Mode
  def handle_info({:tcp_error, _, reason}, %{client: client} = state) do
    Logger.info("Error with peer #{client}: #{inspect(reason)}")

    {:stop, :normal, state}
  end

  def handle_info(
        {:tcp, _, message},
        %{socket: socket, transport: transport, client: client} = state
      ) do
    Logger.info("Received new message: #{inspect(message)} from #{client}")
    # Reply
    case Resp.parse(message) do
      {:ok, commands, ""} ->
        Logger.info("Running #{inspect(commands)} from #{client}")
      {_, _, _} ->
        Logger.info("unparseable sad")
    end
    transport.send(socket, message)
    {:noreply, state}
  end

  def handle_info({:tcp_closed, _}, %{client: client} = state) do
    Logger.info("#{client} disconnected")

    {:stop, :normal, state}
  end

  defp get_client(socket) do
    {:ok, {address, port}} = :inet.peername(socket)

    address =
      address
      |> :inet_parse.ntoa()
      |> to_string()

    "#{address}:#{port}"
  end
end
