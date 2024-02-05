module ServiceBaseURLTestKit
  class ServiceBaseURLEndpointQueryGroup < Inferno::TestGroup
    id :service_base_url_retrieve_list
    title 'Retrieve Service Base URL List'
    description %(
      A developer's Service Base URL list must be publicly available.  This test
      issues a HTTP GET request against the supplied URL and expects to receive
      the service base url list at this location.
    )
    run_as_group

    input :service_base_url_list_url,
      title: 'Service Base URL List URL',
      description: 'The URL to the developer\'s public Service Base URL List'

    http_client do
      url :service_base_url_list_url
      headers 'Accept': 'application/json, application/fhir+json'
    end

    test do
      id :service_base_url_retrieve_list_test
      title 'Server returns publicly accessible Service Base URL List'
      description %(
        Verify that the developer's list of Service Base URLs can be publicly
        accessed at the supplied URL location.
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
