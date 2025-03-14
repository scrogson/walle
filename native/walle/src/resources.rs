use rustler::{Resource, ResourceArc};

type PrivateKey = [u8; 32];

pub struct PrivateKeyRef(pub PrivateKey);

#[rustler::resource_impl]
impl Resource for PrivateKeyRef {}

impl PrivateKeyRef {
    pub fn new(private_key: PrivateKey) -> ResourceArc<PrivateKeyRef> {
        ResourceArc::new(PrivateKeyRef(private_key))
    }
}
