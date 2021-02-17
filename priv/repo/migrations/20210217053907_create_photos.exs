defmodule LvUploadExample.Repo.Migrations.CreatePhotos do
  use Ecto.Migration

  def change do
    create table(:photos) do
      add :slug, :string
      add :caption, :string
      add :path, :string

      timestamps()
    end

  end
end
