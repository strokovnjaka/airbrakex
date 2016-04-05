defmodule Airbrakex.ExceptionParser do
  alias Airbrakex.Utils

  def parse(kind, reason, stack) do
    {type, message} = info(kind, reason)
    %{
      type: type,
      message: message,
      backtrace: stacktrace(stack)
    }
  end
  def parse(kind, reason) do
     parse(kind, reason, System.stacktrace)
  end

  # from plug/debugger.ex
  defp info(:error, error),
    do: {inspect(error.__struct__), Exception.message(error)}
  defp info(:throw, thrown),
    do: {"unhandled throw", inspect(thrown)}
  defp info(:exit, reason),
    do: {"unhandled exit", Exception.format_exit(reason)}


  defp stacktrace(stacktrace) do
    Enum.map stacktrace, fn
      ({ module, function, args, [] }) ->
        %{
          file: "unknown",
          line: 0,
          function: "#{ module |> Utils.strip_elixir_prefix }.#{ function }#{ args(args) }"
        }
      ({ module, function, args, [file: file, line: line_number] }) ->
        %{
          file: "(#{module |> Utils.strip_elixir_prefix }) #{List.to_string(file)}",
          line: line_number,
          function: "#{function}#{args(args)}"
        }
    end
  end

  defp args(args) when is_integer(args) do
    "/#{args}"
  end
  defp args(args) when is_list(args) do
    "(#{args
        |> Enum.map(&(inspect(&1)))
        |> Enum.join(", ")})"
  end
end
