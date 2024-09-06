module ServiceBaseURLTestKit
  class ServiceBaseURLEndpointQueryGroup < Inferno::TestGroup
    id :service_base_url_retrieve_list
    title 'Retrieve Service Base URL Publication'
    description %(
      A developer's Service Base URL publication must be publicly available.  This test
      issues a HTTP GET request against the supplied URL and expects to receive
      the service base url publication at this location.
    )
    run_as_group

    http_client do
      url :service_base_url_publication_url
      headers Accept: 'application/json, application/fhir+json'
    end

    test do
      id :service_base_url_retrieve_list_test
      title 'Server returns publicly accessible Service Base URL Publication'
      description %(
        Verify that the developer's list of Service Base URLs can be publicly
        accessed at the supplied URL location.
      )

      input :service_base_url_publication_url,
            optional: true

      output :bundle_response

      makes_request :bundle_request

      run do
        omit_if service_base_url_publication_url.blank?, 'URL for Service Base URL Publication not Inputted.'

        get(tags: ['service_base_url_bundle'])
        assert_response_status(200)
      end
    end
  end
end
