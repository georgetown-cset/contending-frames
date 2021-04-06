"""Some wrappers around the BQ client for Python.
Reference: https://googleapis.dev/python/bigquery/latest/index.html
"""
import warnings
from pathlib import Path
from typing import Union, Optional

import google.auth
from google.cloud import bigquery
from google.cloud.bigquery.job import QueryJob
from google.oauth2 import service_account

from settings import PROJECT_ID, SQL_DIR, DATASET_ID

_client = None
_credentials = None


def create_client(key_path: Optional[str] = None) -> bigquery.Client:
    """Create BQ API Client.
    :return: BQ API Client.
    """
    global _client, _credentials
    with warnings.catch_warnings():
        warnings.filterwarnings('ignore', message='Your application has authenticated using end user credentials')
        if key_path is not None:
            _credentials = service_account.Credentials.from_service_account_file(
                key_path, scopes=["https://www.googleapis.com/auth/cloud-platform"],
            )
        elif _credentials is None:
            _credentials, _ = google.auth.default()
        if _client is None:
            _client = bigquery.Client(project=PROJECT_ID, credentials=_credentials)
    return _client


def write_query(sql: Union[str, Path],
                table: str,
                dataset=DATASET_ID,
                clobber=False,
                **config_kw) -> QueryJob:
    """Run a query and write the result to a BigQuery table.
    :param sql: Query SQL as text or a :class:`pathlib.Path` to a SQL file.
    :param table: Destination table.
    :param dataset: Destination dataset.
    :param clobber: If ``True``, overwrite the destination table if it exists.
    :param config_kw: Passed to :class:`bigquery.QueryJobConfig`.
    :return: Completed QueryJob.
    :raises: :class:`google.api_core.exceptions.GoogleAPICallError` if the request is unsuccessful .
    """
    if isinstance(sql, Path):
        sql = sql.read_text()
    _client = create_client()
    destination_id = f'{PROJECT_ID}.{dataset}.{table}'
    print(f'Writing {dataset}.{table}')
    config = bigquery.QueryJobConfig(destination=destination_id,
                                     write_disposition='WRITE_TRUNCATE' if clobber else 'WRITE_EMPTY',
                                     use_legacy_sql=False,
                                     **config_kw)
    job = _client.query(sql, job_config=config)
    # Wait for job to finish, or raise an error if unsuccessful
    _ = job.result()
    return job


def read_sql(filename: Union[str, Path]) -> str:
    """
    Read SQL file from the `./sql` directory.
    :param filename: Filename.
    :return: File text.
    """
    return Path(SQL_DIR, filename).with_suffix('.sql').read_text()


def make_table(table: str, clobber=False, **kw) -> QueryJob:
    """
    Just a wrapper around read_sql() + write_query().

    Run a query defined in a SQL file, and write the result to a BQ table of the same name as the SQL file.
    :param table: Table name.
    :param clobber: If ``True``, overwrite the table if it exists.
    :return: Completed QueryJob.
    """
    job = write_query(read_sql(table), table, clobber=clobber, **kw)
    return job
