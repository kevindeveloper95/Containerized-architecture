from flask import Flask, jsonify, request
import mysql.connector
from flask_cors import CORS
import json
import boto3


# Get MySQL credentials from AWS Secrets Manager
def get_mysql_databse_secrets() -> str:

    session = boto3.Session()
    client = session.client(service_name="secretsmanager", region_name="INSERT-REGION-HERE")
    get_secret_value_response = client.get_secret_value(SecretId = "YOUR-SECRET-ID")
    SecretString = json.loads(get_secret_value_response["SecretString"])
    DESTINATION_DB_HOST = SecretString["host"]
    DESTINATION_DB_USERNAME= SecretString["username"]
    DESTINATION_DB_PASSWORD = SecretString["password"]
    DESTINATION_DATABASE = SecretString["dbname"]
    DESTINATION_DB_PORT = SecretString["port"]

    return [DESTINATION_DB_HOST, DESTINATION_DB_USERNAME, DESTINATION_DB_PASSWORD , DESTINATION_DATABASE, DESTINATION_DB_PORT]

# Flask App Setup
app = Flask(__name__)

CORS(app, resources={r"/*": {"origins": "*"}})

secrets = get_mysql_databse_secrets() 

# Initialize database connection
connection = mysql.connector.connect(
    host=secrets[0] ,
    user=secrets[1],
    password=secrets[2],
    database=secrets[3],
    port=secrets[4],
    autocommit=True
)
cursor = connection.cursor()

# Create the recipes table if it doesn't exist

query = """
CREATE TABLE IF NOT EXISTS recipes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    recipe_name VARCHAR(255) NOT NULL,
    description_main TEXT,
    description_nutrition TEXT,
    ingredients TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
"""
cursor.execute(query)
connection.commit()

# Function to check and reconnect the MySQL connection
def check_and_reconnect():
    global connection, cursor
    try:
        connection.ping(reconnect=True, attempts=3, delay=2)
    except mysql.connector.Error as err:
        print("Error: Reconnecting to the database.")
        connection = mysql.connector.connect(
            host=secrets[0] ,
            user=secrets[1],
            password=secrets[2],
            database=secrets[3],
            port=secrets[4],
            autocommit=True
        )
        cursor = connection.cursor()

# Routes
@app.route('/api/get_recipe', methods=['GET'])
def get_recipes():
    check_and_reconnect()
    query = "SELECT * FROM recipes ORDER BY id DESC;"
    cursor.execute(query)
    rows = cursor.fetchall()
    recipes = []
    for row in rows:

        recipe = {
                'name': row[1],
                'recipe': row[3],
                'ingredients':[row[6]] ,
                'description': {
                    'main': row[4],
                    'nutrition': row[5]  # Add real data if available
                }
            }
        
        recipes.append(recipe)
    return jsonify(recipes)

# API to insert a new recipe
@app.route('/api/add_recipe', methods=['POST'])
def add_recipe():
    check_and_reconnect()
    data = request.get_json()
    name = data.get('name')
    email = data.get('email')
    recipe_name = data.get('recipe_name')
    description_main = data.get('description_main')
    description_nutrition = data.get('description_nutrition')
    ingredients = data.get('ingredients')

    query = """
        INSERT INTO recipes (name, email, recipe_name, description_main,description_nutrition, ingredients)
        VALUES (%s, %s, %s, %s, %s, %s);
    """
    
    cursor.execute(query, (name, email, recipe_name, description_main, description_nutrition, ingredients))
   
    connection.commit()

    return jsonify({'message': 'Recipe added successfully'}), 201


@app.route('/api/health')
def health_check():
    return 'Healthy', 200


if __name__ == '__main__':
    
    app.run(host='0.0.0.0', port=5000)
