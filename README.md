# LvUploadExample

Just a test harness I'm using to validate a DefinitelyTyped definition file for Phoenix LiveView
0.15. The sample application includes a hook for Google Maps and an external uploader that
uses the UpChunk library.

To start your Phoenix server:

  * Obtain a billing account on Google Cloud Platform and configure an API key with access
    to the Google Maps API
  * Configure the API key in `config/google_maps.exs` (you can copy
    `config/google_maps_example.exs` for the correct format)
  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Install Node.js dependencies with `npm install` inside the `assets` directory
  * In the `assets/node_modules` directory, add the Typescript definition file with 
    `ln -s ../typing/custom/phoenix_live_view`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
