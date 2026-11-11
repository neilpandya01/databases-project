# Relational ERD — Draft 1

```mermaid
erDiagram
    USERS ||--o{ USER_ADDRESSES : "has"
    ADDRESSES ||--o{ USER_ADDRESSES : "shared by"
    USERS ||--o{ PAYMENT_METHODS : "saves"
    USERS ||--o{ CARTS : "owns"
    USERS ||--o{ ORDERS : "places"

    CATEGORIES |o--o{ CATEGORIES : "parent of"
    CATEGORIES ||--o{ PRODUCTS : "classifies"
    PRODUCTS ||--|{ PRODUCT_VARIANTS : "has"

    CARTS ||--o{ CART_ITEMS : "contains"
    PRODUCT_VARIANTS ||--o{ CART_ITEMS : "added as"

    USER_ADDRESSES ||--o{ ORDERS : "ships to"
    SHIPPING_OPTIONS ||--o{ ORDERS : "chosen for"
    CARTS ||--o| ORDERS : "converts to"
    ORDERS ||--|{ ORDER_ITEMS : "contains"
    PRODUCT_VARIANTS ||--o{ ORDER_ITEMS : "purchased as"

    ORDERS ||--o{ PAYMENTS : "paid by"
    PAYMENT_METHODS ||--o{ PAYMENTS : "used for"
    ORDERS ||--o{ SHIPMENTS : "fulfilled by"

    ORDERS ||--o{ RETURNS : "may have"
    RETURNS ||--|{ RETURN_ITEMS : "contains"
    ORDER_ITEMS ||--o{ RETURN_ITEMS : "returned as"
    PRODUCT_VARIANTS |o--o{ RETURN_ITEMS : "exchange for"

    PAYMENTS ||--o{ REFUNDS : "refunded by"
    RETURNS ||--o{ REFUNDS : "triggers"

    USERS {
        BIGINT user_id PK
        VARCHAR(255) email UK
        VARCHAR(255) password_hash
        VARCHAR(100) first_name
        VARCHAR(100) last_name
        DATETIME created_at
    }

    ADDRESSES {
        BIGINT address_id PK
        VARCHAR(255) line1
        VARCHAR(255) line2
        VARCHAR(100) city
        VARCHAR(100) state
        VARCHAR(20) postal_code
        CHAR(2) country_code
    }

    USER_ADDRESSES {
        BIGINT user_address_id PK
        BIGINT user_id FK "UK with address_id"
        BIGINT address_id FK "UK with user_id"
        BOOLEAN is_default
    }

    PAYMENT_METHODS {
        BIGINT payment_method_id PK "UK with user_id"
        BIGINT user_id FK
        ENUM method_type "credit_card, debit_card, bank_account"
        VARCHAR(50) provider
        VARCHAR(255) provider_token
        CHAR(4) last4
        VARCHAR(50) brand
        TINYINT exp_month
        SMALLINT exp_year
        DATETIME created_at
    }

    CATEGORIES {
        INT category_id PK
        INT parent_category_id FK
        VARCHAR(100) name UK
    }

    PRODUCTS {
        BIGINT product_id PK
        INT category_id FK
        VARCHAR(255) name
        TEXT description
        VARCHAR(100) brand
        BOOLEAN is_active
        DATETIME created_at
    }

    PRODUCT_VARIANTS {
        BIGINT variant_id PK
        BIGINT product_id FK
        VARCHAR(64) sku UK
        DECIMAL price
        DECIMAL restocking_fee
        VARCHAR(30) size "UK with product_id and color"
        VARCHAR(30) color "UK with product_id and size"
        INT quantity_on_hand
        INT quantity_reserved
        INT quantity_available
        BOOLEAN is_active
    }

    CARTS {
        BIGINT cart_id PK
        BIGINT user_id FK
        ENUM status "active, converted, abandoned"
        VARCHAR(20) last_device_type "laptop, tablet, phone"
        VARCHAR(64) last_session_id
        DATETIME created_at
        DATETIME updated_at
    }

    CART_ITEMS {
        BIGINT cart_variant_id PK
        BIGINT cart_id FK "UK with variant_id"
        BIGINT variant_id FK "UK with cart_id"
        INT quantity
        DECIMAL unit_price
        DATETIME added_at
    }

    SHIPPING_OPTIONS {
        INT shipping_option_id PK
        VARCHAR(50) name
        DECIMAL base_fee
        TINYINT est_days_min
        TINYINT est_days_max
    }

    ORDERS {
        BIGINT order_id PK "UK with user_id"
        BIGINT user_id FK
        BIGINT cart_id FK "UK"
        BIGINT user_address_id FK
        INT shipping_option_id FK
        ENUM status "pending, paid, shipped, delivered, cancelled"
        DECIMAL subtotal
        DECIMAL tax_amount
        DECIMAL shipping_fee
        DECIMAL total_amount
        DATETIME placed_at
        DATE expected_delivery_date
    }

    ORDER_ITEMS {
        BIGINT order_item_id PK
        BIGINT order_id FK
        BIGINT variant_id FK
        INT quantity
        DECIMAL unit_price
        INT returned_quantity
    }

    PAYMENTS {
        BIGINT payment_id PK "UK with order_id"
        BIGINT order_id FK
        BIGINT user_id FK
        BIGINT payment_method_id FK
        ENUM status "authorized, captured, failed"
        DECIMAL amount
        DECIMAL refunded_amount
        VARCHAR(100) provider_txn_id UK
        DATETIME created_at
    }

    REFUNDS {
        BIGINT refund_id PK
        BIGINT order_id FK
        BIGINT payment_id FK
        BIGINT return_id FK
        DECIMAL amount
        ENUM status "pending, completed, failed"
        VARCHAR(100) provider_refund_id UK
        DATETIME created_at
        DATETIME completed_at
    }

    SHIPMENTS {
        BIGINT shipment_id PK
        BIGINT order_id FK
        VARCHAR(50) carrier
        VARCHAR(100) tracking_number
        ENUM status "label_created, in_transit, delivered"
        DATETIME shipped_at
        DATETIME delivered_at
    }

    RETURNS {
        BIGINT return_id PK
        BIGINT order_id FK "UK with return_id"
        ENUM status "requested, label_issued, in_transit, received, completed, rejected"
        VARCHAR(50) return_carrier
        VARCHAR(100) return_tracking_number
        DATETIME requested_at
        DATETIME completed_at
    }

    RETURN_ITEMS {
        BIGINT return_item_id PK
        BIGINT return_id FK "UK with order_item_id"
        BIGINT order_id FK
        BIGINT order_item_id FK "UK with return_id"
        INT quantity
        VARCHAR(255) reason
        ENUM resolution "refund, exchange"
        BIGINT exchange_variant_id FK
        DECIMAL restocking_fee
        DECIMAL refund_amount
    }
```

## Design notes

- **Data types**: every `DECIMAL` is `DECIMAL(12,2)`. `quantity_available` is a stored generated column (`quantity_on_hand - quantity_reserved`).
- **Products** hold common columns only. Category-specific attributes live in MongoDB, keyed by `product_id`. Every product has at least one variant, and `size` / `color` are `NOT NULL` with `''` meaning "not applicable".
- **Inventory** is per variant (`quantity_on_hand`, `quantity_reserved`).
- **Carts**: at most one `active` cart per user. Every order comes from exactly one cart.
- **Addresses**: many-to-many with users through `user_addresses`. `is_default` is per user.
- **Payments** store only a provider token, `last4`, `brand` and expiry. `refunds` is a separate ledger, one row per refund event.
- **Returns** are per order item (`return_items`). `return_items.order_id` is denormalized so composite FKs keep a return inside its own order.
