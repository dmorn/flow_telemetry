defmodule TeleFlow.Collector.FS do
  defstruct [:start, :stop]

  alias TeleFlow.Collector.FS
  alias TeleFlow.Event.{Start, Stop, Span}

  require Logger

  def new(id_or_list, opts \\ [])

  def new(id_or_list, opts) when is_list(id_or_list) do
    id_or_list
    |> Enum.join("-")
    |> new(opts)
  end

  def new(id_or_list, opts) when is_binary(id_or_list) do
    cache_dir = Keyword.get_lazy(opts, :cache_dir, &System.tmp_dir!/0)
    base_dir = Path.join([cache_dir, id_or_list])
    File.mkdir_p!(base_dir)

    [start, stop] =
      ["start", "stop"]
      |> Enum.map(fn x -> [x, ".etf.b64"] end)
      |> Enum.map(&IO.chardata_to_string/1)
      |> Enum.map(fn x -> Path.join([base_dir, x]) end)
      |> Enum.map(fn x -> FS.File.new(x) end)

    %FS{start: start, stop: stop}
  end

  def write_start_event(%FS{start: driver}, event) do
    FS.File.append_event(driver, event)
  end

  def write_stop_event(%FS{stop: driver}, event) do
    FS.File.append_event(driver, event)
  end

  def stream_span_events(%FS{start: start, stop: stop}) do
    # Assumption: for each start event there exist a stop event.

    [start, stop] =
      [start, stop]
      |> Enum.map(&FS.File.copy_read_only/1)

    start_fun = fn -> [start, stop] end

    next_fun = fn files ->
      {events, files} =
        files
        |> Enum.map(&FS.File.read_event/1)
        |> Enum.unzip()

      cond do
        Enum.all?(events) -> {events, files}
        Enum.any?(events) -> {Enum.filter(events, fn x -> x != nil end), files}
        true -> {:halt, files}
      end
    end

    after_resource = fn files -> Enum.each(files, &FS.File.close/1) end

    chunk_fun = fn event, acc ->
      case Map.get(acc, event.ref) do
        nil ->
          {:cont, Map.put(acc, event.ref, event)}

        peer ->
          span = make_span(event, peer)
          {:cont, [span], Map.delete(acc, event.ref)}
      end
    end

    after_chunk = fn acc ->
      if map_size(acc) > 0 do
        Logger.warn("Telemetry.Event accumulator contains #{map_size(acc)} unmatched events")
      end

      {:cont, acc}
    end

    start_fun
    |> Stream.resource(next_fun, after_resource)
    |> Stream.chunk_while(%{}, chunk_fun, after_chunk)
    |> Stream.flat_map(fn chunks -> chunks end)
  end

  def stream_start_events(%FS{start: driver}) do
    driver
    |> FS.File.copy_read_only()
    |> stream_events()
  end

  def stream_stop_events(%FS{stop: driver}) do
    driver
    |> FS.File.copy_read_only()
    |> stream_events()
  end

  defp stream_events(file = %FS.File{}) do
    start_fun = fn -> file end

    next_fun = fn file ->
      {event, file} = FS.File.read_event(file)

      case event do
        nil -> {:halt, file}
        event -> {[event], file}
      end
    end

    after_fun = fn file ->
      FS.File.close(file)
    end

    Stream.resource(start_fun, next_fun, after_fun)
  end

  defp make_span(start = %Start{}, stop = %Stop{}), do: Span.new(start, stop)
  defp make_span(stop = %Stop{}, start = %Start{}), do: Span.new(start, stop)
end

defimpl TeleFlow.Collector, for: TeleFlow.Collector.FS do
  alias TeleFlow.Collector.FS

  def handle_start(disk, start) do
    FS.write_start_event(disk, start)
  end

  def handle_stop(disk, stop) do
    FS.write_stop_event(disk, stop)
  end
end
