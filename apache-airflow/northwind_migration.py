from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.postgres_operator import PostgresOperator
from airflow.hooks.postgres_hook import PostgresHook
dag_params = {
    'dag_id': 'northwind_migration',
    'start_date':datetime(2021, 8, 24),
    'schedule_interval': timedelta(seconds=60)
}
with DAG(**dag_params) as dag:
    src = PostgresHook(postgres_conn_id='northwind_source')
    dest = PostgresHook(postgres_conn_id='northwind_target')
    src_conn = src.get_conn()
    cursor = src_conn.cursor()
    dest_conn = dest.get_conn()
    dest_cursor = dest_conn.cursor()
    dest_cursor.execute("SELECT MAX(product_id) FROM products;")
    product_id = dest_cursor.fetchone()[0]
    if product_id is None:
        product_id = 0
    cursor.execute("SELECT * FROM products WHERE product_id > %s", [product_id])
    dest.insert_rows(table="products", rows=cursor)
    dest_cursor.execute("SELECT MAX(order_id) FROM orders;")
    order_id = dest_cursor.fetchone()[0]
    if order_id is None:
        order_id = 0
    cursor.execute("SELECT * FROM orders WHERE order_id > %s", [order_id])
    dest.insert_rows(table="orders", rows=cursor)