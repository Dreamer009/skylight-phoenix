defmodule Skylight do
  use Application

  alias Skylight.Trace

  @type resource :: binary

  def start(_type, _args) do
    import Supervisor.Spec

    load_libskylight!()

    children = [
      worker(Skylight.Store, []),
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  defp load_libskylight!() do
    path = Application.app_dir(:skylight, "priv") |> Path.join("libskylight.#{so_ext()}")

    case Skylight.NIF.load_libskylight(path) do
      {:ok, _} -> :ok
      :error   -> raise "couldn't load libskylight from #{path}"
    end
  end

  defp so_ext() do
    # TODO include Windows in this (with a .dll extension).
    case :os.type() do
      {:unix, :darwin} -> "dylib"
      {:unix, _}       -> "so"
    end
  end

  # Phoenix instrumentation API

  @doc false
  @spec phoenix_controller_render(:start, %{}, %{}) :: term
  @spec phoenix_controller_render(:stop, non_neg_integer, term) :: term
  def phoenix_controller_render(start_or_stop, arg2, arg3)

  def phoenix_controller_render(:start, _compile, runtime) do
    trace = Trace.fetch()

    handle = Trace.instrument(trace, "view.render")
    :ok = Trace.set_span_title(trace, handle, runtime.template)

    {:ok, handle}
  end

  def phoenix_controller_render(:stop, _diff, {:ok, handle}) do
    trace = Trace.fetch()
    :ok = Trace.mark_span_as_done(trace, handle)
  end
end
