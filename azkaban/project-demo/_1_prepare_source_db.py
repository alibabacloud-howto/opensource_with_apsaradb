import psycopg2
import sys

con = None

try:

    conn = psycopg2.connect(database='northwind_source',
                            user='demo',
                            password='N1cetest',
                            host='pgm-3ns1uqdq892od196168190.pg.rds.aliyuncs.com',
                            port='5432')
    conn.set_isolation_level(psycopg2.extensions.ISOLATION_LEVEL_AUTOCOMMIT)
    cur = conn.cursor()
    cur.execute(open("northwind_ddl.sql", "r").read())
    cur.execute(open("northwind_data_source.sql", "r").read())

except psycopg2.DatabaseError as e:

    print(f'Error {e}')
    sys.exit(1)

finally:

    if conn:
        conn.close()
