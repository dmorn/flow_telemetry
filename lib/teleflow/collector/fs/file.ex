defmodule TeleFlow.Collector.FS.File do
  defstruct path: "", read_only?: false, write_agent: nil, read_device: nil

  alias TeleFlow.Collector.FS

  @max_queue_size 60_000

  def new(path, read_only? \\ false)

  def new(path, false) do
    opts = [:append, :binary]
    device = File.open!(path, opts)
    {:ok, agent} = Agent.start(fn -> %{dev: device, queue: [], queue_size: 0} end)
    %FS.File{path: path, write_agent: agent, read_only?: false}
  end

  def new(path, true) do
    %FS.File{path: path, read_only?: true}
  end

  def append_event(%FS.File{read_only?: true}, event) do
    raise ArgumentError, "Append attempt of #{inspect(event)} on read-only file"
  end

  def append_event(%FS.File{write_agent: agent}, event) do
    enqueue(agent, event)
    flush_queue(agent)
  end

  def read_event(file = %FS.File{read_device: nil, path: path}) do
    device = File.open!(path, [:binary, read_ahead: 20_000])
    read_event(%FS.File{file | read_device: device})
  end

  def read_event(file = %FS.File{read_device: device}) do
    event =
      case IO.binread(device, :line) do
        {:error, reason} ->
          raise "Reading from event file failed: #{inspect(reason)}"

        :eof ->
          nil

        data ->
          decode_event(data)
      end

    {event, file}
  end

  def copy_read_only(%FS.File{path: path, write_agent: agent}) when agent != nil do
    flush_queue(agent, true)
    FS.File.new(path, true)
  end

  def close(file = %FS.File{write_agent: nil, read_device: nil}) do
    file
  end

  def close(file = %FS.File{write_agent: agent}) when agent != nil do
    flush_queue(agent, true)

    Agent.cast(agent, fn %{dev: dev} ->
      File.close(dev)
      %{dev: nil, queue: [], queue_size: 0}
    end)

    Agent.stop(agent)
    close(%FS.File{file | write_agent: nil})
  end

  def close(file = %FS.File{read_device: device}) when device != nil do
    File.close(device)
    close(%FS.File{file | read_device: nil})
  end

  defp enqueue(agent, event) do
    Agent.cast(agent, fn %{dev: dev, queue: queue, queue_size: n} ->
      %{dev: dev, queue: [encode_event(event) | queue], queue_size: n + 1}
    end)
  end

  defp flush_queue(agent, force \\ false) do
    Agent.update(agent, fn state = %{dev: dev, queue: queue, queue_size: n} ->
      if n > @max_queue_size or force do
        IO.binwrite(dev, Enum.reverse(queue))
        %{dev: dev, queue: [], queue_size: 0}
      else
        state
      end
    end)
  end

  defp encode_event(event) do
    event
    |> :erlang.term_to_binary()
    |> Base.encode64()
    |> List.wrap()
    |> Enum.concat(["\n"])
  end

  defp decode_event(iodata) do
    iodata
    |> String.trim()
    |> Base.decode64!()
    |> :erlang.binary_to_term()
  end
end
