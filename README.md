# PayRoute — High-Availability Payment Router

A portfolio-grade Haskell/Servant payment-routing service with PostgreSQL persistence,
Redis-backed gateway health, Kafka event publishing, deterministic failover routing,
Prometheus metrics, Docker Compose, Nix development support, Hspec and QuickCheck tests,
and a GitLab CI pipeline.

## Architecture
- Haskell + Servant: HTTP API
- Beam + PostgreSQL: payment records
- Redis: gateway success-rate/health state
- Kafka: payment routing events
- Prometheus: latency/request metrics
- Grafana: local dashboard provisioning
- Docker Compose: local infrastructure
- Nix: reproducible development shell

## Run
1. Copy `.env.example` to `.env`.
2. `docker compose up --build`
3. API: `http://localhost:8080`
4. Metrics: `http://localhost:8080/metrics`
5. Prometheus: `http://localhost:9090`
6. Grafana: `http://localhost:3000` (`admin` / `admin`)

The service gracefully falls back to an in-memory gateway state when Redis/Kafka/PostgreSQL
are unavailable, which keeps the demo runnable while preserving production-oriented boundaries.

## API
- `GET /health`
- `GET /gateways`
- `POST /payments`
- `GET /payments/:id`

Example:
```json
POST /payments
{
  "merchantId": "merchant-01",
  "amount": 1250,
  "currency": "INR",
  "method": "UPI"
}
```

## Tests
```bash
cabal test
```

The test suite includes routing properties and deterministic failover behavior.
