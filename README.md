# databases-project

Team Members: Qiran Kong, Aryan Rao, Neil Pandya (contributions in [`docs/contributions.md`](docs/contributions.md))

Polyglot e-commerce backend: MySQL, MongoDB, Redis, and Neo4j sharing the same `user_id` and `product_id` values.

## Products and versions

| Store | Product | Version | Role |
|---|---|---|---|
| Relational | MySQL | 8.0 | users, catalog, products, variants, inventory, carts, orders, payments, shipments, returns |
| Document | MongoDB | 7.0 | specific product attributes, behavior events |
| Key-value | Redis | 7.2 | sessions, hot carts, recently viewed, live stock counters |
| Graph | Neo4j | 5.20 | user/product/category relationships |

## Layout

- `schema/` — DDL and structures for each database
- `generator/` — synthetic data generation
- `loaders/` — load generated data into each database
- `queries/` — the Part 2 queries, one folder for each
- `perf/` — timing and execution-plan results
- `docs/` — design docs, revision log, contributions, citations
- `report/` — final PDF report

## Setup

### 1. Python virtual environment

Create the environment once, from the repo root:

```bash
python3 -m venv .venv

source .venv/bin/activate        # Linux / macOS / WSL
.venv\Scripts\Activate.ps1       # Windows PowerShell

pip install -r requirements.txt
```

To activate later:

```bash
source .venv/bin/activate        # Linux / macOS / WSL
.venv\Scripts\Activate.ps1       # Windows PowerShell
```

Leave the environment with `deactivate`.

### 2. Configure and start the databases

1. `cp .env.example .env` and set the secrets in `.env` (gitignored, never commit it)
2. `docker compose up -d`

MySQL runs the `.sql` files in `schema/mysql/` only the first time it starts with an empty volume. After changing the DDL, reset with:

```bash
docker compose down -v
```

This deletes all loaded data, so reload afterward.

### 3. Generate, load, query

TODO: fill in as each piece is implemented.

3. Generate data: TODO
4. Load data: TODO
5. Run queries: TODO
6. Run performance evaluation: TODO
