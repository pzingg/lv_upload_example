defmodule LvUploadExample.Media.Photo do
  use Ecto.Schema
  import Ecto.Changeset

  schema "photos" do
    field :caption, :string
    field :file_name, :string
    field :file_type, :string
    field :url, :string

    timestamps()
  end

  @doc false
  def changeset(photo, attrs) do
    photo
    |> cast(attrs, [:caption, :file_name, :file_type, :url])
    |> validate_required([:caption])
  end
end
