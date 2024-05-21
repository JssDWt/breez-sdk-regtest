use std::{net::SocketAddr, path::PathBuf};

use clap::Parser;
use init::generate_init;
use server::scheduler::scheduler_server::SchedulerServer;
use tonic::transport::{Server, Uri};

mod init;
mod server;
mod tls;

#[derive(Debug, Parser)]
#[command(name = "scheduler")]
#[command(about = "A Greenlight scheduler for regtest docker environments", long_about = None)]
struct Cli {
    #[arg(short, long)]
    pub address: SocketAddr,
    #[arg(short, long)]
    pub node_grpc_uri: Uri,
    #[arg(short, long)]
    pub init_path: PathBuf,
    #[arg(short, long)]
    pub cert_path: PathBuf,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args = Cli::parse();

    let node_id = generate_init(&args.init_path).await?;
    tls::generate_certs(&args.cert_path, &node_id).await?;

    let server = server::DockerScheduler::new(args.node_grpc_uri);
    Server::builder()
        .add_service(SchedulerServer::new(server))
        .serve(args.address)
        .await?;

    Ok(())
}
