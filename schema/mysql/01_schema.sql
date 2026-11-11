CREATE TABLE users (
    user_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE addresses (
    address_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    line1 VARCHAR(255) NOT NULL,
    line2 VARCHAR(255) NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100) NULL,
    postal_code VARCHAR(20) NOT NULL,
    country_code CHAR(2) NOT NULL
);

CREATE TABLE user_addresses (
    user_address_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    address_id BIGINT NOT NULL,
    is_default BOOLEAN NOT NULL DEFAULT FALSE,

    UNIQUE KEY uq_user_addresses_user_address (user_id, address_id),
    UNIQUE KEY uq_user_addresses_one_default ((CASE WHEN is_default THEN user_id END)),
    KEY ix_user_addresses_address (address_id),
    CONSTRAINT fk_user_addresses_user FOREIGN KEY (user_id) REFERENCES users (user_id),
    CONSTRAINT fk_user_addresses_address FOREIGN KEY (address_id) REFERENCES addresses (address_id)
);

CREATE TABLE payment_methods (
    payment_method_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    method_type ENUM('credit_card','debit_card','bank_account') NOT NULL,
    provider VARCHAR(50) NOT NULL,
    provider_token VARCHAR(255) NOT NULL,
    last4 CHAR(4) NOT NULL CONSTRAINT ck_payment_methods_last4 CHECK (last4 REGEXP '^[0-9]{4}$'),
    brand VARCHAR(50) NULL,
    exp_month TINYINT NULL CONSTRAINT ck_payment_methods_exp_month CHECK (exp_month IS NULL OR exp_month BETWEEN 1 AND 12),
    exp_year SMALLINT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    UNIQUE KEY uq_payment_methods_method_user (payment_method_id, user_id),
    KEY ix_payment_methods_user (user_id),
    CONSTRAINT fk_payment_methods_user FOREIGN KEY (user_id) REFERENCES users (user_id)
);

CREATE TABLE categories (
    category_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    parent_category_id INT NULL,
    name VARCHAR(100) NOT NULL UNIQUE,

    KEY ix_categories_parent (parent_category_id),
    CONSTRAINT fk_categories_parent FOREIGN KEY (parent_category_id) REFERENCES categories (category_id)
);

CREATE TABLE products (
    product_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    category_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT NULL,
    brand VARCHAR(100) NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    KEY ix_products_category (category_id),
    CONSTRAINT fk_products_category FOREIGN KEY (category_id) REFERENCES categories (category_id)
);

CREATE TABLE product_variants (
    variant_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    product_id BIGINT NOT NULL,
    sku VARCHAR(64) NOT NULL UNIQUE,
    price DECIMAL(12,2) NOT NULL CONSTRAINT ck_variants_price CHECK (price >= 0),
    restocking_fee DECIMAL(12,2) NOT NULL DEFAULT 0 CONSTRAINT ck_variants_restock CHECK (restocking_fee >= 0),
    size VARCHAR(30) NOT NULL DEFAULT '',
    color VARCHAR(30) NOT NULL DEFAULT '',
    quantity_on_hand INT NOT NULL DEFAULT 0 CONSTRAINT ck_variants_on_hand CHECK (quantity_on_hand >= 0),
    quantity_reserved INT NOT NULL DEFAULT 0,
    quantity_available INT GENERATED ALWAYS AS (quantity_on_hand - quantity_reserved) STORED,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    UNIQUE KEY uq_variants_product_size_color (product_id, size, color),
    KEY ix_variants_available (quantity_available),
    KEY ix_variants_color (color),
    KEY ix_variants_size (size),
    CONSTRAINT fk_variants_product FOREIGN KEY (product_id) REFERENCES products (product_id),
    CONSTRAINT ck_variants_reserved CHECK (quantity_reserved >= 0 AND quantity_reserved <= quantity_on_hand)
);

CREATE TABLE carts (
    cart_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    status ENUM('active','converted','abandoned') NOT NULL DEFAULT 'active',
    last_device_type VARCHAR(20) NOT NULL CONSTRAINT ck_carts_device CHECK (last_device_type IN ('laptop','tablet','phone')),
    last_session_id VARCHAR(64) NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY uq_carts_cart_user (cart_id, user_id),
    UNIQUE KEY uq_carts_one_active ((CASE WHEN status = 'active' THEN user_id END)),
    KEY ix_carts_user (user_id),
    KEY ix_carts_status (status),
    KEY ix_carts_created_at (created_at),
    CONSTRAINT fk_carts_user FOREIGN KEY (user_id) REFERENCES users (user_id)
);

CREATE TABLE cart_items (
    cart_variant_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    cart_id BIGINT NOT NULL,
    variant_id BIGINT NOT NULL,
    quantity INT NOT NULL CONSTRAINT ck_cart_items_quantity CHECK (quantity > 0),
    unit_price DECIMAL(12,2) NOT NULL CONSTRAINT ck_cart_items_unit_price CHECK (unit_price >= 0),
    added_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    UNIQUE KEY uq_cart_items_cart_variant (cart_id, variant_id),
    KEY ix_cart_items_variant (variant_id),
    CONSTRAINT fk_cart_items_cart FOREIGN KEY (cart_id) REFERENCES carts (cart_id) ON DELETE CASCADE,
    CONSTRAINT fk_cart_items_variant FOREIGN KEY (variant_id) REFERENCES product_variants (variant_id)
);

CREATE TABLE shipping_options (
    shipping_option_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    base_fee DECIMAL(12,2) NOT NULL CONSTRAINT ck_shipping_options_fee CHECK (base_fee >= 0),
    est_days_min TINYINT NOT NULL,
    est_days_max TINYINT NOT NULL,

    CONSTRAINT ck_shipping_options_days CHECK (est_days_min >= 0 AND est_days_min <= est_days_max)
);

CREATE TABLE orders (
    order_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    cart_id BIGINT NOT NULL UNIQUE,
    user_address_id BIGINT NOT NULL,
    shipping_option_id INT NOT NULL,
    status ENUM('pending','paid','shipped','delivered','cancelled') NOT NULL DEFAULT 'pending',
    subtotal DECIMAL(12,2) NOT NULL,
    tax_amount DECIMAL(12,2) NOT NULL,
    shipping_fee DECIMAL(12,2) NOT NULL,
    total_amount DECIMAL(12,2) NOT NULL,
    placed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expected_delivery_date DATE NULL,

    CONSTRAINT fk_orders_cart_user FOREIGN KEY (cart_id, user_id) REFERENCES carts (cart_id, user_id),
    CONSTRAINT fk_orders_user_address FOREIGN KEY (user_address_id) REFERENCES user_addresses (user_address_id),
    CONSTRAINT fk_orders_shipping_option FOREIGN KEY (shipping_option_id) REFERENCES shipping_options (shipping_option_id),
    UNIQUE KEY uq_orders_order_user (order_id, user_id),
    KEY ix_orders_user_placed (user_id, placed_at),
    KEY ix_orders_user_address (user_address_id),
    KEY ix_orders_shipping_option (shipping_option_id),
    CONSTRAINT ck_orders_amounts CHECK (subtotal >= 0 AND tax_amount >= 0 AND shipping_fee >= 0 AND total_amount = subtotal + tax_amount + shipping_fee)
);

CREATE TABLE order_items (
    order_item_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT NOT NULL,
    variant_id BIGINT NOT NULL,
    quantity INT NOT NULL CONSTRAINT ck_order_items_quantity CHECK (quantity > 0),
    unit_price DECIMAL(12,2) NOT NULL CONSTRAINT ck_order_items_unit_price CHECK (unit_price >= 0),
    returned_quantity INT NOT NULL DEFAULT 0,

    UNIQUE KEY uq_order_items_item_order (order_item_id, order_id),
    KEY ix_order_items_order (order_id),
    KEY ix_order_items_variant_order (variant_id, order_id),
    CONSTRAINT fk_order_items_order FOREIGN KEY (order_id) REFERENCES orders (order_id),
    CONSTRAINT fk_order_items_variant FOREIGN KEY (variant_id) REFERENCES product_variants (variant_id),
    CONSTRAINT ck_order_items_returned CHECK (returned_quantity >= 0 AND returned_quantity <= quantity)
);

CREATE TABLE payments (
    payment_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    payment_method_id BIGINT NOT NULL,
    status ENUM('authorized','captured','failed') NOT NULL,
    amount DECIMAL(12,2) NOT NULL CONSTRAINT ck_payments_amount CHECK (amount >= 0),
    refunded_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    provider_txn_id VARCHAR(100) NULL UNIQUE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    UNIQUE KEY uq_payments_payment_order (payment_id, order_id),
    KEY ix_payments_order_user (order_id, user_id),
    KEY ix_payments_method_user (payment_method_id, user_id),
    CONSTRAINT fk_payments_order_user FOREIGN KEY (order_id, user_id) REFERENCES orders (order_id, user_id),
    CONSTRAINT fk_payments_method_user FOREIGN KEY (payment_method_id, user_id) REFERENCES payment_methods (payment_method_id, user_id),
    CONSTRAINT ck_payments_refunded CHECK (refunded_amount >= 0 AND refunded_amount <= amount)
);

CREATE TABLE shipments (
    shipment_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT NOT NULL,
    carrier VARCHAR(50) NOT NULL,
    tracking_number VARCHAR(100) NULL,
    status ENUM('label_created','in_transit','delivered') NOT NULL DEFAULT 'label_created',
    shipped_at DATETIME NULL,
    delivered_at DATETIME NULL,

    KEY ix_shipments_order (order_id),
    CONSTRAINT fk_shipments_order FOREIGN KEY (order_id) REFERENCES orders (order_id)
);

CREATE TABLE returns (
    return_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT NOT NULL,
    status ENUM('requested','label_issued','in_transit','received','completed','rejected') NOT NULL DEFAULT 'requested',
    return_carrier VARCHAR(50) NULL,
    return_tracking_number VARCHAR(100) NULL,
    requested_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at DATETIME NULL,

    UNIQUE KEY uq_returns_return_order (return_id, order_id),
    KEY ix_returns_order (order_id),
    CONSTRAINT fk_returns_order FOREIGN KEY (order_id) REFERENCES orders (order_id)
);

CREATE TABLE return_items (
    return_item_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    return_id BIGINT NOT NULL,
    order_id BIGINT NOT NULL,
    order_item_id BIGINT NOT NULL,
    quantity INT NOT NULL CONSTRAINT ck_return_items_quantity CHECK (quantity > 0),
    reason VARCHAR(255) NULL,
    resolution ENUM('refund','exchange') NOT NULL,
    exchange_variant_id BIGINT NULL,
    restocking_fee DECIMAL(12,2) NOT NULL DEFAULT 0,
    refund_amount DECIMAL(12,2) NOT NULL DEFAULT 0,

    UNIQUE KEY uq_return_items_return_item (return_id, order_item_id),
    KEY ix_return_items_order_item (order_item_id, order_id),
    KEY ix_return_items_return_order (return_id, order_id),
    KEY ix_return_items_exchange_variant (exchange_variant_id),
    CONSTRAINT fk_return_items_return FOREIGN KEY (return_id, order_id) REFERENCES returns (return_id, order_id),
    CONSTRAINT fk_return_items_order_item FOREIGN KEY (order_item_id, order_id) REFERENCES order_items (order_item_id, order_id),
    CONSTRAINT fk_return_items_exchange_variant FOREIGN KEY (exchange_variant_id) REFERENCES product_variants (variant_id),
    CONSTRAINT ck_return_items_amounts CHECK (restocking_fee >= 0 AND refund_amount >= 0),
    CONSTRAINT ck_return_items_exchange CHECK ((resolution = 'exchange') = (exchange_variant_id IS NOT NULL))
);

CREATE TABLE refunds (
    refund_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT NOT NULL,
    payment_id BIGINT NOT NULL,
    return_id BIGINT NOT NULL,
    amount DECIMAL(12,2) NOT NULL CONSTRAINT ck_refunds_amount CHECK (amount >= 0),
    status ENUM('pending','completed','failed') NOT NULL DEFAULT 'pending',
    provider_refund_id VARCHAR(100) NULL UNIQUE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at DATETIME NULL,

    KEY ix_refunds_payment_order (payment_id, order_id),
    KEY ix_refunds_return_order (return_id, order_id),
    CONSTRAINT fk_refunds_payment_order FOREIGN KEY (payment_id, order_id) REFERENCES payments (payment_id, order_id),
    CONSTRAINT fk_refunds_return_order FOREIGN KEY (return_id, order_id) REFERENCES returns (return_id, order_id)
);
