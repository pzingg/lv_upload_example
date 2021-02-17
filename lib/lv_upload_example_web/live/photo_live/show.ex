defmodule LvUploadExampleWeb.PhotoLive.Show do
  use LvUploadExampleWeb, :live_view

  alias LvUploadExample.Media

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:photo, Media.get_photo!(id))}
  end

  defp page_title(:show), do: "Show Photo"
  defp page_title(:edit), do: "Edit Photo"
end
