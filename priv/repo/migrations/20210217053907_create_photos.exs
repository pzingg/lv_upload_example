defmodule LvUploadExample.Repo.Migrations.CreatePhotos do
  use Ecto.Migration

  def change do
    create table(:photos) do
      add :caption, :string
      add :file_name, :string
      add :file_type, :string
      add :url, :string, null: false
      timestamps()
    end

  end
end
