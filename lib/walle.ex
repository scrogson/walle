defmodule Walle do
  @external_resource "README.md"
  @moduledoc File.read!("README.md")

  alias Walle.Native

  @doc """
  Verifies that `signature` on `message` was produced by `address`
  """
  def verify(message, signature, address),
    do: Native.verify(message, signature, address)

  @doc """
  Recovers the Ethereum address which was used to sign the given message.

  Recovery signature data uses ‘Electrum’ notation, this means the `v` value is expected to be either `27` or `28`.
  """
  def recover(message, signature),
    do: Native.recover(message, signature)

  @doc """
  Recovers the address which signed the typed data (EIP-712).
  """
  def recover_typed_data(typed_data, signature) when is_binary(typed_data),
    do: Native.recover_typed_data(typed_data, signature)

  def recover_typed_data(typed_data, signature) when is_map(typed_data) do
    with {:ok, typed_data} <- Jason.encode(typed_data) do
      Native.recover_typed_data(typed_data, signature)
    end
  end

  @doc """
  Creates a new random encrypted JSON with the provided password.
  """
  @deprecated "Use Walle.Wallet.to_keystore/2 instead"
  def new_keystore(password),
    do: Native.new_keystore(password)

  @doc """
  Decrypts an encrypted JSON keystore from JSON string.

  Decryption supports the [Scrypt](https://tools.ietf.org/html/rfc7914.html) and [PBKDF2](https://ietf.org/rfc/rfc2898.txt) key derivation functions.
  """
  @deprecated "Use Walle.Wallet.export_private_key/1 instead"
  def decrypt_keystore(json_string, password),
    do: Native.decrypt_keystore(json_string, password)

  @doc """
  Returns the public address from the given private key.
  """
  @deprecated "Use Walle.Wallet.address/1 instead"
  def public_address(private_key),
    do: Native.public_address(private_key)

  @doc """
  Signs the given message with the provided private key.
  """
  @deprecated "Use Walle.Wallet.sign_message/2 instead"
  def sign_message(message, private_key),
    do: Native.sign_message(message, private_key)

  @doc """
  Signs typed data (EIP-712) with the provided private key.
  """
  @deprecated "Use Walle.Wallet.sign_typed_data/2 instead"
  def sign_typed_data(typed_data, private_key),
    do: Native.sign_typed_data(typed_data, private_key)
end
