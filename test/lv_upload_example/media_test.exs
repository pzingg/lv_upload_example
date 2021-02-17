defmodule LvUploadExample.MediaTest do
  use LvUploadExample.DataCase

  alias LvUploadExample.Media

  describe "photos" do
    alias LvUploadExample.Media.Photo

    @valid_attrs %{
      caption: "some caption",
      file_name: "some file name",
      file_type: "some file type",
      url: "http://localhost:4000/uploads/some_file"
    }
    @update_attrs %{
      caption: "some updated caption",
      file_name: "some updated file_name",
      file_type: "some updated file_type",
      url: "http://localhost:4000/uploads/some_updated_file"
    }
    @invalid_attrs %{caption: nil, file_name: nil, file_type: nil, url: nil}

    def photo_fixture(attrs \\ %{}) do
      attrs =
        attrs
        |> Enum.into(@valid_attrs)

      {:ok, photo} = Media.create_photo(attrs)
      photo
    end

    test "list_photos/0 returns all photos" do
      photo = photo_fixture()
      assert Media.list_photos() == [photo]
    end

    test "get_photo!/1 returns the photo with given id" do
      photo = photo_fixture()
      assert Media.get_photo!(photo.id) == photo
    end

    test "create_photo/1 with valid data creates a photo" do
      assert {:ok, %Photo{} = photo} = Media.create_photo(@valid_attrs)
      assert photo.caption == "some caption"
      assert photo.file_name == "some file name"
      assert photo.file_type == "some file type"
    end

    test "create_photo/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Media.create_photo(@invalid_attrs)
    end

    test "update_photo/2 with valid data updates the photo" do
      photo = photo_fixture()
      assert {:ok, %Photo{} = photo} = Media.update_photo(photo, @update_attrs)
      assert photo.caption == "some updated caption"
      assert photo.file_name == "some updated file_name"
      assert photo.file_type == "some updated file_type"
    end

    test "update_photo/2 with invalid data returns error changeset" do
      photo = photo_fixture()
      assert {:error, %Ecto.Changeset{}} = Media.update_photo(photo, @invalid_attrs)
      assert photo == Media.get_photo!(photo.id)
    end

    test "delete_photo/1 deletes the photo" do
      photo = photo_fixture()
      assert {:ok, %Photo{}} = Media.delete_photo(photo)
      assert_raise Ecto.NoResultsError, fn -> Media.get_photo!(photo.id) end
    end

    test "change_photo/1 returns a photo changeset" do
      photo = photo_fixture()
      assert %Ecto.Changeset{} = Media.change_photo(photo)
    end
  end
end
