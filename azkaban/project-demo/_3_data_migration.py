import psycopg2
import sys

con = None

try:

    conn_src = psycopg2.connect(database='northwind_source',
                                user='demo',
                                password='N1cetest',
                                host='pgm-xxxx.pg.rds.aliyuncs.com',
                                port='1921')
    conn_src.set_isolation_level(
        psycopg2.extensions.ISOLATION_LEVEL_AUTOCOMMIT)
    cur_src = conn_src.cursor()

    conn_des = psycopg2.connect(database='northwind_target',
                                user='demo',
                                password='N1cetest',
                                host='pgm-xxxx.pg.rds.aliyuncs.com',
                                port='1921')
    conn_des.set_isolation_level(
        psycopg2.extensions.ISOLATION_LEVEL_AUTOCOMMIT)
    cur_des = conn_des.cursor()

    # Keep migrating the incremental data for table: products
    cur_des.execute("SELECT MAX(product_id) FROM products;")
    product_id = cur_des.fetchone()[0]
    if product_id is None:
        product_id = 0
    cur_src.execute(
        "SELECT * FROM products WHERE product_id > %s", [product_id])
    for row in cur_src.fetchall():
        cur_des.execute('INSERT INTO products VALUES %s', (row,))

    # Keep migrating the incremental data for table: orders
    cur_des.execute("SELECT MAX(order_id) FROM orders;")
    order_id = cur_des.fetchone()[0]
    if order_id is None:
        order_id = 0
    cur_src.execute(
        "SELECT * FROM orders WHERE order_id > %s", [order_id])
    for row in cur_src.fetchall():
        cur_des.execute('INSERT INTO orders VALUES %s', (row,))

except psycopg2.DatabaseError as e:

    print(f'Error {e}')
    sys.exit(1)

finally:

    if conn_src:
        conn_src.close()

    if conn_des:
        conn_des.close()
