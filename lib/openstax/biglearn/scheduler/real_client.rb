module OpenStax
  module Biglearn
    module Scheduler
      class RealClient

        HEADER_OPTIONS = { headers: { 'Content-Type' => 'application/json' } }.freeze

        def initialize(biglearn_scheduler_configuration)
          @server_url   = biglearn_scheduler_configuration.server_url
          @client_id    = biglearn_scheduler_configuration.client_id
          @secret       = biglearn_scheduler_configuration.secret

          @oauth_client = OAuth2::Client.new @client_id, @secret, site: @server_url

          @oauth_token  = @oauth_client.client_credentials.get_token unless @client_id.nil?
        end

        #
        # API methods
        #

        def fetch_clue_calculations(request)
          single_api_request url: :fetch_clue_calculations, request: request
        end

        def fetch_exercise_calculations(request)
          single_api_request url: :fetch_exercise_calculations, request: request
        end

        def update_clue_calculations(requests)
          bulk_api_request url: :update_clue_calculations,
                           requests: requests,
                           requests_key: :clue_calculation_updates,
                           responses_key: :clue_calculation_update_responses
        end

        def update_exercise_calculations(requests)
          bulk_api_request url: :update_exercise_calculations,
                           requests: requests,
                           requests_key: :exercise_calculation_updates,
                           responses_key: :exercise_calculation_update_responses
        end

        protected

        def absolutize_url(url)
          Addressable::URI.join @server_url, url.to_s
        end

        def api_request(method:, url:, body:)
          absolute_uri = absolutize_url(url)

          request_options = body.nil? ? HEADER_OPTIONS : HEADER_OPTIONS.merge(body: body.to_json)

          response = (@oauth_token || @oauth_client).request method, absolute_uri, request_options

          JSON.parse(response.body).deep_symbolize_keys
        end

        def single_api_request(method: :post, url:, request: nil)
          response_hash = api_request method: method, url: url, body: request

          block_given? ? yield(response_hash) : response_hash
        end

        def bulk_api_request(method: :post, url:, requests:,
                             requests_key:, responses_key:, max_requests: 1000)
          max_requests ||= requests.size

          requests.each_slice(max_requests).flat_map do |requests|
            body = { requests_key => requests }

            response_hash = api_request method: method, url: url, body: body

            responses_array = response_hash.fetch responses_key

            responses_array.map{ |response| block_given? ? yield(response) : response }
          end
        end

      end
    end
  end
end
