import mysql.connector
from mysql.connector import errorcode

config = {
    'user': 'root',
    'password': 'senha123',
    'host': 'localhost'
}

DB_NAME = 'harmocrew'

TABLES = {}
TABLES['users'] = (
    "CREATE TABLE IF NOT EXISTS users ("
    "  id INT AUTO_INCREMENT PRIMARY KEY,"
    "  nome VARCHAR(255) NOT NULL,"
    "  email VARCHAR(255) NOT NULL UNIQUE,"
    "  senha VARCHAR(255) NOT NULL"
    ") ENGINE=InnoDB"
)

TABLES['posts'] = (
    "CREATE TABLE IF NOT EXISTS posts ("
    "  id INT AUTO_INCREMENT PRIMARY KEY,"
    "  user_id INT NOT NULL,"
    "  texto TEXT NOT NULL,"
    "  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,"
    "  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE"
    ") ENGINE=InnoDB"
)

TABLES['candidaturas'] = (
    "CREATE TABLE IF NOT EXISTS candidaturas ("
    "  id INT AUTO_INCREMENT PRIMARY KEY,"
    "  user_id INT NOT NULL,"
    "  post_id INT NOT NULL,"
    "  data TIMESTAMP DEFAULT CURRENT_TIMESTAMP,"
    "  status VARCHAR(20) DEFAULT 'pendente',"
    "  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,"
    "  FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,"
    "  UNIQUE KEY unique_candidate (user_id, post_id)"
    ") ENGINE=InnoDB"
)

def init_db():
    try:
        conn = mysql.connector.connect(**config)
        cursor = conn.cursor()

        try:
            cursor.execute(f"CREATE DATABASE IF NOT EXISTS {DB_NAME} DEFAULT CHARACTER SET 'utf8'")
        except mysql.connector.Error as err:
            print(f"Erro ao criar o banco de dados: {err}")
            return

        conn.database = DB_NAME

        for table_name in TABLES:
            table_description = TABLES[table_name]
            try:
                cursor.execute(table_description)
            except mysql.connector.Error as err:
                print(f"Erro ao criar tabela {table_name}: {err}")

        cursor.close()
        conn.close()
        print("Banco de dados e tabelas verificados/criados com sucesso.")

    except mysql.connector.Error as err:
        print(f"Erro ao conectar no MySQL: {err}")
