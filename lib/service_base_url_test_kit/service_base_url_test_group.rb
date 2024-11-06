require_relative 'service_base_url_validate_group'
require_relative 'service_base_url_retrieve_group'

module ServiceBaseURLTestKit
  class ServiceBaseURLGroup < Inferno::TestGroup
    id :service_base_url_test_group
    title 'Validate Service Base URL Publication'
    description %(
      Verify that the developer makes its Service Base URL publication publicly available in the Bundle resource format
      with valid Endpoint and Organization entries. This test group will issue a HTTP GET request against the supplied
      URL to retrieve the developer's Service Base URL publication and ensure the list is publicly accessible. It will
      then ensure that the returned service base URL publication is in the Bundle resource format containing its service
      base URLs and related organizational details in valid Endpoint and Organization resources that follow the
      specifications detailed in the HTI-1 rule and the API Condition and Maintenance of Certification.

      For systems that provide the service base URL Bundle at a URL, please run
      this test with the Service Base URL Publication URL input populated and the Service Base URL Publication Bundle
      input left blank. While it is the expectation of the specification for the service base URL Bundle to be served at
      a public-facing endpoint, testers can validate a Service Base URL Bundle not served at a public endpoint by
      running these tests with the Service Base URL Publication Bundle input populated and the Service Base URL
      Publication URL input left blank.
    )

    input_instructions <<~INSTRUCTIONS
      For systems that make their Service Base URL Bundle available at a public endpoint, please input
      the Service Base URL Publication URL to retrieve the Bundle from there in order to perform validation.

      For systems that do not have a Service Base URL Bundle served at a public endpoint, testers can validate by
      providing the Service Base URL Publication Bundle as an input and leaving the Service Base URL Publication URL
      input blank.
    INSTRUCTIONS

    run_as_group

    input :service_base_url_publication_url,
          title: 'Service Base URL Publication URL',
          description: %(The URL to the developer's public Service Base URL Publication. Insert your Service Base URL
          publication URL if you host your Bundle at a public-facing endpoint and want Inferno to retrieve the Bundle
          from there.),
          optional: true

    input :service_base_url_bundle,
          title: 'Service Base URL Publication Bundle',
          description: %(The developer's Service Base URL Publication in the JSON string format. If this input is
          populated, Inferno will use the Bundle inserted here to do validation. Insert your Service Base URL
          Publication Bundle in the JSON format in this input to validate your list without Inferno needing to access
          the Bundle via a public-facing endpoint.),
          type: 'textarea',
          optional: true

    group from: :service_base_url_retrieve_list
    group from: :service_base_url_validate_list
  end
end
