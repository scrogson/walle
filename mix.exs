defmodule Walle.MixProject do
  use Mix.Project

  @description "NIF library for recovering ethereum based wallet addresses."
  @source_url "https://github.com/scrogson/walle"
  @version "0.1.0"

  def project do
    [
      app: :walle,
      deps: [
        {:rustler, "~> 0.29", optional: true},
        {:rustler_precompiled, "~> 0.7"}
      ],
      description: @description,
      elixir: "~> 1.14",
      name: "Walle",
      package: [
        maintainers: ["scrogson"],
        name: "Walle",
        licenses: ["Apache-2.0"],
        links: %{"GitHub" => @source_url},
        files: [
          "lib",
          "native/walle/.cargo",
          "native/walle/src",
          "native/walle/Cargo*",
          "checksum-*.exs",
          "mix.exs"
        ]
      ],
      source_url: @source_url,
      start_permanent: Mix.env() == :prod,
      version: @version
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end
end
