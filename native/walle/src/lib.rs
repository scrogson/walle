use ethers::types::{Address, Signature};
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

rustler::init!("Elixir.Walle", [recover, verify]);
