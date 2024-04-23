defmodule Walle.Wallet do
  @moduledoc """
  Wallet specifc functions.
  """
  alias Walle.{Native, Wallet}

  defstruct [:resource]

  @doc """
  Generates a new random wallet.
  """
  def new do
    Native.wallet_new()
  end

  @doc """
  Returns a new wallet from seed phrase.
  """
  def from_seed_phrase(seed_phrase) do
    Native.wallet_from_seed_phrase(seed_phrase)
  end

  @doc """
  Returns a new wallet from the given private key.
  """
  def from_private_key(private_key) do
    Native.wallet_from_private_key(private_key)
  end

  @doc """
  Returns a new wallet from the given keystore and password.
  """
  def from_keystore(keystore, password) when is_binary(keystore) do
    Native.wallet_from_keystore(keystore, password)
  end

  def from_keystore(keystore, password) when is_map(keystore) do
    with {:ok, string} <- Jason.encode(keystore) do
      Native.wallet_from_keystore(string, password)
    end
  end

  @doc """
  Generates an encrypted JSON keystore from the given wallet.

  The keystore is encrypted with the provided password.
  """
  def to_keystore(%Wallet{} = wallet, password) do
    with {:ok, keystore} <- Native.wallet_to_keystore(wallet, password) do
      Jason.decode(keystore)
    end
  end

  @doc """
  Export the private key of the given wallet.
  """
  def export_private_key(%Wallet{} = wallet) do
    Native.wallet_export_private_key(wallet)
  end

  @doc """
  Returns the public address from the given private key.
  """
  def address(%Wallet{} = wallet) do
    Native.wallet_address(wallet)
  end

  @doc """
  Signs the given message with the provided private key.
  """
  def sign_message(%Wallet{} = wallet, message) do
    Native.wallet_sign_message(wallet, message)
  end

  @doc """
  Signs typed data (EIP-712) with the provided private key.
  """
  def sign_typed_data(%Wallet{} = wallet, data) when is_binary(data) do
    Native.wallet_sign_typed_data(wallet, data)
  end

  def sign_typed_data(%Wallet{} = wallet, data) when is_map(data) do
    with {:ok, string} <- Jason.encode(data) do
      Native.wallet_sign_typed_data(wallet, string)
    end
  end
end
