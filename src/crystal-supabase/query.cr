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

  def select(fields : String)
    @select_fields = fields
    @operation = Operation::Select
    self
  end

  def insert(payload : String)
    @payload = payload
    @operation = Operation::Insert
    self
  end

  def upsert(payload : String, on_conflict : Array(String))
    @payload = payload
    @on_conflict = on_conflict
    @operation = Operation::Upsert
    self
  end

  def update(payload : String)
    @payload = payload
    @operation = Operation::Update
    self
  end

  def delete
    @operation = Operation::Delete
    self
  end

  def eq(column : String, value : String)
    add_filter(column, "eq", value)
  end

  def neq(column : String, value : String)
    add_filter(column, "neq", value)
  end

  def gt(column : String, value : String)
    add_filter(column, "gt", value)
  end

  def gte(column : String, value : String)
    add_filter(column, "gte", value)
  end

  def lt(column : String, value : String)
    add_filter(column, "lt", value)
  end

  def lte(column : String, value : String)
    add_filter(column, "lte", value)
  end

  def like(column : String, pattern : String)
    add_filter(column, "like", pattern)
  end

  def ilike(column : String, pattern : String)
    add_filter(column, "ilike", pattern)
  end

  def in_(column : String, values : Array(String))
    joined = values.join(",")
    @conditions << "#{column}=in.(#{joined})"
    self
  end

  def is_null(column : String, is_null : Bool = true)
    val = is_null ? "is.null" : "not.is.null"
    @conditions << "#{column}=#{val}"
    self
  end

  def not(column : String, operator : String, value : String)
    @conditions << "#{column}=not.#{operator}.#{value}"
    self
  end

  def order_asc(column : String)
    @conditions << "order=#{column}.asc"
    self
  end

  def order_desc(column : String)
    @conditions << "order=#{column}.desc"
    self
  end

  def limit(count : Int32)
    @conditions << "limit=#{count}"
    self
  end

  def offset(count : Int32)
    @conditions << "offset=#{count}"
    self
  end

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
