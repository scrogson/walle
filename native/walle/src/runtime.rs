use once_cell::sync::Lazy;
use std::future::Future;
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
