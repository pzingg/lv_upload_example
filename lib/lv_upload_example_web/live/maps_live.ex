defmodule LvUploadExampleWeb.MapsLive do
  use LvUploadExampleWeb, :live_view

  # Compile-time configuration
  @api_key Application.get_env(:lv_upload_example, :google_maps) |> Keyword.get(:api_key)

  # New York, New York
  @map_lat 40.7128
  @map_lng -74.0060
  @range_lat 0.4
  @range_lng 0.8

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, api_key: @api_key, map_lat: @map_lat, map_lng: @map_lng)}
  end

  @impl true
  def handle_event("add_random_sighting", _params, socket) do
    random_sighting = generate_random_sighting()

    # inform the browser / client that there is a new sighting
    {:noreply, push_event(socket, "new_sighting", %{sighting: random_sighting})}
  end

  defp generate_random_sighting() do
    # https://developers.google.com/maps/documentation/javascript/reference/coordinates
    %{
      lat: @map_lat + :rand.uniform() * @range_lat - @range_lat / 2,
      lng: @map_lng + :rand.uniform() * @range_lng - @range_lng / 2
    }
  end
end
