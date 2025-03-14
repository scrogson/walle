mod deprecated;
mod resources;
mod runtime;
mod wallet;

rustler::init!("Elixir.Walle.Native", load = runtime::load);
