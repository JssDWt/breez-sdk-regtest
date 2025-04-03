use std::{net::SocketAddr, str::FromStr, time::Duration};

use axum::{
    extract::{Query, State},
    response::IntoResponse,
    routing::get,
    Json, Router,
};
use bitcoincore_rpc::{
    bitcoin::{Address, Amount},
    json::AddressType,
    Auth, Client, RpcApi,
};
use clap::Parser;
use serde::Deserialize;
use tokio::{
    net::TcpListener,
    signal::unix::{signal, SignalKind},
    task,
    time::{self, sleep},
};
use tokio_util::sync::CancellationToken;

#[derive(Debug, Parser, Clone)]
#[command(name = "miner")]
#[command(about = "Mines blocks and generously sends funds to anyone who asks.", long_about = None)]
struct Cli {
    #[arg(long)]
    pub address: SocketAddr,
    #[arg(long)]
    pub bitcoin_rpcconnect: String,
    #[arg(long)]
    pub bitcoin_rpcuser: String,
    #[arg(long)]
    pub bitcoin_rpcpassword: String,
    #[arg(long)]
    pub block_interval_secs: u64,
}

#[derive(Clone)]
struct RestState {
    cli: Cli,
    token: CancellationToken,
}

#[derive(Deserialize)]
struct SendParams {
    pub address: String,
    pub amount: u64,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args = Cli::parse();
    let rpcuser = args.bitcoin_rpcuser.clone();
    let rpcpass = args.bitcoin_rpcpassword.clone();
    let rpcconnect = args.bitcoin_rpcconnect.clone();
    // Start the miner in the background
    let token = CancellationToken::new();
    let child_token = token.child_token();
    let (miner_close_tx, mut miner_close_rx) = tokio::sync::oneshot::channel();
    let miner_handle = task::spawn(async move {
        let rpc = Client::new(&rpcconnect, Auth::UserPass(rpcuser, rpcpass)).unwrap();

        loop {
            let block_count = match rpc.get_block_count() {
                Ok(block_count) => block_count,
                Err(e) => {
                    println!("waiting for bitcoind to come online: {:?}", e);
                    tokio::select! {
                        _ = sleep(Duration::from_secs(1)) => {
                            continue;
                        }
                        _ = &mut miner_close_rx => {
                            return
                        }
                    }
                }
            };

            println!("connected to bitcoind. blockheight {}.", block_count);
            if block_count < 101 {
                rpc.create_wallet("default", None, None, None, None)
                    .expect("failed create wallet");
                let address = rpc
                    .get_new_address(Some("initial blocks"), Some(AddressType::Bech32))
                    .expect("failed create address for initial blocks");
                rpc.generate_to_address(101, &address.assume_checked())
                    .expect("failed to mine initial blocks");
                println!("mined initial 101 blocks")
            } else {
                rpc.load_wallet("default").expect("failed load wallet");
            }

            break;
        }

        token.cancel();
        let mut interval = time::interval(Duration::from_secs(args.block_interval_secs));

        loop {
            tokio::select! {
                _ = interval.tick() => {
                    let address = match rpc.get_new_address(None, Some(AddressType::Bech32)) {
                        Ok(address) => address,
                        Err(e) => {
                            println!("failed to get address for periodic block: {:?}", e);
                            continue;
                        }
                    };
                    match rpc.generate_to_address(1, &address.assume_checked()) {
                        Ok(_) => println!("mined block"),
                        Err(e) => println!("failed to generate to address for periodic block: {:?}", e),
                    };
                }
                _ = &mut miner_close_rx => {
                    return
                }
            }
        }
    });

    // Start the server to send funds generously.
    let app = Router::new()
        .route("/send", get(send))
        .with_state(RestState {
            cli: args.clone(),
            token: child_token,
        });
    let listener = TcpListener::bind(args.address).await?;
    let (server_close_tx, server_close_rx) = tokio::sync::oneshot::channel();
    let server_handle = tokio::spawn(async {
        println!("Starting miner server");
        axum::serve(listener, app)
            .with_graceful_shutdown(async move {
                _ = server_close_rx.await;
            })
            .await
            .unwrap();
    });

    tokio::spawn(async move {
        let mut sigterm = signal(SignalKind::terminate()).unwrap();
        let mut sigint = signal(SignalKind::interrupt()).unwrap();
        tokio::select! {
            _ = sigterm.recv() => println!("Received SIGTERM"),
            _ = sigint.recv() => println!("Received SIGINT"),
        };
        miner_close_tx.send(()).unwrap();
        server_close_tx.send(()).unwrap();
    });

    tokio::select! {
        _ = server_handle => {
            println!("server exited");
        }
        _ = miner_handle => {
            println!("miner exited");
        }
    }
    Ok(())
}

async fn send(params: Query<SendParams>, State(args): State<RestState>) -> impl IntoResponse {
    // Ensure the wallet is active.
    args.token.cancelled().await;

    let rpc = Client::new(
        &args.cli.bitcoin_rpcconnect,
        Auth::UserPass(args.cli.bitcoin_rpcuser, args.cli.bitcoin_rpcpassword),
    )
    .unwrap();

    let address = match Address::from_str(&params.address) {
        Ok(address) => address,
        Err(e) => {
            println!("Got invalid address {}: {:?}", params.address, e);
            return Json("Invalid address");
        }
    };
    let address = address.assume_checked();

    println!("Sending {} to {}", params.amount, &address);
    match rpc.send_to_address(
        &address,
        Amount::from_sat(params.amount),
        None,
        None,
        None,
        None,
        None,
        None,
    ) {
        Ok(txid) => txid,
        Err(e) => {
            println!("Failed to send to address: {:?}", e);
            return Json("Failed to send to address");
        }
    };
    Json("")
}
