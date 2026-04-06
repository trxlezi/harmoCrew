import mysql.connector

conn = mysql.connector.connect(user='root', password='', host='localhost', database='harmocrew')
cur = conn.cursor()
cur.execute('SELECT id FROM users')
ids = [row[0] for row in cur.fetchall()]
for user_id in ids:
    url = f'https://i.pravatar.cc/150?u={user_id}'
    cur.execute('UPDATE users SET profile_pic_url = %s WHERE id = %s', (url, user_id))
conn.commit()
cur.close()
conn.close()
print('Atualização concluída.') 