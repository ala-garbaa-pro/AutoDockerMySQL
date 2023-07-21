# Database Management Shell Script

This is a shell script that allows you to perform various actions on a database using automation with Docker. The script provides an easy-to-use command-line interface to interact with the database.

## Prerequisites

Before running this script, ensure that you have Docker installed on your system and the necessary Docker images or containers for the database you want to manage.

## Usage

To use this script, follow the instructions below:

```bash
./database.sh [ACTION] [PATH]
```

Replace `[ACTION]` with one of the following options:

- `c` or `create`: Create a new database.
- `e` or `export`: Export the database.
- `i` or `import`: Import the database from the file specified in `[PATH]`.
- `d` or `delete`: Delete an existing database.
- `r` or `recreate`: Delete the existing database and create a new one.
- `p` or `print_uri`: Print the database URI.
- `ch` or `check`: Check the database connection.

## Actions

### Create a New Database

To create a new database, run the following command:

```bash
./database.sh create
```

### Export the Database

To export the database, use the following command:

```bash
./database.sh export
```

### Import the Database

To import the database from a specific file, provide the file `PATH` as follows:

```bash
./database.sh import PATH
```

Replace `PATH` with the path to the file containing the database you want to import.

### Delete an Existing Database

To delete an existing database, use the following command:

```bash
./database.sh delete
```

### Delete and Recreate Database

To delete the existing database and create a new one, use the following command:

```bash
./database.sh recreate
```

### Print Database URI

To print the database URI, use the following command:

```bash
./database.sh print_uri
```

### Check Database Connection

To check the database connection, use the following command:

```bash
./database.sh check
```

## Examples

1. Create a new database:

```bash
./database.sh create
```

2. Export the database:

```bash
./database.sh export
```

3. Import the database from a file:

```bash
./database.sh import /path/to/database_file.sql
```

4. Delete an existing database:

```bash
./database.sh delete
```

5. Delete the existing database and create a new one:

```bash
./database.sh recreate
```

6. Print the database URI:

```bash
./database.sh print_uri
```

7. Check the database connection:

```bash
./database.sh check
```

## Note

- Make sure to adjust the script according to your specific database configuration and Docker setup.
- Use the script at your own risk, and ensure you have proper backups before performing any destructive actions.

If you have any questions or face issues, feel free to contact me. 

Happy database management! 😄