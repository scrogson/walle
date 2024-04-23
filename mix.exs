defmodule Walle.MixProject do
  use Mix.Project

  @description "NIF library for recovering ethereum based wallet addresses."
  @source_url "https://github.com/scrogson/walle"
  @version "0.4.0"

  def project do
    [
      app: :walle,
      deps: [
        {:rustler, "~> 0.30", optional: true},
        {:rustler_precompiled, "~> 0.7"},
        {:jason, "~> 1.4"},
        {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
      ],
      description: @description,
      elixir: "~> 1.14",
      name: "Walle",
      package: [
        maintainers: ["scrogson"],
        name: "walle",
        licenses: ["Apache-2.0"],
        links: %{"GitHub" => @source_url},
        files: [
          "README.md",
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
