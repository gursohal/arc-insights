"""
Database connection management for ARCL Insights API
Uses connection pooling for efficient PostgreSQL access under load.
"""

import os
import psycopg2
import psycopg2.extras
import psycopg2.pool
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")

# Connection pool: min 1 connection, max 10 connections
# Lazy-initialized on first use
_pool = None


def _get_pool():
    """Get or create the connection pool (lazy init)."""
    global _pool
    if _pool is None or _pool.closed:
        _pool = psycopg2.pool.ThreadedConnectionPool(
            minconn=1,
            maxconn=10,
            dsn=DATABASE_URL,
        )
    return _pool


def get_connection():
    """Get a PostgreSQL connection from the pool."""
    return _get_pool().getconn()


def put_connection(conn):
    """Return a connection to the pool."""
    try:
        _get_pool().putconn(conn)
    except Exception:
        # If pool is closed or conn is bad, just close it
        try:
            conn.close()
        except Exception:
            pass


def execute_query(query: str, params=None):
    """Execute a query and return all results."""
    conn = get_connection()
    try:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(query, params)
            return cur.fetchall()
    finally:
        put_connection(conn)


def execute_one(query: str, params=None):
    """Execute a query and return one result."""
    conn = get_connection()
    try:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(query, params)
            return cur.fetchone()
    finally:
        put_connection(conn)
