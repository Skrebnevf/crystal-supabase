require "./client"

class Supabase::Query
  getter table : String
  getter select_fields : String
  getter conditions : Array(String)

  enum Operation
    Select
    Insert
    Update
    Delete
    Upsert
  end

  def initialize(@client : Client, @table : String)
    @conditions = [] of String
    @select_fields = "*"
    @operation = Operation::Select
    @payload = ""
    @on_conflict = [] of String
  end

  # Executes a SELECT query
  #
  # Returns response body as `String`
  # Raises error if request fails.
  #
  # Example:
  # ```
  # response = client
  #    .from("users")
  #    .select("*")
  #    .eq("active", "true")
  #    .execute()
  # puts response 
  #```
  def select(fields : String)
    @select_fields = fields
    @operation = Operation::Select
    self
  end

  # Executes an INSERT query with the given JSON payload
  #
  # Returns response body as `String`
  # Raises error if request fails.
  #
  # TODO: Implement bulk insert for multiple rows
  #
  # Example:
  # ```
  # payload = %({"name": "Alice", "age": 30})
  # response = client
  #   .from("users")
  #   .insert(payload)
  #   .execute()
  # puts response
  # ```
  def insert(payload : String)
    @payload = payload
    @operation = Operation::Insert
    self
  end

  # Executes an UPSERT query with conflict resolution on specified columns
  #
  # Returns response body as `String`
  # Raises error if request fails.
  #
  # TODO: Implement bulk upsert for multiple rows
  #
  # Example:
  # ```
  # payload = %({"id": 1, "name": "Bob"})
  # response = client
  #   .from("users")
  #   .upsert(payload, ["id"])
  #   .execute()
  # puts response
  # ```
  def upsert(payload : String, on_conflict : Array(String))
    @payload = payload
    @on_conflict = on_conflict
    @operation = Operation::Upsert
    self
  end

  # Executes an UPDATE query with the given JSON payload
  #
  # Returns response body as `String`
  # Raises error if request fails.
  #
  # TODO: Consider support for bulk update by primary key
  #
  # Example:
  # ```
  # payload = %({"name": "Charlie"})
  # response = client
  #   .from("users")
  #   .eq("id", "1")
  #   .update(payload)
  #   .execute()
  # puts response
  # ```
  def update(payload : String)
    @payload = payload
    @operation = Operation::Update
    self
  end

  # Executes a DELETE query
  #
  # Returns response body as `String`
  # Raises error if request fails.
  #
  # TODO: Support bulk delete using filters or array of conditions
  #
  # Example:
  # ```
  # response = client
  #   .from("users")
  #   .eq("id", "1")
  #   .delete()
  # puts response
  # ```
  def delete
    @operation = Operation::Delete
    self
  end

  # Adds equality filter: column = value
  #
  # ```
  # response = client
  #   .from("users")
  #   .select("*")
  #   .eq("role", "admin")
  #   .execute()
  # puts response
  # ```
  def eq(column : String, value : String)
    add_filter(column, "eq", value)
  end

  # Adds inequality filter: column != value
  #
  # ```
  # response = client
  #   .from("users")
  #   .select("*")
  #   .neq("status", "inactive")
  #   .execute()
  # puts response
  # ```
  def neq(column : String, value : String)
    add_filter(column, "neq", value)
  end

  # Adds greater than filter: column > value
  #
  # ```
  # response = client
  #   .from("users")
  #   .select("*")
  #   .gt("age", "18")
  #   .execute()
  # puts response
  # ```
  def gt(column : String, value : String)
    add_filter(column, "gt", value)
  end

  # Adds greater than or equal filter: column >= value
  #
  # ```
  # response = client
  #   .from("users")
  #   .select("*")
  #   .gte("score", "70")
  #   .execute()
  # puts response
  # ```
  def gte(column : String, value : String)
    add_filter(column, "gte", value)
  end

  # Adds less than filter: column < value
  #
  # ```
  # response = client
  #   .from("products")
  #   .select("*")
  #   .lt("price", "100")
  #   .execute()
  # puts response
  # ```
  def lt(column : String, value : String)
    add_filter(column, "lt", value)
  end

  # Adds less than or equal filter: column <= value
  #
  # ```
  # response = client
  #   .from("products")
  #   .select("*")
  #   .lte("price", "500")
  #   .execute()
  # puts response
  # ```
  def lte(column : String, value : String)
    add_filter(column, "lte", value)
  end

    #
    # ```
    # response = client
    #   .from("products")
    #   .select("*")
    #   .lte("price", "500")
    #   .execute()
    # puts response
    # ```
  def like(column : String, pattern : String)
    add_filter(column, "like", pattern)
  end

  # Adds ILIKE filter (case-insensitive LIKE)
  #
  # ```
  # response = client
  #   .from("articles")
  #   .select("*")
  #   .ilike("title", "%crystal%")
  #   .execute()
  # puts response
  # ```
  def ilike(column : String, pattern : String)
    add_filter(column, "ilike", pattern)
  end

  # Adds `IN` filter: column IN (values)
  #
  # ```
  # response = client
  #   .from("orders")
  #   .select("*")
  #   .in_("status", ["pending", "shipped"])
  #   .execute()
  # puts response
  # ```
  def in_(column : String, values : Array(String))
    joined = values.join(",")
    @conditions << "#{column}=in.(#{joined})"
    self
  end

  # Adds IS NULL or IS NOT NULL filter
  #
  # ```
  # response = client
  #   .from("profiles")
  #   .select("*")
  #   .is_null("bio", true)
  #   .execute()
  # puts response
  def is_null(column : String, is_null : Bool = true)
    val = is_null ? "is.null" : "not.is.null"
    @conditions << "#{column}=#{val}"
    self
  end

  # Adds NOT operator for custom filters
  #
  # ```
  # response = client
  #   .from("users")
  #   .select("*")
  #   .not("email", "like", "%@test.com")
  #   .execute()
  # puts response
  # ```
  def not(column : String, operator : String, value : String)
    @conditions << "#{column}=not.#{operator}.#{value}"
    self
  end

  # Sorts by column ascending
  #
  # ```
  # response = client
  #   .from("tasks")
  #   .select("*")
  #   .order_asc("created_at")
  #   .execute()
  # puts response
  # ```
  def order_asc(column : String)
    @conditions << "order=#{column}.asc"
    self
  end

  # Sorts by column descending
  #
  # ```
  # response = client
  #   .from("tasks")
  #   .select("*")
  #   .order_desc("created_at")
  #   .execute()
  # puts response
  # ```
  def order_desc(column : String)
    @conditions << "order=#{column}.desc"
    self
  end

  # Limits number of returned rows
  #
  # ```
  # response = client
  #   .from("logs")
  #   .select("*")
  #   .limit(10)
  #   .execute()
  # puts response
  # ```
  def limit(count : Int32)
    @conditions << "limit=#{count}"
    self
  end

  # Skips number of rows (offset)
  #
  # ```
  # response = client
  #   .from("logs")
  #   .select("*")
  #   .offset(20)
  #   .limit(10)
  #   .execute()
  # puts response
  # ```
  def offset(count : Int32)
    @conditions << "offset=#{count}"
    self
  end

  # Executes the current query on Supabase based on the operation type:
  # SELECT, INSERT, UPDATE, UPSERT, or DELETE.
  #
  # Returns the response body as a `String`.
  # Raises an error if the request fails.
  def execute : String
    case @operation
    when .select?
      @client.select(self)
    when .insert?
      @client.insert(self, @payload)
    when .upsert?
      @client.upsert(self, @payload, @on_conflict)
    when .update?
      @client.update(self, @payload)
    when .delete?
      @client.delete(self)
    else
      raise "Unknown operation"
    end
  end

  private def add_filter(column : String, op : String, value : String)
    @conditions << "#{column}=#{op}.#{value}"
    self
  end
end
