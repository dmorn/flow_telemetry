defmodule TeleFlow.Collector.FS.File do
  defstruct path: "", write: nil, read: nil, read_only?: false

  alias TeleFlow.Collector.FS

  def new(path) do
    %FS.File{path: path}
  end

  def append_event(%FS.File{read_only?: true}, event) do
    raise ArgumentError, "Append attempt of #{inspect(event)} on read-only file"
  end

  def append_event(file = %FS.File{write: nil, path: path}, event) do
    opts = [:append, :binary]
    device = File.open!(path, opts)
    append_event(%FS.File{file | write: device}, event)
  end

  def append_event(file = %FS.File{write: device}, event) do
    raw =
      event
      |> :erlang.term_to_binary()
      |> Base.encode64()

    IO.binwrite(device, [raw, "\n"])
    file
  end

  def read_event(file = %FS.File{read: nil, path: path}) do
    device = File.open!(path, [:binary, read_ahead: 20_000])
    read_event(%FS.File{file | read: device})
  end

  def read_event(file = %FS.File{read: device}) do
    event =
      case IO.binread(device, :line) do
        {:error, reason} ->
          raise "Reading from event file failed: #{inspect(reason)}"

        :eof ->
          nil

        data ->
          data
          |> String.trim()
          |> Base.decode64!()
          |> :erlang.binary_to_term()
      end

    {event, file}
  end

  def copy_read_only(%FS.File{path: path}) do
    %FS.File{FS.File.new(path) | read_only?: true}
  end

  def close(file = %FS.File{write: nil, read: nil}) do
    file
  end

  def close(file = %FS.File{write: device}) when device != nil do
    File.close(device)
    close(%FS.File{file | write: nil})
  end

  def close(file = %FS.File{read: device}) when device != nil do
    File.close(device)
    close(%FS.File{file | read: nil})
  end
end
