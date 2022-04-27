defmodule Flow.Telemetry do
  @moduledoc """
  Instruments Flow opearations.
  """

  # TODO: it would be nice now to depend on Flow itself but a Protocol defined
  # by this library. For that we need Flow to export some introspection
  # functions that allow us to retrieve operations and producers with the
  # ability to substitute them.
  def instrument(flow = %Flow{}, event_prefix) when is_list(event_prefix) do
    flow
    |> walk_and_instrument(event_prefix)
  end

  defp walk_and_instrument(flow = %Flow{}, event_prefix) do
    flow
    |> Map.update(:operations, [], fn ops ->
      Enum.map(ops, &instrument_op(&1, event_prefix))
    end)
    |> Map.update(:producers, [], fn
      {:flows, flows} ->
        {:flows, Enum.map(flows, &walk_and_instrument(&1, event_prefix))}

      other ->
        other
    end)
  end

  defp instrument_op({:mapper, id, funs}, event_prefix) do
    funs =
      funs
      |> Enum.map(fn fun ->
        fn x ->
          instrument_fun(fun, [x], event_prefix, %{
            op: :mapper,
            id: id
          })
        end
      end)

    {:mapper, id, funs}
  end

  defp instrument_op({:reduce, acc_fun, reducer_fun}, event_prefix) do
    reducer_fun = fn x, acc ->
      instrument_fun(reducer_fun, [x, acc], event_prefix, %{
        op: :reduce
      })
    end

    {:reduce, acc_fun, reducer_fun}
  end

  # TODO: missing operations
  # * {:uniq, fun()}
  # * {:emit_and_reduce, fun(), fun()}
  # * {:on_trigger, fun()}
  defp instrument_op(unsupported_op, _event_prefix) do
    unsupported_op
  end

  defp instrument_fun(fun, args, event_prefix, start_metadata) do
    :telemetry.span(
      event_prefix,
      start_metadata,
      fn ->
        result = apply(fun, args)

        metadata =
          cond do
            is_list(result) -> %{result_size: Enum.count(result)}
            true -> %{}
          end

        {result, metadata}
      end
    )
  end
end
