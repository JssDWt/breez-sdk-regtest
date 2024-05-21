use scheduler::scheduler_server::Scheduler;
use tonic::{transport::Uri, Code};

pub mod scheduler {
    tonic::include_proto!("scheduler");
}

pub mod greenlight {
    tonic::include_proto!("greenlight");
}

#[derive(Debug)]
pub struct DockerScheduler {
    node_grpc_uri: Uri,
}

impl DockerScheduler {
    pub fn new(node_grpc_uri: Uri) -> Self {
        DockerScheduler { node_grpc_uri }
    }

    fn node_info(&self, node_id: Vec<u8>) -> scheduler::NodeInfoResponse {
        scheduler::NodeInfoResponse {
            node_id,
            grpc_uri: self.node_grpc_uri.to_string(),
            session_id: 0,
        }
    }
}

#[tonic::async_trait]
impl Scheduler for DockerScheduler {
    async fn register(
        &self,
        request: tonic::Request<scheduler::RegistrationRequest>,
    ) -> std::result::Result<tonic::Response<scheduler::RegistrationResponse>, tonic::Status> {
        if &request.into_inner().network != "regtest" {
            return Err(tonic::Status::new(
                Code::FailedPrecondition,
                "only regtest is supported",
            ));
        }

        // Simply always return the same credentials.
        Ok(tonic::Response::new(scheduler::RegistrationResponse {
            creds: (0..31).collect(),
            device_cert: String::from(
                "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
            ),
            device_key: String::from(
                "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
            ),
            rune: String::from("cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"),
        }))
    }

    async fn recover(
        &self,
        _request: tonic::Request<scheduler::RecoveryRequest>,
    ) -> std::result::Result<tonic::Response<scheduler::RecoveryResponse>, tonic::Status> {
        Ok(tonic::Response::new(scheduler::RecoveryResponse {
            creds: (0..31).collect(),
            device_cert: String::from(
                "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
            ),
            device_key: String::from(
                "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
            ),
            rune: String::from("cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"),
        }))
    }

    async fn get_challenge(
        &self,
        _request: tonic::Request<scheduler::ChallengeRequest>,
    ) -> std::result::Result<tonic::Response<scheduler::ChallengeResponse>, tonic::Status> {
        Ok(tonic::Response::new(scheduler::ChallengeResponse {
            challenge: (0..31).collect(),
        }))
    }

    async fn schedule(
        &self,
        request: tonic::Request<scheduler::ScheduleRequest>,
    ) -> std::result::Result<tonic::Response<scheduler::NodeInfoResponse>, tonic::Status> {
        Ok(tonic::Response::new(
            self.node_info(request.into_inner().node_id),
        ))
    }

    async fn get_node_info(
        &self,
        request: tonic::Request<scheduler::NodeInfoRequest>,
    ) -> std::result::Result<tonic::Response<scheduler::NodeInfoResponse>, tonic::Status> {
        Ok(tonic::Response::new(
            self.node_info(request.into_inner().node_id),
        ))
    }

    async fn maybe_upgrade(
        &self,
        request: tonic::Request<scheduler::UpgradeRequest>,
    ) -> std::result::Result<tonic::Response<scheduler::UpgradeResponse>, tonic::Status> {
        Ok(tonic::Response::new(scheduler::UpgradeResponse {
            old_version: request.into_inner().signer_version,
        }))
    }

    async fn list_invite_codes(
        &self,
        _request: tonic::Request<scheduler::ListInviteCodesRequest>,
    ) -> std::result::Result<tonic::Response<scheduler::ListInviteCodesResponse>, tonic::Status>
    {
        Ok(tonic::Response::new(scheduler::ListInviteCodesResponse {
            invite_code_list: vec![],
        }))
    }

    async fn export_node(
        &self,
        _request: tonic::Request<scheduler::ExportNodeRequest>,
    ) -> std::result::Result<tonic::Response<scheduler::ExportNodeResponse>, tonic::Status> {
        Err(tonic::Status::unimplemented("not implemented"))
    }

    async fn add_outgoing_webhook(
        &self,
        _request: tonic::Request<scheduler::AddOutgoingWebhookRequest>,
    ) -> std::result::Result<tonic::Response<scheduler::AddOutgoingWebhookResponse>, tonic::Status>
    {
        Err(tonic::Status::unimplemented("not implemented"))
    }

    async fn list_outgoing_webhooks(
        &self,
        _request: tonic::Request<scheduler::ListOutgoingWebhooksRequest>,
    ) -> std::result::Result<tonic::Response<scheduler::ListOutgoingWebhooksResponse>, tonic::Status>
    {
        Err(tonic::Status::unimplemented("not implemented"))
    }

    async fn delete_webhooks(
        &self,
        _request: tonic::Request<scheduler::DeleteOutgoingWebhooksRequest>,
    ) -> std::result::Result<tonic::Response<greenlight::Empty>, tonic::Status> {
        Err(tonic::Status::unimplemented("not implemented"))
    }

    async fn rotate_outgoing_webhook_secret(
        &self,
        _request: tonic::Request<scheduler::RotateOutgoingWebhookSecretRequest>,
    ) -> std::result::Result<tonic::Response<scheduler::WebhookSecretResponse>, tonic::Status> {
        Err(tonic::Status::unimplemented("not implemented"))
    }
}
