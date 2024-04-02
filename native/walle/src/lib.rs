use ethers::{
    core::{types::transaction::eip712::TypedData, utils::to_checksum},
    signers::{Signer, Wallet},
    types::{Address, Signature},
    utils::hex,
};
use once_cell::sync::Lazy;
use std::future::Future;
use std::io::Write;
use std::str::FromStr;
use tokio::runtime::{Builder, Runtime};

static TOKIO: Lazy<Runtime> = Lazy::new(|| {
    Builder::new_current_thread()
        .build()
        .expect("Walle: Failed to start tokio runtime")
});

pub fn block_on<F: Future>(future: F) -> F::Output
where
    F: Future + Send + 'static,
    F::Output: Send + 'static,
{
    TOKIO.block_on(future)
}

#[rustler::nif]
fn recover(message: String, signature: String) -> Result<String, String> {
    let signature = Signature::from_str(&signature).map_err(|e| e.to_string())?;

    match signature.recover(message) {
        Ok(address) => Ok(format!("{:#x}", address)),
        Err(e) => Err(e.to_string()),
    }
}

#[rustler::nif]
fn verify(message: String, signature: String, address: String) -> Result<bool, String> {
    let address = Address::from_str(&address).map_err(|e| e.to_string())?;
    let signature = Signature::from_str(&signature).map_err(|e| e.to_string())?;

    match signature.verify(message, address) {
        Ok(()) => Ok(true),
        Err(e) => Err(e.to_string()),
    }
}

#[rustler::nif(schedule = "DirtyCpu")]
fn new_keystore(password: String) -> Result<String, String> {
    let dir = tempfile::TempDir::new().unwrap();
    let mut rng = rand::thread_rng();
    let (_wallet, name) = Wallet::new_keystore(&dir, &mut rng, &password, None).unwrap();

    let keystore = std::fs::read_to_string(dir.into_path().join(name)).unwrap();

    Ok(keystore)
}

#[rustler::nif(schedule = "DirtyCpu")]
fn decrypt_keystore(keystore: String, password: String) -> Result<String, String> {
    let mut tmpfile = tempfile::NamedTempFile::new().unwrap();
    tmpfile.write_all(keystore.as_bytes()).unwrap();
    let wallet = Wallet::decrypt_keystore(tmpfile.path(), &password).unwrap();
    tmpfile.close().unwrap();

    Ok(format!("{:x}", wallet.signer().to_bytes()))
}

#[rustler::nif(schedule = "DirtyCpu")]
fn public_address(private_key: String) -> Result<String, String> {
    let wallet = Wallet::from_bytes(&hex::decode(&private_key).unwrap()).unwrap();
    Ok(to_checksum(&wallet.address(), None))
}

#[rustler::nif(schedule = "DirtyIo")]
fn sign_message(message: String, private_key: String) -> Result<String, String> {
    let signature = block_on(async move {
        let wallet = Wallet::from_bytes(&hex::decode(&private_key).unwrap()).unwrap();
        wallet.sign_message(message.as_bytes()).await
    })
    .unwrap();
    Ok(format!("0x{}", signature.to_string()))
}

#[rustler::nif(schedule = "DirtyIo")]
fn sign_typed_data(typed_data: String, private_key: String) -> Result<String, String> {
    let typed_data: TypedData = match serde_json::from_str(&typed_data) {
        Ok(typed_data) => typed_data,
        Err(e) => return Err(e.to_string()),
    };

    let signature = block_on(async move {
        let wallet = Wallet::from_bytes(&hex::decode(&private_key).unwrap()).unwrap();
        wallet.sign_typed_data(&typed_data).await
    })
    .unwrap();

    Ok(format!("0x{}", signature.to_string()))
}

#[rustler::nif(schedule = "DirtyCpu")]
fn recover_typed_data(typed_data: String, signature: String) -> Result<String, String> {
    let typed_data: TypedData = match serde_json::from_str(&typed_data) {
        Ok(typed_data) => typed_data,
        Err(e) => return Err(e.to_string()),
    };

    let signature = Signature::from_str(&signature).map_err(|e| e.to_string())?;

    match signature.recover_typed_data(&typed_data) {
        Ok(address) => Ok(format!("{:#x}", address)),
        Err(e) => Err(e.to_string()),
    }
}

rustler::init!(
    "Elixir.Walle",
    [
        recover,
        verify,
        new_keystore,
        decrypt_keystore,
        public_address,
        sign_message,
        sign_typed_data,
        recover_typed_data
    ]
);
