# Revision Log

| # | Date | Component | Change | Rationale |
|---|---|---|---|---|
| 1 | 2026-11-11 | Relational schema (MySQL) + ERD | Initial version: 17 tables covering users, addresses, payment methods, categories, products, variants (per-variant stock), carts, orders, payments, shipments, returns, refunds. | Keep SQL as source of truth for transactional data; share `user_id`/`product_id`/`variant_id` with other stores; composite FKs and CHECKs keep orders, payments and returns consistent. |
