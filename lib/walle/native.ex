defmodule Walle.Native do
  @moduledoc false

  version = Mix.Project.config()[:version]
  env_config = Application.compile_env(:rustler_precompiled, :force_build, [])

  use RustlerPrecompiled,
    otp_app: :walle,
    crate: "walle",
    base_url: "https://github.com/scrogson/walle/releases/download/v#{version}",
    force_build: System.get_env("RUSTLER_BUILD") in ["1", "true"] or env_config[:walle],
    nif_versions: ["2.15"],
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

  def verify(_message, _signature, _address), do: nif_error()
  def recover(_message, _signature), do: nif_error()
  def recover_typed_data(_typed_data, _signature), do: nif_error()

  # Wallet API
  def wallet_new(), do: nif_error()
  def wallet_from_seed_phrase(_seed_phrase), do: nif_error()
  def wallet_from_private_key(_private_key), do: nif_error()
  def wallet_from_keystore(_keystore, _password), do: nif_error()
  def wallet_to_keystore(_wallet, _password), do: nif_error()
  def wallet_export_private_key(_wallet), do: nif_error()
  def wallet_address(_wallet), do: nif_error()
  def wallet_sign_message(_wallet, _message), do: nif_error()
  def wallet_sign_typed_data(_wallet, _typed_data), do: nif_error()

  # deprecated
  def new_keystore(_password), do: nif_error()
  def decrypt_keystore(_json_string, _password), do: nif_error()
  def public_address(_private_key), do: nif_error()
  def sign_message(_message, _private_key), do: nif_error()
  def sign_typed_data(_typed_data, _private_key), do: nif_error()

  defp nif_error, do: :erlang.nif_error(:nif_not_loaded)
end
