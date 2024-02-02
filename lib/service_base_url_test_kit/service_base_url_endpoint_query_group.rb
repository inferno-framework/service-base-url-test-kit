module ServiceBaseURLTestKit
  class ServiceBaseURLEndpointQueryGroup < Inferno::TestGroup
    id :service_base_url_endpoint_query
    title 'Service Base URL Endpoint Query'
    description %(
      A server's Service Base URL list should be publicly available. 
      This test attempts to query the server's Service Base URL endpoint to ensure it receives a 200 response.
    )
    run_as_group

    input :service_base_url_list_endpoint,
      title: 'Service Base URL List endpoint URL',
      description: 'The URL to the server\'s public Service Base URL List'

    http_client do
      url :service_base_url_list_endpoint
      headers 'Accept': 'application/json, application/fhir+json'
    end

    test do
      id :service_base_url_endpoint_query_test
      title 'Server returns publicly accessible Service Base URL List'
      description %(
        Verify that the server's list of Service Base URLs can be publicly accessed on the server.
      )

      output :bundle_response

      makes_request :bundle_request

      run do
        get
        assert_response_status(200)
        output bundle_response: resource.to_json
      end      
    end
  end
end
