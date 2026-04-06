import mysql.connector
from mysql.connector import Error
from config.settings import MYSQL_DATABASE, MYSQL_HOST, MYSQL_PASSWORD, MYSQL_PORT, MYSQL_USER


def get_connection():
    try:
        connection = mysql.connector.connect(
            host=MYSQL_HOST,
            port=MYSQL_PORT,
            user=MYSQL_USER,
            password=MYSQL_PASSWORD,
            database=MYSQL_DATABASE,
        )
        if connection.is_connected():
            return connection
    except Error as error:
        print(f"Erro ao conectar no MySQL: {error}")
        return None
