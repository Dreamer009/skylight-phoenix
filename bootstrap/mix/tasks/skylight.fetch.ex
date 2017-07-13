defmodule Mix.Tasks.Skylight.Fetch do
  use Mix.Task

  @shortdoc "TODO"

  @moduledoc "TODO"

  def run(_args) do
    opts = Keyword.put_new([], :use_deps_dir, true)

    :ok = SkylightBootstrap.fetch(opts)
  end
end
