use std::{fs::Permissions, os::unix::fs::PermissionsExt, path::Path};

use rcgen::{
    BasicConstraints, Certificate, CertificateParams, DnType, ExtendedKeyUsagePurpose, IsCa,
    KeyPair, KeyUsagePurpose,
};
use tokio::{fs::{self, File}, io::AsyncWriteExt};

pub async fn generate_certs(dir: &Path, node_id: &[u8]) -> Result<(), Box<dyn std::error::Error>> {
    let node_id = hex::encode(node_id);
    let ca_cert_path = dir.join("ca.pem");
    let ca_key_path = dir.join("ca-key.pem");
    let server_path = dir.join("users/1");
    let server_cert_path = server_path.join("server.crt");
    let server_key_path = server_path.join("server-key.pem");
    let node_path = dir.join(format!("users/{}", node_id));
    let node_cert_path = node_path.join("node.pem");
    let node_key_path = node_path.join("node-key.pem");
    let device_cert_path = node_path.join("device.pem");
    let device_key_path = node_path.join("device-key.pem");

    if ca_cert_path.exists() {
        return Ok(());
    }

    fs::create_dir_all(dir).await?;

    let (ca_cert, ca_key) = new_ca()?;
    save(ca_cert.pem(), &ca_cert_path).await?;
    save(ca_key.serialize_pem(), &ca_key_path).await?;

    fs::create_dir_all(server_path).await?;
    let (server_cert, server_key) = new_end_entity(&ca_cert, &ca_key)?;
    save(server_cert.pem(), &server_cert_path).await?;
    save(server_key.serialize_pem(), &server_key_path).await?;

    fs::create_dir_all(node_path).await?;
    let (node_cert, node_key) = new_end_entity(&ca_cert, &ca_key)?;
    save(node_cert.pem(), &node_cert_path).await?;
    save(node_key.serialize_pem(), &node_key_path).await?;

    let (device_cert, device_key) = new_end_entity(&ca_cert, &ca_key)?;
    save(device_cert.pem(), &device_cert_path).await?;
    save(device_key.serialize_pem(), &device_key_path).await?;
    println!("CA cert:\n{}", ca_cert.pem());
    println!("CA key:\n{}", ca_key.serialize_pem());
    println!("server cert:\n{}", server_cert.pem());
    println!("server key:\n{}", server_key.serialize_pem());
    println!("device cert:\n{}", device_cert.pem());
    println!("device key:\n{}", device_key.serialize_pem());
    println!("node cert:\n{}", node_cert.pem());
    println!("node key:\n{}", node_key.serialize_pem());
    Ok(())
}

async fn save(content: String, path: &Path) -> Result<(), Box<dyn std::error::Error>> {
    let mut file = File::create(path).await?;
    file.write(content.as_bytes()).await?;
    file.flush().await?;
    file.set_permissions(Permissions::from_mode(0o777)).await?;
    Ok(())
}

fn new_ca() -> Result<(Certificate, KeyPair), Box<dyn std::error::Error>> {
    let mut params = CertificateParams::new(Vec::default())?;
    params.is_ca = IsCa::Ca(BasicConstraints::Unconstrained);
    params
        .distinguished_name
        .push(DnType::OrganizationName, "Breez regtest Greenlight");
    params.key_usages.push(KeyUsagePurpose::DigitalSignature);
    params.key_usages.push(KeyUsagePurpose::KeyCertSign);
    params.key_usages.push(KeyUsagePurpose::CrlSign);

    let key_pair = KeyPair::generate()?;
    Ok((params.self_signed(&key_pair)?, key_pair))
}

fn new_end_entity(
    ca_cert: &Certificate,
    ca_key: &KeyPair,
) -> Result<(Certificate, KeyPair), Box<dyn std::error::Error>> {
    let name = "greenlight client";
    let mut params = CertificateParams::new(vec![name.into()])?;
    params.distinguished_name.push(DnType::CommonName, name);
    params.use_authority_key_identifier_extension = true;
    params.key_usages.push(KeyUsagePurpose::DigitalSignature);
    params
        .extended_key_usages
        .push(ExtendedKeyUsagePurpose::ClientAuth);
    params
        .extended_key_usages
        .push(ExtendedKeyUsagePurpose::ServerAuth);

    let key_pair = KeyPair::generate()?;
    Ok((params.signed_by(&key_pair, ca_cert, ca_key)?, key_pair))
}
