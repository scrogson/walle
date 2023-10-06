defmodule Walle do
  @external_resource "README.md"
  @moduledoc File.read!("README.md")

  version = Mix.Project.config()[:version]
  env_config = Application.compile_env(:rustler_precompiled, :force_build, [])

  use RustlerPrecompiled,
    otp_app: :walle,
    crate: "walle",
    base_url: "https://github.com/scrogson/walle/releases/download/v#{version}",
    force_build: System.get_env("RUSTLER_BUILD") in ["1", true] or env_config[:walle],
    nif_versions: ["2.14"],
    targets: [
      "aarch64-apple-darwin",
      "aarch64-unknown-linux-gnu",
      "aarch64-unknown-linux-musl",
      "arm-unknown-linux-gnueabihf",
      "x86_64-apple-darwin",
      "x86_64-pc-windows-gnu",
      "x86_64-pc-windows-msvc",
      "x86_64-unknown-linux-gnu",
      "x86_64-unknown-linux-musl"
    ],
    version: version

  @doc """
  Verifies that `signature` on `message` was produced by `address`
  """
  def verify(_message, _signature, _address), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Recovers the Ethereum address which was used to sign the given message.

  Recovery signature data uses ‘Electrum’ notation, this means the `v` value is expected to be either `27` or `28`.
  """
  def recover(_message, _signature), do: :erlang.nif_error(:nif_not_loaded)
end
