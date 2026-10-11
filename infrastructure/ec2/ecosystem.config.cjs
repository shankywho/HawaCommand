// PM2 processes for a single EC2 host (Amazon Linux / Ubuntu), from the repository root:
//   pm2 start infrastructure/ec2/ecosystem.config.cjs && pm2 save
// Prerequisites: `make install` (creates backend/.venv) and `make frontend` once (builds frontend/.next).
// Settings come from backend/.env (and the Secrets Manager secret named there); AWS credentials come from
// the instance role (hawa-backend-ec2-role), never from files.
const path = require("path");

const root = path.resolve(__dirname, "..", "..");

module.exports = {
  apps: [
    {
      name: "hawa-backend",
      cwd: path.join(root, "backend"),
      script: ".venv/bin/uvicorn",
      args: "hawa_backend.api.app:app --host 0.0.0.0 --port 8000 --proxy-headers --forwarded-allow-ips=*",
      interpreter: "none",
      env: { PYTHONUNBUFFERED: "1" },
      max_memory_restart: "1800M",
    },
    // Kinesis -> live fleet as its own process. Only when HAWA_AWS_KINESIS_CONSUMER=false in backend/.env
    // (the default .env runs the consumer inside hawa-backend); never run both.
    // {
    //   name: "hawa-telemetry-consumer",
    //   cwd: path.join(root, "backend"),
    //   script: ".venv/bin/hawa",
    //   args: "consume-telemetry",
    //   interpreter: "none",
    //   env: { PYTHONUNBUFFERED: "1" },
    //   restart_delay: 5000,
    // },
    {
      name: "hawa-frontend",
      cwd: path.join(root, "frontend"),
      script: "pnpm",
      args: "start",
      interpreter: "none",
    },
    // Optional: the AI-ML engine as its own service on 127.0.0.1:8100 (the backend runs it in process otherwise).
    // {
    //   name: "hawa-aiml",
    //   cwd: path.join(root, "AI-ML"),
    //   script: path.join(root, "backend/.venv/bin/uvicorn"),
    //   args: "hawa_ml.api.main:app --host 127.0.0.1 --port 8100",
    //   interpreter: "none",
    // },
  ],
};
