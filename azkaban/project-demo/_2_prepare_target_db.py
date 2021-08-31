import psycopg2
import sys

con = None

try:

    conn = psycopg2.connect(database='northwind_target',
                            user='demo',
                            password='N1cetest',
                            host='pgm-xxxx.pg.rds.aliyuncs.com',
                            port='1921')
    conn.set_isolation_level(psycopg2.extensions.ISOLATION_LEVEL_AUTOCOMMIT)
    cur = conn.cursor()
    cur.execute(open("northwind_ddl.sql", "r").read())
    cur.execute(open("northwind_data_target.sql", "r").read())

except psycopg2.DatabaseError as e:

    print(f'Error {e}')
    sys.exit(1)

finally:

    if conn:
        conn.close()
