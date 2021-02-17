defmodule LvUploadExample.Media.Photo do
  use Ecto.Schema
  import Ecto.Changeset

  schema "photos" do
    field :caption, :string
    field :path, :string
    field :slug, :string

    timestamps()
  end

  @doc false
  def changeset(photo, attrs) do
    photo
    |> cast(attrs, [:slug, :caption, :path])
    |> validate_required([:slug, :caption, :path])
  end
end
