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
      assert {:ok, _private_key} = Walle.decrypt_keystore(keystore, password)
    end
  end
end
