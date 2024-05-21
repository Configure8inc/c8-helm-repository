#!/usr/bin/env python3

import loguru
import os
import argparse
import snowflake.connector
from snowflake.connector import DictCursor
from snowflake.connector.errors import DatabaseError, ProgrammingError
import time

logger = loguru.logger


def _parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--account", type=str, required=True, help="Snowflake account.")
    parser.add_argument(
        "--username", type=str, required=True, help="Snowflake username."
    )
    parser.add_argument("--role", type=str, required=True, help="Snowflake role.")
    parser.add_argument(
        "--password", type=str, required=True, help="Snowflake password."
    )
    parser.add_argument(
        "--database", type=str, required=True, help="Snowflake database."
    )
    parser.add_argument(
        "--warehouse", type=str, required=True, help="Snowflake warehouse."
    )

    return parser.parse_args()


def add_database_privileges(con, role, database):
    database_privileges = {
        f"{role}": "USAGE, CREATE SCHEMA",
    }

    database_privileges_future = {
        "FUTURE SCHEMAS": {"OWNERSHIP", "CREATE TABLE", "MODIFY", "USAGE"},
        "FUTURE TABLES": {"OWNERSHIP", "DELETE", "INSERT", "SELECT", "UPDATE"},
        "FUTURE STAGES": {"OWNERSHIP", "USAGE"},
    }

    try:
        for role, permission in database_privileges.items():
            try:
                logger.info(
                    f'Granting {permission} to "{role}" on database {database}.'
                )
                con.cursor().execute(
                    f'grant {permission} on database {database} to role "{role}";'
                ).fetchall()
            except Exception as e:
                logger.error(f"Programming error: {e}")
                raise

        for permission, actions in database_privileges_future.items():
            logger.info(f"permission: {permission}, actions: {actions};")
            for action in actions:
                logger.info(f"action: {action};")
                try:
                    logger.info(
                        f"GRANT {action} ON {permission} IN DATABASE {database};"
                    )
                    con.cursor().execute(
                        f"GRANT {action} ON {permission} IN DATABASE {database} TO ROLE {role};"
                    )

                except Exception as e:
                    logger.error(f"Programming error: {e}")

        while not test_database_access(con, database):
            logger.info(f"Checking database {database} access.")
            logger.info(f"Waiting for database {database} to be created.")
            time.sleep(5)

        public_schema_privileges_ownership = {
            "FUTURE TABLES": f"{role}",
            "FUTURE STAGES": f"{role}",
        }
        public_schema_privileges = {
            f"{role}": "CREATE TABLE, MODIFY, USAGE, CREATE STAGE, APPLYBUDGET, CREATE ALERT, CREATE DYNAMIC TABLE, CREATE EVENT TABLE, CREATE EXTERNAL TABLE, CREATE FILE FORMAT, CREATE FUNCTION, CREATE ICEBERG TABLE, CREATE NETWORK RULE, CREATE PACKAGES POLICY, CREATE PASSWORD POLICY, CREATE PIPE, CREATE PROCEDURE, CREATE RESOURCE GROUP, CREATE SECRET, CREATE SEQUENCE, CREATE SESSION POLICY, CREATE SNOWFLAKE.CORE.BUDGET, CREATE SNOWFLAKE.ML.ANOMALY_DETECTION, CREATE SNOWFLAKE.ML.FORECAST, CREATE STAGE, CREATE STREAM, CREATE STREAMLIT, CREATE TABLE, CREATE TASK, CREATE TEMPORARY TABLE, CREATE VIEW, MONITOR",
        }

        for role, permission in public_schema_privileges.items():
            try:
                logger.info(
                    f'GRANT {permission} ON SCHEMA {database}.PUBLIC ROLE "{role}";'
                )
                con.cursor().execute(
                    f'GRANT {permission} ON SCHEMA {database}.PUBLIC TO ROLE "{role}";'
                )

            except Exception as e:
                logger.error(f"Programming error: {e}")
                raise

        for permission, role in public_schema_privileges_ownership.items():
            try:
                logger.info(
                    f'GRANT OWNERSHIP ON {permission} IN SCHEMA {database}.PUBLIC TO ROLE "{role}" COPY CURRENT GRANTS;'
                )
                con.cursor().execute(
                    f'GRANT OWNERSHIP ON {permission} IN SCHEMA {database}.PUBLIC TO ROLE "{role}" COPY CURRENT GRANTS;'
                )

            except Exception as e:
                logger.error(f"Programming error: {e}")

    except ProgrammingError as e:
        if e.errno == 2002:
            logger.info(f"Database {database} already exists. Exiting.")
        else:
            logger.error(f"Programming error: {e.errno}")
            raise


def test_database_access(con, database_name):
    try:
        cursor = con.cursor()
        cursor.execute(f"SHOW SCHEMAS IN DATABASE {database_name};")

        return True
    except Exception as e:
        print(f"Failed to access database {database_name}: {str(e)}")
        return False


def main():
    # Establish Snowflake connection
    try:
        connection = snowflake.connector.connect(
            user=ARGS.username,
            password=ARGS.password,
            account=ARGS.account,
            warehouse=ARGS.warehouse,
            database=ARGS.database,
        )
    except DatabaseError as e:
        if e.errno == 250001:
            logger.error(f"Invalid username/password provided.")
            logger.error(e)
        else:
            raise
    except Exception as ex:
        logger.error(f"Exception occurred: {ex}.")
        raise

    add_database_privileges(connection, ARGS.role, ARGS.database)

    connection.close()


if __name__ == "__main__":
    logger.info("App started.")
    ARGS = _parse_args()
    main()
    logger.info("App completed.")
