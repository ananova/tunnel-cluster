# Tunnel Cluster

A tool for managing database tunnels and ECS container shell access across multiple environments. Includes a web UI for convenient management of database tunnels.

## Features

- Visual interface for all configured database environments
- Start/stop tunnels with a single click
- Real-time status indicators
- Auto-refresh capability
- Organized by service groups
- Clean, modern interface

## Setup

1. Install dependencies:
   ```bash
   npm install
   ```

2. Ensure you have the required prerequisites:
   - AWS CLI installed and configured
   - aws-vault installed
   - AWS Session Manager plugin installed
   - Valid AWS credentials for your environments
   - `config.json` file in the project root

3. Start the server:
   ```bash
   npm start
   ```

4. Open your browser to:
   ```
   http://localhost:31415
   ```

## Configuration

Create a `config.json` file in the project root. This file defines base AWS configurations and individual environments.

### Example Configuration

```json
{
  "base_configs": {
    "production_account": {
      "aws_profile": "developer@production",
      "aws_region": "us-east-1",
      "rds_endpoint": "abc123.us-east-1.rds.amazonaws.com"
    },
    "staging_account": {
      "aws_profile": "developer@staging",
      "aws_region": "ap-southeast-2",
      "rds_endpoint": "xyz789.ap-southeast-2.rds.amazonaws.com"
    }
  },
  "environments": {
    "my-service-production": {
      "extends": "production_account",
      "cluster": "my_ecs_cluster",
      "service": "my_service_web",
      "container": "app",
      "db_prefix": "my-service-db-cluster",
      "local_port": 15432
    },
    "my-service-staging": {
      "extends": "staging_account",
      "cluster": "staging_ecs_cluster",
      "service": "my_service_web",
      "container": "app",
      "db_prefix": "my-service-db-cluster",
      "local_port": 15433
    },
    "another-service-production": {
      "extends": "production_account",
      "cluster": "my_ecs_cluster",
      "service": "another_service_web",
      "container": "app",
      "db_host": "custom-db.example.com",
      "local_port": 15434
    }
  }
}
```

### Configuration Fields

**Base Configs:**
- `aws_profile`: AWS profile name (used with aws-vault)
- `aws_region`: AWS region for the infrastructure
- `rds_endpoint`: RDS cluster endpoint

**Environments:**
- `extends`: References a base config to inherit from
- `cluster`: ECS cluster name
- `service`: ECS service name
- `container`: Container name within the service
- `db_prefix`: Optional database cluster name prefix (auto-constructs full RDS endpoint). If not specified, auto-generated from environment name by removing `-production` or `-staging` suffix and appending `-db-cluster`
- `db_host`: Optional explicit database host (overrides db_prefix). Use this for custom database hostnames
- `local_port`: Local port to bind the tunnel to (must be unique per environment)

## Usage

### Starting a Tunnel

1. Find the environment you want to connect to
2. Click the "Start Tunnel" button
3. Wait for the status to change to "Running"
4. Connect to the database using `localhost` and the displayed local port

### Stopping a Tunnel

1. Find the running environment
2. Click the "Stop Tunnel" button
3. The tunnel will be terminated (equivalent to Ctrl-C in terminal)

### Auto-Refresh

Toggle the "Auto-refresh" switch to automatically update tunnel statuses periodically.

### Shell Access (Command Line Only)

The web UI manages database tunnels only. For interactive shell access to ECS containers, use the command line:

```bash
./tunnel_cluster <environment-name> shell
```

This opens an interactive bash shell inside the ECS container for the specified environment. Useful for debugging, running rake tasks, or inspecting the container environment.

Example:
```bash
./tunnel_cluster my-service-production shell
```

Press Ctrl-D or type `exit` to close the shell session.

## API Endpoints

The server exposes the following REST API endpoints:

- `GET /api/environments` - List all environments with their status
- `POST /api/tunnels/:environment/start` - Start a tunnel
- `POST /api/tunnels/:environment/stop` - Stop a tunnel
- `GET /api/tunnels/:environment/status` - Get tunnel status
- `GET /api/tunnels/:environment/logs` - Get tunnel logs

## Architecture

- **Backend**: Node.js + Express server
- **Frontend**: Vanilla HTML/CSS/JavaScript
- **Process Management**: Node.js child_process for spawning tunnel_cluster scripts

Environments are automatically read from `config.json` and grouped by service for easy navigation in the UI.

## Development

Run in development mode with auto-restart:
```bash
npm run dev
```

## Troubleshooting

- If a tunnel fails to start, check the browser console for error messages
- Ensure your AWS credentials are valid and not expired
- Verify that aws-vault is properly configured
- Check that the tunnel_cluster script has execute permissions

## Shutting Down

Press Ctrl-C in the terminal to stop the server. All active tunnels will be automatically terminated.