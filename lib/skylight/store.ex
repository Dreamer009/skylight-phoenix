defmodule Skylight.Store do
  @moduledoc """
  Store for global state in the `:skylight` application.

  This store is a `GenServer` that manages all the application-wide global
  state.

  The ETS table stores:

    * the global Skylight instrumenter (under the `:instrumenter` key)

  """

  use GenServer

  alias Skylight.Instrumenter
  alias Skylight.Config

  @table_name __MODULE__
  @table_opts [:named_table, :protected, :set, read_concurrency: true]

  ## Public API

  @doc """
  Starts this store and creates the ETS table.
  """
  @spec start_link() :: GenServer.on_start
  def start_link() do
    GenServer.start_link(__MODULE__, :ok)
  end

  @doc """
  Retrieves the instrumenter from the global state.
  """
  @spec get_instrumenter() :: Instrumenter.t | no_return
  def get_instrumenter() do
    case :ets.lookup(@table_name, :instrumenter) do
      [] ->
        raise "instrumenter not found in the ETS table"
      [{:instrumenter, instrumenter}] ->
        instrumenter
    end
  end

  ## Callbacks

  @doc false
  def init(:ok) do
    create_ets_table()
    {:ok, nil}
  end

  ## Helpers

  defp create_ets_table do
    :ets.new(@table_name, @table_opts)
    :ets.insert(@table_name, {:instrumenter, create_and_start_instrumenter()})
  end

  defp create_and_start_instrumenter do
    inst = Instrumenter.new(Config.read())
    :ok = Instrumenter.start(inst)
    inst
  end
end
