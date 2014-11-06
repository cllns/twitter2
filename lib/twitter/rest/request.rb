require 'faraday'
require 'json'
require 'timeout'
require 'twitter/error'
require 'twitter/headers'
require 'twitter/rate_limit'

module Twitter
  module REST
    class Request
      attr_accessor :client, :headers, :rate_limit, :request_method, :path, :options
      alias_method :verb, :request_method
      URL_PREFIX = 'https://api.twitter.com'

      # @param client [Twitter::Client]
      # @param request_method [String, Symbol]
      # @param path [String]
      # @param options [Hash]
      # @return [Twitter::REST::Request]
      def initialize(client, request_method, path, options = {})
        @client = client
        @request_method = request_method.to_sym
        @path = path
        @options = options
      end

      # @return [Array, Hash]
      def perform
        @headers = Twitter::Headers.new(@client, @request_method, URL_PREFIX + @path, @options).request_headers
        begin
          response = @client.connection.send(@request_method, @path, @options) { |request| request.headers.update(@headers) }.env
        rescue Faraday::Error::TimeoutError, Timeout::Error => error
          raise(Twitter::Error::RequestTimeout.new(error))
        rescue Faraday::Error::ClientError, JSON::ParserError => error
          raise(Twitter::Error.new(error))
        end
        @rate_limit = Twitter::RateLimit.new(response.response_headers)
        response.body
      end
    end
  end
end
