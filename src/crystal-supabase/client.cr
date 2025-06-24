require "http/client"
require "./query"
require "./types"
require "json"
require "./client_builder.cr"

class Supabase::Client < Supabase::ClientBuilder
  property url : String
  property api_key : String

  @version = "/rest/v1/"

  # Creates a new Supabase client
  #
  # Raises `ArgumentError` if `url` or `api_key` is empty.
  def initialize(@url : String, @api_key : String)
    if @url.empty? || @api_key.empty?
      raise ArgumentError.new "url or api key must not be empty"
    end
  end

  def headers : HTTP::Headers
    HTTP::Headers{
      "apikey"        => api_key,
      "Authorization" => "Bearer #{api_key}",
      "Accept"        => "application/json",
      "Content-Type"  => "application/json",
      "Prefer"        => "return=representation",
    }
  end

  # Initializes a query for the given table
  #
  # Raises `ArgumentError` if table name is empty
  #
  # ```
  # query = client.from("users")
  # ```
  def from(table : String) : Query
    raise ArgumentError.new "table must be not empty" if table.strip.empty?
    Query.new(self, table)
  end

  # Execute a RPC request
  # Argument rpc - name of supabase function
  #
  # Returns response body as `String`
  # Raises error if request fails
  # Raises error if argument is empty
  #
  # response = client.rpc("hello_world")
  # puts response
  def rpc(rpc : String) : String
    raise ArgumentError.new "rpc must not be empty" if rpc.strip.empty?

    endpoints = "#{@version}rpc/#{rpc}"
    with_http_client @url do |client|
      response = client.post(endpoints, headers: headers)
      return response.body if response.status.success?
      error = ExecuteError.from_json response.body
      raise error_msg("SELECT", error)
    end
  end

  # Executes a SELECT query
  #
  # Returns response body as `String`
  # Raises error if request fails
  #
  # Example:
  # ```
  # response = client
  #   .from("users")
  #   .select("*")
  #   .eq("active", "true")
  #   .execute
  # puts response
  # ```
  def select(query : Query) : String
    query_str = "select=#{query.select_fields}"
    query_str += "&#{query.conditions.join("&")}" unless query.conditions.empty?
    endpoints = "#{@version}#{query.table}?#{query_str}"

    with_http_client @url do |client|
      response = client.get(endpoints, headers: headers)
      return response.body if response.status.success?
      error = ExecuteError.from_json response.body
      raise error_msg("SELECT", error)
    end
  end

  # Executes an INSERT query with the given JSON payload
  #
  # Returns response body as `String`
  # Raises error if request fails
  # Raises error if payload is empty
  #
  #
  # Example:
  # ```
  # payload = %({"name": "Alice", "age": 30})
  # response = client
  #   .from("users")
  #   .insert(payload)
  #   .execute
  # puts response
  #
  # Bulk insert
  # payload = %([
  #   {"id": 1, "name": "Bob"},
  #   {"id": 2, "name": "Charlie"}
  # ])
  # response = client
  #   .from("users")
  #   .insert(payload)
  #   .execute
  # puts response
  # ```
  def insert(query : Query, payload : String) : String
    raise ArgumentError.new "payload must not be empty" if payload.strip.empty?

    endpoints = "#{@version}#{query.table}"
    response_body = with_http_client @url do |client|
      response = client.post(endpoints, headers: headers, body: payload)
      return response.body if response.status.success?
      error = ExecuteError.from_json response.body
      raise error_msg("INSERT", error)
    end
  end

  # Executes an UPSERT query with conflict resolution on specified columns
  #
  # Returns response body as `String`
  # Raises error if request fails
  # Raises error if arguments is empty
  # Raises error if on_conflict has dupblicetes
  #
  #
  # Example:
  # ```
  # payload = %({"id": 1, "name": "Bob"})
  # response = client
  #   .from("users")
  #   .upsert(payload, ["id"])
  #   .execute
  # puts response
  #
  # Bulk upsert
  # payload = %([
  #   {"id": 1, "name": "Bob"},
  #   {"id": 2, "name": "Charlie"}
  # ])
  # response = client
  #   .from("users")
  #   .upsert(payload, ["id"])
  #   .execute
  # puts response
  # ```
  def upsert(query : Query, payload : String, on_conflict : Array(String)) : String
    raise ArgumentError.new "payload must not be empty" if payload.strip.empty?
    raise ArgumentError.new "on_conflict must not be empty" if on_conflict.empty?
    raise ArgumentError.new "duplicate fields in on_conflict" unless on_conflict.uniq.size == on_conflict.size

    merge = headers.clone
    merge["Prefer"] = "resolution=merge-duplicates"
    conflict_col = on_conflict.join(",")
    endpoints = "#{@version}#{query.table}?on_conflict=#{conflict_col}"

    response_body = with_http_client @url do |client|
      response = client.post(endpoints, headers: merge, body: payload)
      return response.body if response.status.success?
      error = ExecuteError.from_json response.body
      raise error_msg("UPSERT", error)
    end
  end

  # Executes an UPDATE query with the given JSON payload
  #
  # Returns response body as `String`
  # Raises error if request fails
  # Raises error if payload argument is empty
  #
  #
  # Example:
  # ```
  # payload = %({"name": "Charlie"})
  # response = client
  #   .from("users")
  #   .eq("id", "1")
  #   .update(payload)
  #   .execute
  # puts response
  # ```
  def update(query : Query, payload : String) : String
    raise ArgumentError.new "payload must not be empty" if payload.strip.empty?

    endpoints = "#{@version}#{query.table}"
    endpoints += "?#{query.conditions.join("&")}" unless query.conditions.empty?

    response_body = with_http_client @url do |client|
      response = client.patch(endpoints, headers: headers, body: payload)
      return response.body if response.status.success?
      error = ExecuteError.from_json response.body
      raise error_msg("UPDATE", error)
    end
  end

  # Executes a DELETE query
  #
  # Returns response body as `String`
  # Raises error if request fails.
  #
  #
  # Example:
  # ```
  # response = client
  #   .from("users")
  #   .eq("id", "1")
  #   .delete
  #
  # Bulk delete
  # response = client
  #   .from("users")
  #   .in_("id", [1, 2])
  #   .delete()
  #   .execute
  # puts response
  # ```
  def delete(query : Query) : String
    endpoints = "#{@url}#{@version}#{query.table}"
    endpoints += "?#{query.conditions.join("&")}" unless query.conditions.empty?

    response_body = with_http_client @url do |client|
      response = client.delete(endpoints, headers: headers)
      return response.body if response.status.success?
      error = ExecuteError.from_json response.body
      raise error_msg("DELETE", error)
    end
  end

  private def error_msg(method : String, error : ExecuteError)
    error_msg = <<-MESSAGE
    #{method} query faild
      Message: #{error.message}
      Hint: #{error.hint}
      Details: #{error.details}
      Code: #{error.code}
    MESSAGE
  end
end
