DROP TABLE IF EXISTS association_rules;
DROP TABLE IF EXISTS product_info;
DROP TABLE IF EXISTS invoice;
DROP TABLE IF EXISTS customer_info;
DROP TABLE IF EXISTS invoice_time;
DROP TABLE IF EXISTS invoice_outliers;


-- Table: Association Rules
CREATE TABLE association_rules (
    consequent_support Float,
    leverage Float,
    antecedent_support Float,
    conviction Float,
    lift Float,
    antecedants Text,
    confidence Float,
    support Float,
    consequents Text
);


-- Table: Product Info
CREATE TABLE product_info (
    description Text,
    unit_price Float,
    stock_code Text
);

-- Table: Invoice
CREATE TABLE invoice (
    invoice_no Text,
    quantity Integer,
    invoice_date Text,
    customer_id Integer,
    stock_code Text
);

-- Table: Customer Info
CREATE TABLE customer_info (
    customer_id Integer,
    country Text,
    country_code Text
);

-- Table: Invoice Time
CREATE TABLE invoice_time (
    minute Integer,
    year Integer,
    month Text,
    hour Integer,
    dayofyear Integer,
    weekofyear Integer,
    dayofweek Integer,
    day Integer,
    quarter Integer,
    invoice_date Text
);

-- Table: Invoice Outliers
CREATE TABLE invoice_outliers (
    invoice_no Text,
    quantity Integer,
    invoice_date Text,
    customer_id Integer,
    stock_code Text
);