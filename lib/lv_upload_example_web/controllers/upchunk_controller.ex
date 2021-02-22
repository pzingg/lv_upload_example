defmodule LvUploadExampleWeb.UpChunkController do
  use LvUploadExampleWeb, :controller

  require Logger

  # @successful_chunk_upload_codes [200, 201, 202, 204, 308]
  # These error codes imply a chunk may be retried
  # @temporary_error_codes [408, 502, 503, 504]

  def update(conn, %{"file" => _file}) do
    # Get :range and either :upload or :body from conn that was put there
    # by Plug.Parsers.UpChunk
    case conn do
      %{body_params: params} ->
        conn =
          case params do
            # %{range: %{range_end: 1273307, range_start: 0, size: 1273308},
            #   upload: %Plug.Upload{content_type: "image/png",
            #   filename: "dann-residence-1.png",
            #   path: "priv/static/uploads/chunks/<uuid>.png"}}
            %{range: range, upload: _upload} ->
              Logger.debug("Do we need to do anything with the partially written file?")

              if range.range_start == 0 do
                conn |> resp(201, "Created")
              else
                conn |> resp(204, "No content")
              end

            %{body: _body} ->
              Logger.debug("What should I do with the body?")
              conn |> resp(204, "No content")
          end

        # file or binary was good
        conn
        |> send_resp()

      _ ->
        conn
        |> resp(500, "Unfetched")
        |> send_resp()
    end
  end
end
