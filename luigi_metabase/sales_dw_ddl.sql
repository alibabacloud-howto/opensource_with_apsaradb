DROP TABLE IF EXISTS association_rules;
DROP TABLE IF EXISTS product_info;
DROP TABLE IF EXISTS invoice;
DROP TABLE IF EXISTS customer_info;
DROP TABLE IF EXISTS invoice_time;
DROP TABLE IF EXISTS invoice_outliers;


-- Table: Association Rules
CREATE TABLE association_rules (
    antecedants Text,
    consequents Text,
    antecedent_support Float,
    consequent_support Float,
    support Float,
    confidence Float,
    lift Float,
    leverage Float,
    conviction Float
);

-- Table: Product Info
CREATE TABLE product_info (
    stock_code Text,
    description Text,
    unit_price Float
);

-- Table: Invoice
CREATE TABLE invoice (
    invoice_no Text,
    stock_code Text,
    quantity Integer,
    invoice_date Text,
    customer_id Integer
);

-- Table: Customer Info
CREATE TABLE customer_info (
    customer_id Integer,
    country Text,
    country_code Text
);

-- Table: Invoice Time
CREATE TABLE invoice_time (
    invoice_date Text,
    dayofweek Integer,
    year Integer,
    month Text,
    day Integer,
    hour Integer,
    minute Integer,
    dayofyear Integer,
    weekofyear Integer,
    quarter Integer
);

-- Table: Invoice Outliers
CREATE TABLE invoice_outliers (
    invoice_no Text,
    stock_code Text,
    quantity Integer,
    invoice_date Text,
    customer_id Integer
);