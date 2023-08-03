require_relative 'service_base_url_test_kit/patient_group'

module ServiceBaseURLTestKit
  class ServiceBaseURLTestSuite < Inferno::TestSuite
    id :service_base_url_test_suite
    title 'Service Base URL Test Suite'
    description 'A service base url testing suite for Inferno'

    # These inputs will be available to all tests in this suite
    input :url,
          title: 'FHIR Server Base Url'

    input :credentials,
          title: 'OAuth Credentials',
          type: :oauth_credentials,
          optional: true

    # All FHIR requests in this suite will use this FHIR client
    fhir_client do
      url :url
      oauth_credentials :credentials
    end

    # All FHIR validation requsets will use this FHIR validator
    validator do
      url ENV.fetch('VALIDATOR_URL')
    end

    # Tests and TestGroups can be defined inline
    group do
      id :capability_statement
      title 'Capability Statement'
      description 'Verify that the server has a CapabilityStatement'

      test do
        id :capability_statement_read
        title 'Read CapabilityStatement'
        description 'Read CapabilityStatement from /metadata endpoint'

        run do
          fhir_get_capability_statement

          assert_response_status(200)
          assert_resource_type(:capability_statement)
        end
      end
    end

    # Tests and TestGroups can be written in separate files and then included
    # using their id
    group from: :patient_group
  end
end
