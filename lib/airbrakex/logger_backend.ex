defmodule Airbrakex.LoggerBackend do
  use GenEvent

  def init(__MODULE__) do
    {:ok, configure([])}
  end

  def handle_call({:configure, opts}, _state) do
    {:ok, :ok, configure(opts)}
  end

  def handle_event({_level, gl, _event}, state) when node(gl) != node() do
    {:ok, state}
  end

  def handle_event({level, _gl, event}, %{metadata: keys} = state) do
    if proceed?(event) and meet_level?(level, state.level) do
      post_event(event, keys)
    end
    {:ok, state}
  end

  defp proceed?({Logger, _msg, _ts, meta}) do
    Keyword.get(meta, :airbrakex, true)
  end

  defp meet_level?(lvl, min) do
    Logger.compare_levels(lvl, min) != :lt
  end

  defp post_event({Logger, msg, _ts, _meta}, _keys) do
    msg = IO.chardata_to_string(msg)
    error = Airbrakex.LoggerParser.parse(msg)
    meta = build_metadata(error)
    error |> Airbrakex.Notifier.notify(Map.to_list(meta))
  end

  defp build_metadata(error) do
    {:ok, hostname} =  :inet.gethostname
    context = %{
      component: get_component(error),
      hostname: hostname |> to_string,
      version: Application.get_env(:airbrakex, :version),
      rootDirectory: Application.app_dir(Application.get_env(:airbrakex, :app_name)),
    }
    %{
      context: context
    }
  end

  defp get_component(%{backtrace: backtrace}) do
    case backtrace do
      [%{"function" => function} | _t] ->
        function
      [h | _t] ->
        h |> to_string
      _ ->
        "unknown"
    end
  end
  defp get_component(_) do
    "unknown"
  end

  defp configure(opts) do
    config = Application.get_env(:logger, __MODULE__, []) |> Keyword.merge(opts)

    Application.put_env(:logger, __MODULE__, config)

    %{
      level: Application.get_env(:airbrakex, :logger_level, :error),
      metadata: Keyword.get(config, :metadata, [])
    }
  end
end
