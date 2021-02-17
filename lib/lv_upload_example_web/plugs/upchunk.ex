defmodule LvUploadExampleWeb.Plug.Parsers.UpChunk do
  @behaviour Plug.Parsers

  alias Plug.Conn

  # Content-Range: <unit> <range-start>-<range-end>/<size>
  # Content-Range: <unit> <range-start>-<range-end>/*
  # Content-Range: <unit> */<size>
  @range_re ~r/(?<unit>\w+)\s+(?<range_start>(\*|\d+))(-(?<range_end>\d+))?\/(?<size>(\*|\d+))/

  @impl true
  def init(opts) do
    {limit, opts} = Keyword.pop(opts, :upchunk_limit)
    {limit, opts}
  end

  @impl true
  def parse(conn, _type, _subtype, _params, {limit, opts}) do
    # TODO: validate type, subtype or params?
    if xhr?(conn) do
      case parse_headers(conn, opts) do
        {:binary, range} ->
          {:ok, limit, body, conn} =
            parse_binary(Plug.Conn.read_body(conn, opts), limit, opts, "")

          # if Keyword.get(opts, :validate_utf8, true) do
          #  Plug.Conn.Utils.validate_utf8!(body, Plug.Parsers.BadEncodingError, "multipart body")
          # end

          if limit >= 0 do
            {:ok, %{body: body, range: range}, conn}
          else
            {:error, :too_large, conn}
          end

        {:file, %{range_start: offset} = range, path, %Plug.Upload{} = upload} ->
          # The temporary location for "path" is "guaranteed" to be unique by LiveView's uuid
          open_mode =
            case {offset, File.stat(path)} do
              {0, {:ok, _stat}} ->
                raise Plug.UploadError, "cannot overwrite file #{path} during upload"

              {0, {:error, _}} ->
                [:write, :binary, :delayed_write, :raw]

              {_, {:error, _}} ->
                raise Plug.UploadError,
                      "cannot locate file #{path} for range start #{offset} during upload"

              {_, {:ok, %{size: size}}} ->
                if size != offset do
                  raise Plug.UploadError,
                        "size of file #{path}, #{size}, does not match range start #{offset} during upload"
                end

                [:append, :binary, :delayed_write, :raw]
            end

          case File.open(path, open_mode) do
            {:ok, file} ->
              {:ok, limit, file, conn} =
                parse_file(Plug.Conn.read_body(conn, opts), limit, opts, file)

              :ok = File.close(file)

              if limit >= 0 do
                {:ok, %{upload: upload, range: range}, conn}
              else
                {:error, :too_large, conn}
              end

            {:error, reason} ->
              raise Plug.UploadError,
                    "could not open file #{path} during upload " <>
                      "due to reason: #{inspect(reason)}"
          end

        :skip ->
          {:next, conn}
      end
    else
      {:next, conn}
    end
  end

  defp parse_binary({:more, tail, conn}, limit, opts, body)
       when limit >= byte_size(tail) do
    read_result = Plug.Conn.read_part_body(conn, opts)
    parse_binary(read_result, limit - byte_size(tail), opts, body <> tail)
  end

  defp parse_binary({:more, tail, conn}, limit, _opts, body) do
    {:ok, limit - byte_size(tail), body, conn}
  end

  defp parse_binary({:ok, tail, conn}, limit, _opts, body)
       when limit >= byte_size(tail) do
    {:ok, limit - byte_size(tail), body <> tail, conn}
  end

  defp parse_binary({:ok, tail, conn}, limit, _opts, body) do
    {:ok, limit - byte_size(tail), body, conn}
  end

  defp parse_file({:more, tail, conn}, limit, opts, file)
       when limit >= byte_size(tail) do
    binwrite!(file, tail)
    read_result = Plug.Conn.read_part_body(conn, opts)
    parse_file(read_result, limit - byte_size(tail), opts, file)
  end

  defp parse_file({:more, tail, conn}, limit, _opts, file) do
    {:ok, limit - byte_size(tail), file, conn}
  end

  defp parse_file({:ok, tail, conn}, limit, _opts, file)
       when limit >= byte_size(tail) do
    binwrite!(file, tail)
    {:ok, limit - byte_size(tail), file, conn}
  end

  defp parse_file({:ok, tail, conn}, limit, _opts, file) do
    {:ok, limit - byte_size(tail), file, conn}
  end

  ## Helpers

  defp binwrite!(device, contents) do
    case IO.binwrite(device, contents) do
      :ok ->
        :ok

      {:error, reason} ->
        raise Plug.UploadError,
              "could not write to file #{inspect(device)} during upload " <>
                "due to reason: #{inspect(reason)}"
    end
  end

  defp parse_headers(conn, _opts) do
    range = handle_range(conn)

    case handle_disposition(conn) do
      %{"filename" => ""} ->
        :skip

      %{"filename" => filename} ->
        set_upload(conn, filename, range)

      %{"filename*" => ""} ->
        :skip

      %{"filename*" => "utf-8''" <> filename} ->
        filename = URI.decode(filename)

        Plug.Conn.Utils.validate_utf8!(
          filename,
          Plug.Parsers.BadEncodingError,
          "multipart filename"
        )

        set_upload(conn, filename, range)

      %{} ->
        {:binary, range}
    end
  end

  defp set_upload(conn, filename, range) do
    temp_dir = fetch_req_header!(conn, "x-storage-location")
    dest_file = List.last(conn.path_info)
    path = Path.join(temp_dir, dest_file)

    content_type = fetch_req_header!(conn, "content-type")
    upload = %Plug.Upload{filename: filename, path: path, content_type: content_type}

    {:file, range, path, upload}
  end

  defp handle_range(conn) do
    content_range = fetch_req_header!(conn, "content-range")

    case Regex.named_captures(@range_re, content_range) do
      %{"range_start" => "*", "range_end" => "", "size" => size_str} ->
        size = String.to_integer(size_str)
        %{range_start: 0, range_end: :unsatisfiable, size: size}

      %{"range_start" => start_str, "range_end" => end_str, "size" => "*"} ->
        r_start = String.to_integer(start_str)
        r_end = String.to_integer(end_str)
        %{range_start: r_start, range_end: r_end, size: :unknown}

      %{"range_start" => start_str, "range_end" => end_str, "size" => size_str} ->
        r_start = String.to_integer(start_str)
        r_end = String.to_integer(end_str)
        size = String.to_integer(size_str)
        %{range_start: r_start, range_end: r_end, size: size}

      _ ->
        %{}
    end
  end

  defp handle_disposition(conn) do
    disposition = fetch_req_header!(conn, "content-disposition")

    case :binary.split(disposition, ";") do
      [_, params] ->
        Plug.Conn.Utils.params(params)

      _ ->
        %{}
    end
  end

  defp xhr?(conn) do
    "XMLHttpRequest" in Conn.get_req_header(conn, "x-requested-with")
  end

  def fetch_req_header!(conn, key) do
    case fetch_req_header(conn, key) do
      "" ->
        raise Plug.UploadError, "missing required header #{key} for upload"

      val ->
        val
    end
  end

  def fetch_req_header(conn, key) do
    values = Conn.get_req_header(conn, key)

    case values do
      [val] ->
        val

      _ ->
        ""
    end
  end
end
