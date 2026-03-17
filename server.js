const express = require('express');
const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = 31415;

app.use(express.json());
app.use(express.static('public'));

const activeTunnels = new Map();

function loadConfig() {
  const configPath = path.join(__dirname, 'config.json');
  const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));

  const environments = [];
  for (const [name, env] of Object.entries(config.environments)) {
    const baseConfig = config.base_configs[env.extends];
    environments.push({
      name,
      service: env.service,
      taskFamily: env.task_family,
      dbHost: env.db_host,
      localPort: env.local_port,
      awsProfile: baseConfig.aws_profile,
      region: baseConfig.aws_region,
      cluster: env.cluster
    });
  }

  environments.sort((a, b) => a.name.localeCompare(b.name));

  return environments;
}

app.get('/api/environments', (req, res) => {
  try {
    const environments = loadConfig();
    const withStatus = environments.map(env => ({
      ...env,
      status: activeTunnels.has(env.name) ? 'running' : 'stopped'
    }));
    res.json(withStatus);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/tunnels/:environment/start', (req, res) => {
  const environment = req.params.environment;

  if (activeTunnels.has(environment)) {
    return res.status(400).json({ error: 'Tunnel already running' });
  }

  const tunnelScript = path.join(__dirname, 'tunnel_cluster');

  const process = spawn(tunnelScript, [environment, 'db'], {
    cwd: __dirname,
    stdio: ['ignore', 'pipe', 'pipe']
  });

  let output = '';
  let errorOutput = '';

  process.stdout.on('data', (data) => {
    output += data.toString();
    console.log(`[${environment}] ${data.toString().trim()}`);
  });

  process.stderr.on('data', (data) => {
    errorOutput += data.toString();
    console.error(`[${environment}] ERROR: ${data.toString().trim()}`);
  });

  process.on('exit', (code, signal) => {
    console.log(`[${environment}] Process exited with code ${code}, signal ${signal}`);
    activeTunnels.delete(environment);
  });

  process.on('error', (error) => {
    console.error(`[${environment}] Failed to start: ${error.message}`);
    activeTunnels.delete(environment);
  });

  activeTunnels.set(environment, {
    process,
    startTime: new Date(),
    output,
    errorOutput
  });

  res.json({
    success: true,
    message: `Tunnel started for ${environment}`,
    pid: process.pid
  });
});

app.post('/api/tunnels/:environment/stop', (req, res) => {
  const environment = req.params.environment;

  if (!activeTunnels.has(environment)) {
    return res.status(404).json({ error: 'Tunnel not running' });
  }

  const tunnel = activeTunnels.get(environment);

  tunnel.process.kill('SIGTERM');

  setTimeout(() => {
    if (activeTunnels.has(environment)) {
      tunnel.process.kill('SIGKILL');
    }
  }, 5000);

  activeTunnels.delete(environment);

  res.json({
    success: true,
    message: `Tunnel stopped for ${environment}`
  });
});

app.get('/api/tunnels/:environment/status', (req, res) => {
  const environment = req.params.environment;
  const isRunning = activeTunnels.has(environment);

  if (isRunning) {
    const tunnel = activeTunnels.get(environment);
    res.json({
      status: 'running',
      startTime: tunnel.startTime,
      pid: tunnel.process.pid
    });
  } else {
    res.json({
      status: 'stopped'
    });
  }
});

app.get('/api/tunnels/:environment/logs', (req, res) => {
  const environment = req.params.environment;

  if (!activeTunnels.has(environment)) {
    return res.status(404).json({ error: 'Tunnel not running' });
  }

  const tunnel = activeTunnels.get(environment);
  res.json({
    output: tunnel.output,
    errorOutput: tunnel.errorOutput
  });
});

process.on('SIGTERM', () => {
  console.log('Shutting down server...');
  for (const [name, tunnel] of activeTunnels.entries()) {
    console.log(`Stopping tunnel: ${name}`);
    tunnel.process.kill('SIGTERM');
  }
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('\nShutting down server...');
  for (const [name, tunnel] of activeTunnels.entries()) {
    console.log(`Stopping tunnel: ${name}`);
    tunnel.process.kill('SIGTERM');
  }
  process.exit(0);
});

app.listen(PORT, () => {
  console.log(`Tunnel Manager UI running at http://localhost:${PORT}`);
  console.log(`API available at http://localhost:${PORT}/api`);
});