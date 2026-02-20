/// Opaque handle to a pg Client instance
type PgClient

/// Create a new pg Client with a connection string.
/// Also installs a global unhandledRejection handler so that async errors
/// (e.g. query failures that propagate out of `async fn main`) are printed
/// and cause a non-zero exit instead of silently hanging the process.
extern "js" fn js_create_client(url : String) -> PgClient =
  #| (url) => {
  #|   const { Client } = require('pg');
  #|   if (!process._moonbitSqlUnhandledRejectionInstalled) {
  #|     process._moonbitSqlUnhandledRejectionInstalled = true;
  #|     process.on('unhandledRejection', (reason) => {
  #|       const msg = reason instanceof Error ? reason.message : String(reason);
  #|       console.error('FATAL (unhandled async error):', msg);
  #|       process.exit(1);
  #|     });
  #|   }
  #|   return new Client({ connectionString: url });
  #| }

/// Connect the client (async)
extern "js" fn js_connect_client(client : PgClient) -> @js_async.Promise[Unit] =
  #| (client) => client.connect()

/// Execute a parameterized query, returning rows as JSON string (async)
extern "js" fn js_query_raw(
  client : PgClient,
  sql : String,
  params_json : String,
) -> @js_async.Promise[String] =
  #| async function(client, sql, paramsJson) {
  #|   const params = JSON.parse(paramsJson);
  #|   const result = await client.query(sql, params);
  #|   return JSON.stringify(result.rows);
  #| }

/// Disconnect the client (async)
extern "js" fn js_end_client(client : PgClient) -> @js_async.Promise[Unit] =
  #| (client) => client.end()
