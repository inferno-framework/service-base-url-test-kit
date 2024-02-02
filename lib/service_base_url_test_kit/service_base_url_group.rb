require_relative 'service_base_url_bundle_group'
require_relative 'service_base_url_endpoint_query_group'

module ServiceBaseURLTestKit
  class ServiceBaseURLGroup < Inferno::TestGroup
    id :service_base_url_group
    title 'Retrieve and Validate Service Base URL List'
    description %(    

    Verify that the server makes its Service Base URL list publicly available in the Bundle resource format with valid Endpoint and Organization entries. This test group will query the provided url to the server's Service Base URL list and ensure the list is publicly accessible. It will then ensure that the returned service base URL list is in the Bundle resource format containing its service base URLs and related organizational details in valid Endpoint and Organization resources that follow the specifications detailed in the HTI-1 rule in the API Condition and Maintenance of Certification.

    For systems that provide the service base URL Bundle at a URL, please run all tests within this group.  While it is the expectation of the specification for the service base URL Bundle to be served at a public-facing endpoint, testers can validate a Service Base URL Bundle not served at a public endpoint by running Test 1.2: Service Base URL List Validation individually.
    )
    
    group from: :service_base_url_endpoint_query
    group from: :service_base_url_bundle_tests
  end
end
