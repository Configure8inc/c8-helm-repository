# Snowflake Privilege Management Script

## Requirements

- Python 3
- pip and virtualenv

Install the necessary Python packages using pip within a virtual environment:

```bash
python -m venv env
source env/bin/activate  # For Unix-like OS
env\Scripts\activate  # For Windows
pip install snowflake-connector-python loguru
```

## Parameters

- `--account`: Specifies the name of your Snowflake account. This is a mandatory parameter.
- `--username`: Your Snowflake user login name. This is required to authenticate your session.
- `--password`: The password associated with the specified username. It is required for authentication purposes.
- `--role`: Identifies the Snowflake role to which the script will grant access. This parameter is required.
- `--database`: The name of the database where the script will apply the privileges. This is a required parameter.
- `--warehouse`: Specifies the Snowflake warehouse to be used during the session. This is necessary for resource allocation and is a required parameter.

```bash
python3 sf.py \
    --account='' \
    --username='' \
    --password='' \
    --database='' \
    --warehouse='' \
    --role=''
```
