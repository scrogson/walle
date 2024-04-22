defmodule Walle.WalletTest do
  use ExUnit.Case

  alias Walle.Wallet

  @seed_phrase "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
  @wallet_address "0x9858EfFD232B4033E47d90003D41EC34EcaEda94"
  @private_key "1ab42cc412b618bdea3a599e3c9bae199ebf030895b039e9db1e30dafb12b727"

  test "bad wallet" do
    assert catch_error(Wallet.export_private_key(%Wallet{})) ==
             "Could not decode field :resource on %Wallet{}"
  end

  describe "new/0" do
    test "generates a new wallet" do
      assert {:ok, wallet} = Wallet.new()
      assert is_reference(wallet.resource)
    end
  end

  describe "from_seed_phrase" do
    test "generates a wallet from a seed phrase" do
      {:ok, wallet} = Wallet.from_seed_phrase(@seed_phrase)
      assert @wallet_address == Wallet.address(wallet)
    end
  end

  describe "from_private_key" do
    test "generates a wallet from a private key" do
      {:ok, wallet} = Wallet.from_private_key(@private_key)
      assert @wallet_address == Wallet.address(wallet)
    end
  end

  describe "from_keystore/2" do
    test "generates a wallet from the keystore" do
      keystore = %{
        "crypto" => %{
          "cipher" => "aes-128-ctr",
          "cipherparams" => %{"iv" => "9d3734a58102dc64b3db72b0115427d6"},
          "ciphertext" => "baec8027a27ea36387b120793d4754a881391fadb5fcff88f029d6d3cb0a0689",
          "kdf" => "scrypt",
          "kdfparams" => %{
            "dklen" => 32,
            "n" => 8192,
            "p" => 1,
            "r" => 8,
            "salt" => "c6a9a017954369617336024cf3c4afa9192f1f545eac6e2f2203627797d99a74"
          },
          "mac" => "0b92bb89ef8b9cc38e0fb5982a66e65fd50e0b6bee7506f267424de340fc6c17"
        },
        "id" => "f5231613-a53e-46a0-b256-0175d2b90ca5",
        "version" => 3
      }

      assert {:ok, wallet} = Wallet.from_keystore(keystore, "123456")
      assert @wallet_address == Wallet.address(wallet)
    end
  end

  describe "to_keystore/2" do
    test "generates a keystore for a wallet and given password" do
      assert {:ok, wallet} = Wallet.from_seed_phrase(@seed_phrase)
      assert {:ok, keystore} = Wallet.to_keystore(wallet, "123456")

      assert %{"crypto" => crypto, "id" => _, "version" => 3} = keystore

      assert %{
               "cipher" => "aes-128-ctr",
               "cipherparams" => %{"iv" => _},
               "ciphertext" => _,
               "kdf" => "scrypt",
               "kdfparams" => %{
                 "dklen" => 32,
                 "n" => 8192,
                 "p" => 1,
                 "r" => 8,
                 "salt" => _
               },
               "mac" => _
             } = crypto
    end
  end

  describe "export_private_key/1" do
    test "exports the private key" do
      {:ok, wallet} = Wallet.from_seed_phrase(@seed_phrase)
      assert @private_key == Wallet.export_private_key(wallet)
    end
  end

  describe "address/1" do
    test "returns the public address" do
      {:ok, wallet} = Wallet.from_seed_phrase(@seed_phrase)
      assert @wallet_address == Wallet.address(wallet)
    end
  end

  describe "sign_message/2" do
    test "signs a message" do
      {:ok, wallet} = Wallet.from_seed_phrase(@seed_phrase)
      address = Wallet.address(wallet)
      message = "Hello, World!"
      {:ok, signature} = Wallet.sign_message(wallet, message)
      assert {:ok, true} == Walle.verify(message, signature, address)
    end
  end

  describe "sign_typed_data/2" do
    test "signs typed data" do
      {:ok, wallet} = Wallet.from_seed_phrase(@seed_phrase)

      typed_data = %{
        "types" => %{
          "EIP712Domain" => [
            %{"name" => "name", "type" => "string"},
            %{"name" => "version", "type" => "string"},
            %{"name" => "chainId", "type" => "uint256"},
            %{"name" => "verifyingContract", "type" => "address"}
          ],
          "Person" => [
            %{"name" => "name", "type" => "string"},
            %{"name" => "wallet", "type" => "address"}
          ]
        },
        "primaryType" => "Person",
        "domain" => %{
          "name" => "Ether Mail",
          "version" => "1",
          "chainId" => 1,
          "verifyingContract" => "0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC"
        },
        "message" => %{
          "name" => "Bob",
          "wallet" => "0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB"
        }
      }

      {:ok, signature} = Wallet.sign_typed_data(wallet, typed_data)
      assert {:ok, @wallet_address} == Walle.recover_typed_data(typed_data, signature)
    end
  end
end
