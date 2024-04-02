defmodule WalleTest do
  use ExUnit.Case
  doctest Walle

  setup do
    {:ok,
     message: "Hello, world!",
     wallet_1: %{
       address: "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266",
       signature:
         "9dba579c978220c653b992b02817dc676a08486dc12f9fb0e9898b506a92fae97770a8198ae4915e9e43504d32cefaf5f88b4e6c1ad02d0d0f8604880de2aa251b"
     },
     wallet_2: %{
       address: "0x70997970c51812dc3a010c7d01b50e0d17dc79c8",
       signature:
         "3e5991581f15944dce56238e3efe40bbeb383c7e768b9847646e91be70c80a322a24b735fcfe81b2ef72ea5c67566a5b4b5d197cf65cf105a343d6393820a9d91b"
     },
     private: %{
       private_key: "0b50ebd4eec51a753db1e8af2ab44c83c867dfe10f2d677cc4183cf1570e5585",
       address: "0x63d8090c7353a57485965251506dd2a15244dee5"
     }}
  end

  describe "recover/2" do
    test "recovers the wallet given a message and signature", %{
      message: message,
      wallet_1: wallet_1,
      wallet_2: wallet_2
    } do
      for wallet <- [wallet_1, wallet_2] do
        assert Walle.recover(message, wallet.signature) == {:ok, wallet.address}
      end
    end
  end

  describe "verify/3" do
    test "verifies the wallet given a message and signature", %{
      message: message,
      wallet_1: wallet
    } do
      assert Walle.verify(message, wallet.signature, wallet.address) == {:ok, true}
    end

    test "returns an error if not verified", %{
      message: message,
      wallet_1: wallet_1,
      wallet_2: wallet_2
    } do
      assert Walle.verify(message, wallet_1.signature, wallet_2.address) ==
               {:error, "Signature verification failed. Expected 0x7099…79c8, got 0xf39f…2266"}
    end
  end

  describe "new_keystore/2" do
    test "generates a new keystore encrypted with a password" do
      assert {:ok, keystore} = Walle.new_keystore("password")

      assert %{
               "crypto" => %{
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
               },
               "id" => _,
               "version" => 3
             } = Jason.decode!(keystore)
    end
  end

  describe "decrypt_keystore/2" do
    test "decrypts the wallet JSON keystore" do
      password = "password"
      assert {:ok, keystore} = Walle.new_keystore(password)
      assert {:ok, private_key} = Walle.decrypt_keystore(keystore, password)
      assert String.length(private_key) == 64
    end
  end

  describe "public_address/1" do
    test "returns the public address from the private key", %{private: private} do
      assert {:ok, address} = Walle.public_address(private.private_key)

      assert String.downcase(address) == private.address
    end
  end

  describe "sign_message/2" do
    test "signs the message with the private key", %{message: message, private: private} do
      %{address: address, private_key: private_key} = private

      {_micros, {:ok, signature}} = :timer.tc(Walle, :sign_message, [message, private_key])
      # IO.inspect({micros, signature})
      # 218 microseconds (milliseconds: 0.218)
      assert String.length(signature) == 132
      assert Walle.recover(message, signature) == {:ok, address}
    end
  end

  describe "sign_typed_data/2" do
    test "signs the EIP-721 message with the private key", %{private: private} do
      %{address: address, private_key: private_key} = private

      typed_data = eip_712_message()

      {:ok, signature} = Walle.sign_typed_data(typed_data, private_key)
      assert String.length(signature) == 132

      assert {:ok, ^address} = Walle.recover_typed_data(typed_data, signature)
    end
  end

  defp eip_712_message do
    ~s({
      "types": {
        "EIP712Domain": [
          {
            "name": "name",
            "type": "string"
          },
          {
            "name": "version",
            "type": "string"
          },
          {
            "name": "chainId",
            "type": "uint256"
          },
          {
            "name": "verifyingContract",
            "type": "address"
          }
        ],
        "Message": [
          {
            "name": "data",
            "type": "string"
          }
        ]
      },
      "primaryType": "Message",
      "domain": {
        "name": "example.metamask.io",
        "version": "1",
        "chainId": "1",
        "verifyingContract": "0x0000000000000000000000000000000000000000"
      },
      "message": {
        "data": "Hello!"
      }
    })
  end
end
