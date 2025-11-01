# Refactor: Pass deployment token via environment variable

This PR refactors the deployment token handling to eliminate file-based secret storage.

## Changes
- Removed `local.secret_path` from locals block (no longer needed)
- Consolidated three `local-exec` provisioners into a single one
- Pass deployment token directly via Docker's `-e DEPLOYMENT_TOKEN` flag
- Token is referenced from environment variable instead of file

## Benefits
- **Better Security**: Deployment token never written to filesystem
- **Cleaner Code**: Reduced from 3 provisioners to 1
- **Same Functionality**: Maintains identical deployment behavior

## Testing
Please test the deployment in your environment to ensure the StaticSitesClient correctly receives the token via the environment variable.