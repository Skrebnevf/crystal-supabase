require "http/client"
require "uri"

class Supabase::ClientBuilder
  protected def with_http_client(
    url : String,
    connect_timeout : Time::Span = 40.seconds,
    read_timeout : Time::Span = 30.seconds,
    write_timeout : Time::Span = 30.seconds,
    &
  ) : String
    uri = URI.parse url
    client = HTTP::Client.new uri

    client.connect_timeout = connect_timeout
    client.read_timeout = read_timeout
    client.write_timeout = write_timeout

    begin
      yield client
    rescue ex : IO::TimeoutError
      raise "Timeout error: #{ex.message}"
    rescue ex : IO::Error
      raise "Network error: #{ex.message}"
    rescue ex : Exception
      raise "Unexpected error: #{ex.message}"
    ensure
      client.close
    end
  end
end
