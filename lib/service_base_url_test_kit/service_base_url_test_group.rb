require_relative 'service_base_url_validate_group'
require_relative 'service_base_url_retrieve_group'

module ServiceBaseURLTestKit
  class ServiceBaseURLGroup < Inferno::TestGroup
    id :service_base_url_test_group
    title 'Retrieve and Validate Service Base URL List'
    description %(
    Verify that the developer makes its Service Base URL publication publicly available
    in the Bundle resource format with valid Endpoint and Organization entries.
    This test group will issue a HTTP GET request against the supplied URL to
    retrieve the developer's Service Base URL list and ensure the list is
    publicly accessible. It will then ensure that the returned service base URL
    publication is in the Bundle resource format containing its service base URLs and
    related organizational details in valid Endpoint and Organization resources
    that follow the specifications detailed in the HTI-1 rule and the API
    Condition and Maintenance of Certification.

    For systems that provide the service base URL Bundle at a URL, please run
    all tests within this group.  While it is the expectation of the
    specification for the service base URL Bundle to be served at a
    public-facing endpoint, testers can validate a Service Base URL Bundle not
    served at a public endpoint by running Test 1.2: Validate Service Base URL
    List validation individually with the Service Base URL List Bundle input populated and the Service Base URL List
    URL input is left blank.
    )

    input :service_base_url_list_url,
          title: 'Service Base URL List URL',
          description: %(The URL to the developer's public Service Base URL List. Insert your Service Base URL list URL
          if you host your Bundle at a public-facing endpoint and want Inferno to retrieve the Bundle from there.),
          optional: true

    input :service_base_url_bundle,
          title: 'Service Base URL List Bundle',
          description: %(The developer's Service Base URL List in the JSON string format. If this input is populated,
          Inferno will use the Bundle inserted here to do validation. Insert your Service Base URL List Bundle in the
          JSON format in this input to validate your list without Inferno needing to access the Bundle via a
          public-facing endpoint.),
          type: 'textarea',
          optional: true

    group from: :service_base_url_retrieve_list
    group from: :service_base_url_validate_list
  end
end
