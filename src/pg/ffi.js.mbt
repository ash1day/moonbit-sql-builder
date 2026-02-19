/// Opaque handle to a pg Client instance
type PgClient

/// Create a new pg Client with a connection string
extern "js" fn js_create_client(url : String) -> PgClient =
  #| (url) => {
  #|   const { Client } = require('pg');
  #|   return new Client({ connectionString: url });
  #| }

/// Connect the client (async)
extern "js" fn js_connect_client(client : PgClient) -> @js_async.Promise[Unit] =
  #| (client) => client.connect()

/// Execute a parameterized query, returning rows as JSON string (async)
extern "js" fn js_query_raw(
  client : PgClient,
  sql : String,
  params : Array[String],
) -> @js_async.Promise[String] =
  #| (client, sql, params) => client.query(sql, params).then((result) => JSON.stringify(result.rows))

/// Disconnect the client (async)
extern "js" fn js_end_client(client : PgClient) -> @js_async.Promise[Unit] =
  #| (client) => client.end()
