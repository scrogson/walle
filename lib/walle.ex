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
    targets:
      Enum.uniq(
        ["aarch64-unknown-linux-musl", "x86_64-unknown-freebsd"] ++
          RustlerPrecompiled.Config.default_targets()
      ),
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
