# Tunnel Cluster Manager

A web-based UI for managing AWS RDS database tunnels across multiple environments.

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

Toggle the "Auto-refresh" switch to automatically update tunnel statuses every 3 seconds.

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