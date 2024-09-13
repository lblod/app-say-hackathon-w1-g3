defmodule Dispatcher do
  use Matcher
  define_accept_types [
    html: ["text/html", "application/xhtml+html"],
    json: ["application/json", "application/vnd.api+json"],
    upload: ["multipart/form-data"],
    sparql_json: ["application/sparql-results+json"],
    any: [ "*/*" ],
  ]

  @any %{}
  @json %{ accept: %{ json: true } }
  @html %{ accept: %{ html: true } }


  define_layers [ :api, :frontend, :not_found ]

  # In order to forward the 'themes' resource to the
  # resource service, use the following forward rule:
  #
  # match "/themes/*path", @json do
  #   Proxy.forward conn, path, "http://resource/themes/"
  # end
  #
  # Run `docker-compose restart dispatcher` after updating
  # this file.


  match "/addresses/*path", %{ accept: [:json], layer: :api } do
    Proxy.forward(conn, path, "http://resource/addresses")
  end


  match "/agents/*path", %{ accept: [:json], layer: :api } do
    Proxy.forward(conn, path, "http://resource/agents")
  end


  match "/concepts/*path", %{ accept: [:json], layer: :api } do
    Proxy.forward(conn, path, "http://resource/concepts")
  end


  match "/content/*path", %{ accept: [:json], layer: :api } do
    Proxy.forward(conn, path, "http://resource/content")
  end


  match "/human-made-objects/*path", %{ accept: [:json], layer: :api } do
    Proxy.forward(conn, path, "http://resource/human-made-objects")
  end


  match "/immovable-heritage/*path", %{ accept: [:json], layer: :api } do
    Proxy.forward(conn, path, "http://resource/immovable-heritage")
  end


  match "/legal-acts/*path", %{ accept: [:json], layer: :api } do
    Proxy.forward(conn, path, "http://resource/legal-acts")
  end


  match "/legal-events/*path", %{ accept: [:json], layer: :api } do
    Proxy.forward(conn, path, "http://resource/legal-events")
  end


  match "/legal-subjects/*path", %{ accept: [:json], layer: :api } do
    Proxy.forward(conn, path, "http://resource/legal-subjects")
  end


  match "/people/*path", %{ accept: [:json], layer: :api } do
    Proxy.forward(conn, path, "http://resource/people")
  end


  match "/requests/*path", %{ accept: [:json], layer: :api } do
    Proxy.forward(conn, path, "http://resource/requests")
  end

  ###############################################################
  # /fetch-decision-info/'
  ###############################################################

  match "/fetch-decision-info/*path", %{ accept: [:any], layer: :api } do
    Proxy.forward(conn, path, "http://hacky-backend/fetch-decision-info")
  end

  ###############################################################
  #   FRONTEND
  ###############################################################


  match "/assets/*path", %{ layer: :api } do
    Proxy.forward conn, path, "http://frontend/assets/"
  end

  match "/@appuniversum/*path", %{ layer: :api } do
    Proxy.forward conn, path, "http://frontend/@appuniversum/"
  end

  match "/*path", %{ accept: [:html], layer: :api } do
    Proxy.forward conn, [], "http://frontend/index.html"
  end

  match "/*_path", %{ layer: :frontend } do
    Proxy.forward conn, [], "http://frontend/index.html"
  end

  match "/groups/*path", %{ accept: [:json], layer: :api} do
    Proxy.forward conn, path, "http://resource/administrative-units/"
  end

  ###############################################################
  #   ERROR HANDLING
  ###############################################################

  match "/*_", %{accept: [:any], layer: :not_found} do
    send_resp( conn, 404, "Route not found.  See config/dispatcher.ex" )
  end

end
