use crate::runtime::block_on;
use alloy::{
    primitives::{hex, Address, B256, PrimitiveSignature},
    signers::{
        local::{LocalSigner, PrivateKeySigner},
        Signer,
    },
};
use std::io::Write;
use std::str::FromStr;

#[rustler::nif]
fn recover(message: String, signature: String) -> Result<String, String> {
    let signature = PrimitiveSignature::from_str(&signature).map_err(|e| e.to_string())?;
    let address = signature.recover_address_from_msg(message.as_bytes())
        .map_err(|e| e.to_string())?;
    
    Ok(address.to_checksum(None))
}

#[rustler::nif(schedule = "DirtyCpu")]
fn recover_typed_data(typed_data: String, signature: String) -> Result<String, String> {
    let signature = PrimitiveSignature::from_str(&signature).map_err(|e| e.to_string())?;
    let typed_data_json: serde_json::Value = serde_json::from_str(&typed_data)
        .map_err(|e| e.to_string())?;
    let address = signature.recover_address_from_msg(typed_data_json.to_string().as_bytes())
        .map_err(|e| e.to_string())?;
    
    Ok(address.to_checksum(None))
}

#[rustler::nif]
fn verify(message: String, signature: String, address: String) -> Result<bool, String> {
    let address = Address::from_str(&address).map_err(|e| e.to_string())?;
    let signature = PrimitiveSignature::from_str(&signature).map_err(|e| e.to_string())?;
    let recovered_address = signature.recover_address_from_msg(message.as_bytes())
        .map_err(|e| e.to_string())?;
    
    if recovered_address == address {
        Ok(true)
    } else {
        // Get lowercase hex representation
        let expected = format!("{:#x}", address);
        let got = format!("{:#x}", recovered_address);
        
        // Truncate addresses
        let truncate = |addr: &str| {
            let prefix = &addr[..6];  // includes 0x
            let suffix = &addr[addr.len()-4..];
            format!("{}…{}", prefix, suffix)
        };
        
        Err(format!(
            "Signature verification failed. Expected {}, got {}",
            truncate(&expected),
            truncate(&got)
        ))
    }
}

#[rustler::nif(schedule = "DirtyCpu")]
fn new_keystore(password: String) -> Result<String, String> {
    let dir = tempfile::TempDir::new().map_err(|e| e.to_string())?;
    let mut rng = rand::thread_rng();
    
    let wallet = PrivateKeySigner::random_with(&mut rng);
    let private_key_bytes = wallet.to_bytes();
    
    let bytes_ref: &[u8] = private_key_bytes.as_ref();
    
    let (_, name) = LocalSigner::encrypt_keystore(&dir, &mut rng, bytes_ref, &password, None)
        .map_err(|e| e.to_string())?;
    
    std::fs::read_to_string(dir.into_path().join(name))
        .map_err(|e| e.to_string())
}

#[rustler::nif(schedule = "DirtyCpu")]
fn decrypt_keystore(keystore: String, password: String) -> Result<String, String> {
    let mut tmpfile = tempfile::NamedTempFile::new().map_err(|e| e.to_string())?;
    tmpfile.write_all(keystore.as_bytes()).map_err(|e| e.to_string())?;
    
    let wallet = LocalSigner::decrypt_keystore(tmpfile.path(), &password)
        .map_err(|e| e.to_string())?;
    
    let _ = tmpfile.close();
    
    Ok(hex::encode(wallet.to_bytes().to_vec()))
}

#[rustler::nif(schedule = "DirtyCpu")]
fn public_address(private_key: String) -> Result<String, String> {
    let bytes = hex::decode(&private_key).map_err(|e| e.to_string())?;
    let bytes_array: [u8; 32] = bytes.try_into().map_err(|_| "Invalid private key length".to_string())?;
    
    let b256 = B256::from(bytes_array);
    let wallet = PrivateKeySigner::from_bytes(&b256).map_err(|e| e.to_string())?;
    
    Ok(wallet.address().to_checksum(None))
}

#[rustler::nif(schedule = "DirtyIo")]
fn sign_message(message: String, private_key: String) -> Result<String, String> {
    let signature = block_on(async move {
        let bytes = hex::decode(&private_key).map_err(|e| e.to_string())?;
        let bytes_array: [u8; 32] = bytes.try_into().map_err(|_| "Invalid private key length".to_string())?;
        
        let b256 = B256::from(bytes_array);
        let wallet = PrivateKeySigner::from_bytes(&b256).map_err(|e| e.to_string())?;
        
        let sig = wallet.sign_message(message.as_bytes()).await
            .map_err(|e| e.to_string())?;
        
        Ok::<_, String>(sig)
    })?;
    
    Ok(format!("0x{}", hex::encode(signature.as_bytes())))
}

#[rustler::nif(schedule = "DirtyIo")]
fn sign_typed_data(typed_data: String, private_key: String) -> Result<String, String> {
    let typed_data_json: serde_json::Value = serde_json::from_str(&typed_data)
        .map_err(|e| e.to_string())?;
    
    let message_bytes_string = typed_data_json.to_string();
    
    let signature = block_on(async move {
        let bytes = hex::decode(&private_key).map_err(|e| e.to_string())?;
        let bytes_array: [u8; 32] = bytes.try_into().map_err(|_| "Invalid private key length".to_string())?;
        
        let b256 = B256::from(bytes_array);
        let wallet = PrivateKeySigner::from_bytes(&b256).map_err(|e| e.to_string())?;
        
        wallet.sign_message(message_bytes_string.as_bytes()).await
            .map_err(|e| e.to_string())
    })?;
    
    Ok(format!("0x{}", hex::encode(signature.as_bytes())))
}
