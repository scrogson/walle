defmodule Walle do
  @external_resource "README.md"
  @moduledoc File.read!("README.md")

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

  @doc """
  Verifies that `signature` on `message` was produced by `address`
  """
  def verify(_message, _signature, _address), do: nif_error()

  @doc """
  Recovers the Ethereum address which was used to sign the given message.

  Recovery signature data uses ‘Electrum’ notation, this means the `v` value is expected to be either `27` or `28`.
  """
  def recover(_message, _signature), do: nif_error()

  @doc """
  Creates a new random encrypted JSON with the provided password.
  """
  def new_keystore(_password), do: nif_error()

  @doc """
  Decrypts an encrypted JSON keystore from JSON string.

  Decryption supports the [Scrypt](https://tools.ietf.org/html/rfc7914.html) and [PBKDF2](https://ietf.org/rfc/rfc2898.txt) key derivation functions.
  """
  def decrypt_keystore(_json_string, _password), do: nif_error()

  @doc """
  Returns the public address from the given private key.
  """
  def public_address(_private_key), do: nif_error()

  @doc """
  Signs the given message with the provided private key.
  """
  def sign_message(_message, _private_key), do: nif_error()

  @doc """
  Signs typed data (EIP-712) with the provided private key.
  """
  def sign_typed_data(_typed_data, _private_key), do: nif_error()

  @doc """
  Recovers the address which signed the typed data (EIP-712).
  """
  def recover_typed_data(_typed_data, _signature), do: nif_error()

  defp nif_error, do: :erlang.nif_error(:nif_not_loaded)
end
