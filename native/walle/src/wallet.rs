use crate::runtime::block_on;
use crate::PrivateKeyRef;
use ethers::{
    core::{types::transaction::eip712::TypedData, utils::to_checksum},
    signers::{coins_bip39::English, MnemonicBuilder, Signer, Wallet as EthersWallet},
    utils::hex,
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
        let wallet = EthersWallet::new(&mut rng);
        let resource = PrivateKeyRef::new(wallet.signer().to_bytes().into());
        Ok(Wallet { resource })
    }
}

#[rustler::nif(schedule = "DirtyCpu", name = "wallet_new")]
fn new() -> Result<Wallet, String> {
    Wallet::new()
}

#[rustler::nif(schedule = "DirtyCpu", name = "wallet_from_private_key")]
fn from_private_key(private_key: &str) -> Result<Wallet, String> {
    let wallet = EthersWallet::from_bytes(&hex::decode(private_key).unwrap()).unwrap();
    let resource = PrivateKeyRef::new(wallet.signer().to_bytes().into());
    Ok(Wallet { resource })
}

#[rustler::nif(schedule = "DirtyCpu", name = "wallet_from_seed_phrase")]
fn from_seed_phrase(seed_phrase: &str) -> Result<Wallet, String> {
    let wallet = MnemonicBuilder::<English>::default()
        .phrase(seed_phrase)
        .build()
        .map_err(|e| e.to_string())?;
    let resource = PrivateKeyRef::new(wallet.signer().to_bytes().into());
    Ok(Wallet { resource })
}

#[rustler::nif(schedule = "DirtyCpu", name = "wallet_from_keystore")]
fn from_keystore(keystore: &str, password: &str) -> Result<Wallet, String> {
    let mut tmpfile = tempfile::NamedTempFile::new().unwrap();
    tmpfile.write_all(keystore.as_bytes()).unwrap();
    let wallet = EthersWallet::decrypt_keystore(tmpfile.path(), password).unwrap();
    let _ = tmpfile.close();

    let resource = PrivateKeyRef::new(wallet.signer().to_bytes().into());

    Ok(Wallet { resource })
}

#[rustler::nif(schedule = "DirtyCpu", name = "wallet_to_keystore")]
fn to_keystore(wallet: Wallet, password: &str) -> Result<String, String> {
    let dir = tempfile::TempDir::new().unwrap();
    let mut rng = rand::thread_rng();
    let (_wallet, name) =
        EthersWallet::encrypt_keystore(&dir, &mut rng, &wallet.resource.0, password, None).unwrap();
    let keystore = std::fs::read_to_string(dir.into_path().join(name)).unwrap();

    Ok(keystore)
}

#[rustler::nif(schedule = "DirtyCpu", name = "wallet_export_private_key")]
fn export_private_key(wallet: Wallet) -> String {
    hex::encode(&wallet.resource.0)
}

#[rustler::nif(schedule = "DirtyCpu", name = "wallet_address")]
fn address(wallet: Wallet) -> String {
    let wallet = EthersWallet::from_bytes(&wallet.resource.0).unwrap();
    to_checksum(&wallet.address(), None).to_string()
}

#[rustler::nif(schedule = "DirtyCpu", name = "wallet_sign_message")]
fn sign_message(wallet: Wallet, message: String) -> Result<String, String> {
    let signature = block_on(async move {
        let wallet = EthersWallet::from_bytes(&wallet.resource.0).unwrap();
        wallet.sign_message(message.as_bytes()).await
    })
    .unwrap();
    Ok(format!("0x{}", signature.to_string()))
}

#[rustler::nif(schedule = "DirtyCpu", name = "wallet_sign_typed_data")]
fn sign_typed_data(wallet: Wallet, typed_data: &str) -> Result<String, String> {
    let typed_data: TypedData = match serde_json::from_str(&typed_data) {
        Ok(typed_data) => typed_data,
        Err(e) => return Err(e.to_string()),
    };

    let signature = block_on(async move {
        let wallet = EthersWallet::from_bytes(&wallet.resource.0).unwrap();
        wallet.sign_typed_data(&typed_data).await
    })
    .unwrap();

    Ok(format!("0x{}", signature.to_string()))
}
