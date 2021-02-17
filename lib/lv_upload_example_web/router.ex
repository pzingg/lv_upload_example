defmodule LvUploadExampleWeb.Router do
  use LvUploadExampleWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {LvUploadExampleWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :csrf do
    plug :accepts, ["json"]
    plug :fetch_session
    plug :protect_from_forgery
  end

  scope "/upchunk", LvUploadExampleWeb do
    pipe_through :csrf

    put "/:file", UpChunkController, :update
  end

  scope "/", LvUploadExampleWeb do
    pipe_through :browser

    live "/photos", PhotoLive.Index, :index
    live "/photos/new", PhotoLive.Index, :new
    live "/photos/:id/edit", PhotoLive.Index, :edit

    live "/photos/:id", PhotoLive.Show, :show
    live "/photos/:id/show/edit", PhotoLive.Show, :edit

    live "/maps", MapsLive, :index

    live "/", PageLive, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", LvUploadExampleWeb do
  #   pipe_through :api
  # end
end
