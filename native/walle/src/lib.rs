use ethers::{
    signers::Wallet,
    types::{Address, Signature},
};
use std::io::Write;
use std::str::FromStr;

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

rustler::init!(
    "Elixir.Walle",
    [recover, verify, new_keystore, decrypt_keystore]
);
