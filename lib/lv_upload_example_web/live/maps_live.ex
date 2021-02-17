defmodule LvUploadExampleWeb.MapsLive do
  use LvUploadExampleWeb, :live_view

  @env_file "priv/env.json"
  @env_maps_api_key :google_maps_api_key

  @impl true
  def mount(_params, _session, socket) do
    api_key = get_maps_api_key()
    {:ok, assign(socket, api_key: api_key)}
  end

  @impl true
  def handle_event("add_random_sighting", _params, socket) do
    random_sighting = generate_random_sighting()

    # inform the browser / client that there is a new sighting
    {:noreply, push_event(socket, "new_sighting", %{sighting: random_sighting})}
  end

  defp generate_random_sighting() do
    # https://developers.google.com/maps/documentation/javascript/reference/coordinates
    # Latitude ranges between -90 and 90 degrees, inclusive.
    # Longitude ranges between -180 and 180 degrees, inclusive
    %{
      lat: Enum.random(-60..60),
      lng: Enum.random(-180..180)
    }
  end

  defp get_maps_api_key() do
    {:ok, env} = load_env(@env_file)
    Map.fetch!(env, @env_maps_api_key)
  end

  defp load_env(filename) do
    with {:ok, body} <- File.read(filename) do
      Jason.decode(body, keys: :atoms!)
    end
  end
end
