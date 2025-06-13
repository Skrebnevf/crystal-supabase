require "http/client"
require "./query"
require "./types"

class Supabase::Client
  property url : String
  property api_key : String

  @version = "/rest/v1/"

  # Creates a new Supabase client
  #
  # Raises `ArgumentError` if `url` or `api_key` is empty.
  def initialize(@url : String, @api_key : String)
    if @url.empty? || @api_key.empty?
      raise ArgumentError.new("url or api key must not be empty")
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
  # Raises `ArgumentError` if table name is empty.
  #
  # ```
  # query = client.from("users")
  # ```
  def from(table : String) : Query
    raise ArgumentError.new("table must be not empty") if table.empty?
    Query.new(self, table)
  end

  # Execute a RPC request
  #
  # Returns response body as `String`
  # Raises error if request fails.
  # response = client.rpc("hello_world")
  # puts response
  def rpc(rpc : String) : String
    url = "#{@url}#{@version}rpc/#{rpc}"

    response = HTTP::Client.post(url, headers)
    if response.status.success?
      response.body
    else
      error = ExecuteError.from_json(response.body)
      raise error_msg(error)
    end
  end

  # Executes a SELECT query
  #
  # Returns response body as `String`
  # Raises error if request fails.
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
  def select(query : Query) : String | ExecuteError
    query_str = "select=#{query.select_fields}"
    query_str += "&#{query.conditions.join("&")}" unless query.conditions.empty?
    url = "#{@url}#{@version}#{query.table}?#{query_str}"

    response = HTTP::Client.get(url, headers: headers)
    if response.status.success?
      response.body
    else
      error = ExecuteError.from_json(response.body)
      raise error_msg(error)
    end
  end

  # Executes an INSERT query with the given JSON payload
  #
  # Returns response body as `String`
  # Raises error if request fails.
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
    url = "#{@url}#{@version}#{query.table}"

    response = HTTP::Client.post(url, headers: headers, body: payload)

    if response.status.success?
      response.body
    else
      error = ExecuteError.from_json(response.body)
      raise error_msg(error)
    end
  end

  # Executes an UPSERT query with conflict resolution on specified columns
  #
  # Returns response body as `String`
  # Raises error if request fails.
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
  def upsert(query : Query, payload : String, on_conflict : Array(String))
    merge = headers.clone
    merge["Prefer"] = "resolution=merge-duplicates"
    conflict_col = on_conflict.join(",")
    url = "#{@url}#{@version}#{query.table}?on_conflict=#{conflict_col}"

    response = HTTP::Client.post(url, headers: merge, body: payload)

    if response.status.success?
      response.body
    else
      error = ExecuteError.from_json(response.body)
      raise error_msg(error)
    end
  end

  # Executes an UPDATE query with the given JSON payload
  #
  # Returns response body as `String`
  # Raises error if request fails.
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
    url = "#{@url}#{@version}#{query.table}"
    url += "?#{query.conditions.join("&")}" unless query.conditions.empty?

    response = HTTP::Client.patch(url, headers: headers, body: payload)

    if response.status.success?
      response.body
    else
      error = ExecuteError.from_json(response.body)
      raise error_msg(error)
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
    url = "#{@url}#{@version}#{query.table}"
    url += "?#{query.conditions.join("&")}" unless query.conditions.empty?

    response = HTTP::Client.delete(url, headers: headers)

    if response.status.success?
      response.body
    else
      error = ExecuteError.from_json(response.body)
      raise error_msg(error)
    end
  end

  private def error_msg(error : ExecuteError)
    error_msg = <<-MESSAGE
    SELECT query faild
      Message: #{error.message}
      Hint: #{error.hint}
      Details: #{error.details}
      Code: #{error.code}
    MESSAGE
  end
end
