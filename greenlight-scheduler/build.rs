fn main() -> Result<(), Box<dyn std::error::Error>> {
    tonic_build::compile_protos("src/proto/greenlight.proto")?;
    tonic_build::compile_protos("src/proto/scheduler.proto")?;
    Ok(())
}
