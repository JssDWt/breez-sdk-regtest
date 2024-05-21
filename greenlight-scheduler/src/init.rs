use std::path::Path;

use bip39::{Language, Mnemonic};
use gl_client::{bitcoin::Network, signer::Signer, tls::TlsConfig};
use tokio::{fs::{self, File}, io::AsyncWriteExt};

pub async fn generate_init(dir: &Path) -> Result<Vec<u8>, Box<dyn std::error::Error>> {
    let mnemonic = Mnemonic::generate_in(Language::English, 12)?;
    let seed = mnemonic.to_seed("");
    let tls_config = TlsConfig::new()?.identity(vec![], vec![]);
    let signer = Signer::new(seed.to_vec(), Network::Regtest, tls_config.clone())?;
    let init = signer.get_init();
    let node_id = signer.node_id();

    fs::create_dir_all(dir).await?;
    println!("{}", dir.canonicalize().unwrap().to_str().unwrap());
    save(mnemonic.to_string(), &dir.join("phrase")).await?;
    save(hex::encode(&init), &dir.join("init")).await?;
    save(hex::encode(&node_id), &dir.join("nodeid")).await?;

    println!("MNEMONIC={}", mnemonic.to_string());
    println!("GL_NODE_ID={}", hex::encode(&node_id));
    println!("GL_NODE_INIT={}", hex::encode(&init));

    Ok(node_id)
}

async fn save(content: String, path: &Path) -> Result<(), Box<dyn std::error::Error>> {
    let mut file = File::create(path).await?;
    file.write(content.as_bytes()).await?;
    file.flush().await?;
    Ok(())
}