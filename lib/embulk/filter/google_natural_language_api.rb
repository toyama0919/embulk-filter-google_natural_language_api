require "json"
require "net/http"
require "uri"
require "openssl"

module Embulk
  module Filter

    class GoogleNaturalLanguageApi < FilterPlugin
      Plugin.register_filter("google_natural_language_api", self)
      ENDPOINT_PREFIX = "https://language.googleapis.com/v1/documents"

      def self.transaction(config, in_schema, &control)
        task = {
          "api" => config.param("api", :string),
          "out_key_name_suffix" => config.param("out_key_name_suffix", :string),
          "key_names" => config.param("key_names", :array),
          "delay" => config.param("delay", :integer, default: 0),
          "google_api_key" => config.param("google_api_key", :string, default: ENV['GOOGLE_API_KEY']),
          "language" => config.param("language", :string, default: nil),
        }

        add_columns = task["key_names"].map { |key_name|
          Column.new(nil, key_name + task["out_key_name_suffix"], :json)
        }

        out_columns = in_schema + add_columns

        yield(task, out_columns)
      end

      def init
        @uri = URI.parse("#{ENDPOINT_PREFIX}:#{task['api']}?key=#{task['google_api_key']}")
        @http = Net::HTTP.new(@uri.host, @uri.port)
        @http.use_ssl = true
        @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        @request = Net::HTTP::Post.new(@uri.request_uri, initheader = {'Content-Type' =>'application/json'})
        @key_names = task['key_names']
        @out_key_name_suffix = task['out_key_name_suffix']
        @delay = task['delay']
        @body = {
          "document" => {
            "type" => "PLAIN_TEXT",
          }
        }
        @body["document"]["language"] = task['language'] if task['language']
      end

      def close
      end

      def add(page)
        page.each do |record|
          hash = Hash[in_schema.names.zip(record)]
          @key_names.each do |key_name|
            @body["document"]["content"] = hash[key_name]
            @request.body = @body.to_json

            @http.start do |h|
              response = h.request(@request)
              hash[key_name + @out_key_name_suffix] = JSON.parse(response.body)
            end
          end
          page_builder.add(hash.values)
          sleep @delay
        end
      end

      def finish
        page_builder.finish
      end
    end
  end
end
