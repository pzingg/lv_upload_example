defmodule LvUploadExampleWeb.PhotoLive.FormComponent do
  use LvUploadExampleWeb, :live_component

  alias Phoenix.LiveView.UploadEntry
  alias LvUploadExample.Media
  alias LvUploadExample.Media.Photo

  @upchunk_temp_dir "priv/static/uploads/chunks"
  @upchunk_req_path "/upchunk"

  @upload_dir "priv/static/uploads"
  @upload_req_path "/uploads"

  @impl true
  def mount(socket) do
    # We only allow one upload at a time. Could allow more here.
    {:ok,
     allow_upload(socket, :photo,
       accept: ~w(.png .jpeg .jpg),
       external: &set_upchunk_uploader/2
     )}
  end

  @impl true
  def update(%{photo: photo} = assigns, socket) do
    changeset = Media.change_photo(photo)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"photo" => photo_params}, socket) do
    changeset =
      socket.assigns.photo
      |> Media.change_photo(photo_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"photo" => photo_params}, socket) do
    save_photo(socket, socket.assigns.action, photo_params)
  end

  @impl true
  def handle_event("cancel-entry", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :photo, ref)}
  end

  # entry is a %Phoenix.LiveView.UploadEntry{
  #  cancelled?: false,
  #  client_last_modified: nil,
  #  client_name: "balliere-matte.png",
  #  client_size: 1196129,
  #  client_type: "image/png",
  #  done?: false,
  #  preflighted?: true,
  #  progress: 0,
  #  ref: "0",
  #  upload_config: :photo,
  #  upload_ref: "phx-FmU1eAOWVPpBjwAI",
  #  uuid: "566d8e59-4278-401c-841c-e294409b4270",
  #  valid?: true
  # }
  defp set_upchunk_uploader(
         %UploadEntry{upload_config: upload_config, upload_ref: upload_ref, uuid: uuid} = entry,
         socket
       ) do
    temp_dir = @upchunk_temp_dir
    link = url_for_entry(entry, socket, @upchunk_req_path)
    path = file_path_for_entry(entry, temp_dir)

    # Must supply a 'path' meta to be compliant with the
    # internal LiveView uploader
    {:ok,
     %{
       uploader: "upchunk",
       config: upload_config,
       ref: upload_ref,
       uuid: uuid,
       endpoint: link,
       temp_dir: temp_dir,
       path: path
     }, socket}
  end

  # "file_type" is never sent, because input is marked disabled
  defp save_photo(socket, :edit, params) do
    photo = socket.assigns.photo
    photo_params = put_photo_url(socket, params, true)

    case Media.update_photo(photo, photo_params, &consume_photos(socket, &1)) do
      {:ok, _photo} ->
        {:noreply,
         socket
         |> put_flash(:info, "Photo updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  # "file_type" is never sent, because input is marked disabled
  defp save_photo(socket, :new, params) do
    photo_params = put_photo_url(socket, params, true)

    case Media.create_photo(photo_params, &consume_photos(socket, &1)) do
      {:ok, _photo} ->
        {:noreply,
         socket
         |> put_flash(:info, "Photo created successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp put_photo_url(socket, photo_params, forget_file_name) do
    {completed, _} = uploaded_entries(socket, :photo)

    case completed do
      # We only allow one upload at a time.
      [entry] ->
        photo_params =
          Map.merge(photo_params, %{
            "file_type" => entry.client_type,
            "url" => url_for_entry(entry, socket)
          })

        if forget_file_name || Map.get(photo_params, "file_name", "") == "" do
          Map.put(photo_params, "file_name", entry.client_name)
        else
          photo_params
        end

      # Either zero, or two or more completed
      _ ->
        photo_params
    end
  end

  defp consume_photos(socket, %Photo{} = photo) do
    consume_uploaded_entries(socket, :photo, fn meta, entry ->
      dest = file_path_for_entry(entry)
      File.cp!(meta.path, dest)
    end)

    {:ok, photo}
  end

  def url_for_entry(entry, socket, prefix \\ @upload_req_path) do
    Routes.static_path(socket, "#{prefix}/#{file_name_for_entry(entry)}")
  end

  def file_path_for_entry(entry, dir \\ @upload_dir) do
    Path.join(dir, file_name_for_entry(entry))
  end

  defp file_ext_for_entry(entry) do
    [ext | _] = MIME.extensions(entry.client_type)
    ext
  end

  defp file_name_for_entry(entry) do
    entry.uuid <> "." <> file_ext_for_entry(entry)
  end
end
