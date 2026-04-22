defmodule App.ClickhouseLoggerHelper do
  @moduledoc """
  Helper module for the ClickhouseLogger backend.

  Provides custom field converters that map Elixir Logger values
  to ClickHouse-compatible types.
  """

  @log_levels %{
    debug: 0,
    info: 1,
    warn: 2,
    error: 3
  }

  @doc """
  Converts a Logger level atom into a numeric value for ClickHouse.

  Returns an integer compatible with `UInt8`.
  """
  def level_to_int(level, _timestamp, _message, _metadata) do
    Map.get(@log_levels, level, 4)
  end
end
