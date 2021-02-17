defmodule LvUploadExample.Repo do
  use Ecto.Repo,
    otp_app: :lv_upload_example,
    adapter: Ecto.Adapters.Postgres
end
