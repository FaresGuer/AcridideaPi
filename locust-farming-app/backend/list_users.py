import pymysql

try:
    connection = pymysql.connect(
        host='localhost',
        user='root',
        password='',
        database='locust_farm'
    )
    with connection.cursor(pymysql.cursors.DictCursor) as cursor:
        cursor.execute("SELECT email FROM users LIMIT 10")
        users = cursor.fetchall()
        print(f"EXISTING_USERS:{users}")
    connection.close()
except Exception as e:
    print(f"Database error: {e}")
