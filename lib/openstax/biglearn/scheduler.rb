require_relative 'scheduler/configuration'
require_relative 'scheduler/fake_client'
require_relative 'scheduler/real_client'
require_relative 'scheduler/malformed_request'
require_relative 'scheduler/result_type_error'

module OpenStax
  module Biglearn
    module Scheduler

      ALGORITHM_NAME = 'local_query'.freeze

      mattr_accessor :client

      class << self

        def configuration
          @configuration ||= new_configuration
        end

        def configure
          yield configuration
        end

        def use_fake_client
          self.client = new_client OpenStax::Biglearn::Scheduler::FakeClient
        end

        def use_real_client
          self.client = new_client OpenStax::Biglearn::Scheduler::RealClient
        end

        protected

        def new_configuration
          OpenStax::Biglearn::Scheduler::Configuration.new
        end

        def new_client(client_class)
          begin
            client_class.new(configuration)
          rescue StandardError => e
            raise "Biglearn client initialization error: #{e.message}"
          end
        end

        def verify_and_slice_request(method:, request:, keys:, optional_keys:)
          required_keys = [keys].flatten
          return if request.nil? && required_keys.empty?

          missing_keys = required_keys.reject{ |key| request.has_key? key }

          raise(
            OpenStax::Biglearn::Api::MalformedRequest,
            "Invalid request: #{method} request #{request.inspect
            } is missing these required key(s): #{missing_keys.inspect}"
          ) if missing_keys.any?

          request.slice(*required_keys)
        end

        def verify_result(result:, result_class: Hash)
          results_array = [result].flatten

          results_array.each do |result|
            raise(
              OpenStax::Biglearn::Api::ResultTypeError,
              "Invalid result: #{result} has type #{result.class.name
              } but expected type was #{result_class.name}"
            ) if result.class != result_class
          end

          result
        end

        def single_api_request(method:, request: nil, keys: [], optional_keys: [], result_class: Hash)
          verified_request = verify_and_slice_request method: method,
                                                      request: request,
                                                      keys: keys,
                                                      optional_keys: optional_keys

          response = verified_request.nil? ? client.send(method) :
                                             client.send(method, verified_request)

          verify_result(result: block_given? ? yield(request, response) : response,
                        result_class: result_class)
        end

        def bulk_api_request(method:, requests:, keys:, optional_keys: [],
                             result_class: Hash, uuid_key: :request_uuid)
          return {} if requests.blank?

          requests_map = {}
          [requests].flatten.map do |request|
            requests_map[SecureRandom.uuid] = verify_and_slice_request(
              method: method, request: request, keys: keys, optional_keys: optional_keys
            )
          end

          requests_array = requests_map.map{ |uuid, request| request.merge uuid_key => uuid }

          responses = {}
          client.send(method, requests_array).each do |response|
            request = requests_map[response[uuid_key]]

            responses[request] = verify_result(
              result: block_given? ? yield(request, response) : response, result_class: result_class
            )
          end

          # If given a Hash instead of an Array, return the response directly
          requests.is_a?(Hash) ? responses.values.first : responses
        end

      end

    end
  end
end
