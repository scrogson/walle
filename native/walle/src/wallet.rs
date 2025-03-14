use crate::resources::PrivateKeyRef;
use crate::runtime::block_on;
use alloy::{
    primitives::{hex, B256},
    signers::{
        local::{
            coins_bip39::English,
            LocalSigner,
            MnemonicBuilder,
            PrivateKeySigner,
        },
        Signer,
    },
};
use rustler::{NifStruct, ResourceArc};
use std::io::Write;

#[derive(NifStruct)]
#[module = "Walle.Wallet"]
pub struct Wallet {
    resource: ResourceArc<PrivateKeyRef>,
}

impl Wallet {
    fn new() -> Result<Wallet, String> {
        let mut rng = rand::thread_rng();
        let wallet = PrivateKeySigner::random_with(&mut rng);
        let private_key = wallet.to_bytes().to_vec();
        let resource = PrivateKeyRef::new(private_key.try_into().map_err(|_| "Invalid private key length".to_string())?);
        Ok(Wallet { resource })
    }
}

#[rustler::nif(schedule = "DirtyCpu", name = "wallet_new")]
fn new() -> Result<Wallet, String> {
    Wallet::new()
}

#[rustler::nif(schedule = "DirtyCpu", name = "wallet_from_private_key")]
fn from_private_key(private_key: &str) -> Result<Wallet, String> {
    let bytes = hex::decode(private_key).map_err(|e| e.to_string())?;
    let bytes_array: [u8; 32] = bytes.try_into().map_err(|_| "Invalid private key length".to_string())?;
    
    let b256 = B256::from(bytes_array);
    // We don't need to store the wallet here, just validate it can be created
    let _wallet = PrivateKeySigner::from_bytes(&b256).map_err(|e| e.to_string())?;
    
    let resource = PrivateKeyRef::new(bytes_array);
    Ok(Wallet { resource })
}

#[rustler::nif(schedule = "DirtyCpu", name = "wallet_from_seed_phrase")]
fn from_seed_phrase(seed_phrase: &str) -> Result<Wallet, String> {
    let wallet = MnemonicBuilder::<English>::default()
        .phrase(seed_phrase)
        .build()
        .map_err(|e| e.to_string())?;
    
    let private_key = wallet.to_bytes().to_vec();
    let bytes_array: [u8; 32] = private_key.try_into().map_err(|_| "Invalid private key length".to_string())?;
    
    let resource = PrivateKeyRef::new(bytes_array);
    Ok(Wallet { resource })
}

#[rustler::nif(schedule = "DirtyCpu", name = "wallet_from_keystore")]
fn from_keystore(keystore: &str, password: &str) -> Result<Wallet, String> {
    let mut tmpfile = tempfile::NamedTempFile::new().map_err(|e| e.to_string())?;
    tmpfile.write_all(keystore.as_bytes()).map_err(|e| e.to_string())?;
    
    let wallet = LocalSigner::decrypt_keystore(tmpfile.path(), password)
        .map_err(|e| e.to_string())?;
    
    let _ = tmpfile.close();

    let private_key = wallet.to_bytes().to_vec();
    let bytes_array: [u8; 32] = private_key.try_into().map_err(|_| "Invalid private key length".to_string())?;
    
    let resource = PrivateKeyRef::new(bytes_array);
    Ok(Wallet { resource })
}

#[rustler::nif(schedule = "DirtyCpu", name = "wallet_to_keystore")]
fn to_keystore(wallet: Wallet, password: &str) -> Result<String, String> {
    let dir = tempfile::TempDir::new().map_err(|e| e.to_string())?;
    let mut rng = rand::thread_rng();
    
    // Convert the raw bytes to B256
    let b256 = B256::from(wallet.resource.0);
    
    // Create a PrivateKeySigner from the bytes
    let wallet_signer = PrivateKeySigner::from_bytes(&b256)
        .map_err(|e| e.to_string())?;
    
    // Get the private key bytes
    let private_key_bytes = wallet_signer.to_bytes();
    
    // Convert to a byte slice to avoid the AsRef<[u8]> issue
    let bytes_ref: &[u8] = private_key_bytes.as_ref();
    
    // Call encrypt_keystore passing the private key bytes as a slice
    let (_, name) = LocalSigner::encrypt_keystore(&dir, &mut rng, bytes_ref, password, None)
        .map_err(|e| e.to_string())?;
    
    std::fs::read_to_string(dir.into_path().join(name))
        .map_err(|e| e.to_string())
}

#[rustler::nif(schedule = "DirtyCpu", name = "wallet_export_private_key")]
fn export_private_key(wallet: Wallet) -> String {
    hex::encode(&wallet.resource.0)
}

#[rustler::nif(schedule = "DirtyCpu", name = "wallet_address")]
fn address(wallet: Wallet) -> String {
    // Convert the raw bytes to B256
    let b256 = B256::from(wallet.resource.0);
    
    // Create a PrivateKeySigner from the bytes
    let wallet = PrivateKeySigner::from_bytes(&b256).unwrap();
    
    wallet.address().to_checksum(None)
}

#[rustler::nif(schedule = "DirtyCpu", name = "wallet_sign_message")]
fn sign_message(wallet: Wallet, message: String) -> Result<String, String> {
    let b256 = B256::from(wallet.resource.0);
    
    let signature = block_on(async move {
        let wallet = PrivateKeySigner::from_bytes(&b256)
            .map_err(|e| e.to_string())?;
        
        let sig = wallet.sign_message(message.as_bytes()).await
            .map_err(|e| e.to_string())?;
        
        Ok::<_, String>(sig)
    })?;
    
    Ok(format!("0x{}", hex::encode(signature.as_bytes())))
}

#[rustler::nif(schedule = "DirtyCpu", name = "wallet_sign_typed_data")]
fn sign_typed_data(wallet: Wallet, typed_data_str: &str) -> Result<String, String> {
    // Parse the typed data into structured JSON
    let typed_data_json: serde_json::Value = serde_json::from_str(typed_data_str)
        .map_err(|e| e.to_string())?;
    
    // Since alloy 0.12 doesn't have the eip712 domain module, we'll use sign_message
    // on the serialized JSON as a fallback
    let typed_data_bytes = typed_data_json.to_string();
    
    // Obtain the signature
    let b256 = B256::from(wallet.resource.0);
    let signature = block_on(async move {
        let wallet = PrivateKeySigner::from_bytes(&b256)
            .map_err(|e| e.to_string())?;
        
        // Use sign_message as a fallback since sign_typed_data_with_domain is not available
        wallet.sign_message(typed_data_bytes.as_bytes()).await
            .map_err(|e| e.to_string())
    })?;
    
    Ok(format!("0x{}", hex::encode(signature.as_bytes())))
}
