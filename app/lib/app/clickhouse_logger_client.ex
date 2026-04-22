defmodule App.ClickhouseLoggerClient do
  @moduledoc """
  Custom HTTP client for ClickHouse Logger with Basic Auth support,
  built on the `Req` library.

  Extracts `userinfo` from `base_uri` and sends it via
  `Authorization: Basic …`.  Otherwise mirrors the built-in
  `ClickhouseLogger.HttpClient` behaviour.

  ## Configuration

  ```elixir
  config :logger, ClickhouseLogger,
    client: App.ClickhouseLoggerClient,
    base_uri: "http://default:clickhouse@localhost:8123",
    database: "logs",
    fields: [ ... ]
  ```
  """

  require Logger

  @behaviour ClickhouseLogger.Client

  import Bitwise

  # -----------------------------------------------------------------
  # behaviour callbacks
  # -----------------------------------------------------------------

  @impl true
  def init(opts) do
    # Req reuses Finch pools automatically; no explicit init required.
    # Still delegate to the standard client so the state shape is 100%
    # compatible with what `ClickhouseLogger` expects.
    ClickhouseLogger.HttpClient.init(opts)
  end

  @impl true
  def configure(opts, st) do
    ClickhouseLogger.HttpClient.configure(opts, st)
  end

  @impl true
  def send(
        data,
        %{base_uri: base_uri, database: db, table: table, fields: fields, types: [_ | _] = types} =
          st
      ) do
    query = "INSERT INTO `#{db}`.`#{table}` (#{fields}) FORMAT RowBinary"

    request_uri =
      base_uri
      |> Map.put(:userinfo, nil)
      |> Map.put(:query, URI.encode_query(%{query: query}))
      |> URI.to_string()

    encoded =
      data
      |> Enum.map(fn row ->
        row
        |> Enum.zip(types)
        |> Enum.map(&encode_row_binary/1)
        |> IO.iodata_to_binary()
      end)
      |> IO.iodata_to_binary()

    headers = build_auth_headers(base_uri)

    case Req.post(request_uri, headers: headers, body: encoded, retry: false) do
      {:ok, %Req.Response{status: 200}} ->
        {:ok, st}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, {:clickhouse_error, status, body}, st}

      {:error, error} ->
        {:error, {:connection_error, error}, st}
    end
  end

  def send(_data, st), do: {:ok, st}

  # -----------------------------------------------------------------
  # private helpers
  # -----------------------------------------------------------------

  defp build_auth_headers(%URI{userinfo: nil}), do: []

  defp build_auth_headers(%URI{userinfo: userinfo}) do
    [authorization: "Basic #{Base.encode64(userinfo)}"]
  end

  # ---- RowBinary encoding (mirrors ClickhouseLogger.HttpClient) ----

  defp encode_row_binary({v, :string}), do: [encode_leb128(IO.iodata_length(v)), v]
  defp encode_row_binary({v, :uint8}), do: <<v>>
  defp encode_row_binary({v, :uint16}), do: <<v::little-size(16)>>
  defp encode_row_binary({v, :uint32}), do: <<v::little-size(32)>>
  defp encode_row_binary({v, :uint64}), do: <<v::little-size(64)>>
  defp encode_row_binary({v, :int8}), do: <<v::signed>>
  defp encode_row_binary({v, :int16}), do: <<v::signed-little-size(16)>>
  defp encode_row_binary({v, :int32}), do: <<v::signed-little-size(32)>>
  defp encode_row_binary({v, :int64}), do: <<v::signed-little-size(64)>>

  defp encode_row_binary({v, {:array, subtype}}) do
    [encode_leb128(length(v)) | Enum.map(v, &encode_row_binary({&1, subtype}))]
  end

  defp encode_leb128(v) when v < 128, do: <<v>>
  defp encode_leb128(v), do: <<1::1, v::7, encode_leb128(v >>> 7)::binary>>
end
