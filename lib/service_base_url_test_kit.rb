require_relative 'service_base_url_test_kit/version'
require_relative 'service_base_url_test_kit/service_base_url_group'
require 'erb'

module ServiceBaseURLTestKit
  class ServiceBaseURLTestSuite < Inferno::TestSuite
    id :service_base_url_test_kit_suite
    title 'Service Base URL Test Suite'
    description %(
      This test kit provides a draft set of tests to validate conformance to the
      [HTI-1](https://www.healthit.gov/topic/laws-regulation-and-policy/health-data-technology-and-interoperability-certification-program)
      [rule](https://www.ecfr.gov/current/title-45/subtitle-A/subchapter-D/part-170/subpart-D/section-170.404#p-170.404(b)(2))
      from the API Condition and Maintenance of Certification to include the
      requirement for Certified API Developers with patient-facing apps to
      publish their service base URLs in [a specified
      format](https://www.federalregister.gov/d/2023-07229/p-2342).

      A Certified API developer must publish, at no charge, the service base URLs and related organizational details that can be used by patients to access their electronic health information
      This test kit will test that a server's service base URL list conforms to the following:
        - Service base URL list is publicly accessible
        - Service based URLs are published in the Endpoint resource format according to the standard adopted in § 170.215\(a\) - 
          FHIR 4.0.1 release 
        - Organization details for each service base URL are published in the Organization resource format according to the standard 
          adopted in § 170.215\(a\) - FHIR 4.0.1 release
        - Each Endpoint resource must:
          - Have at least one Organization resource that references it in the Bundle
        - Each Organization resource must:
          - Have a populated Organization.endpoint field that contains references to the Endpoint resources containing service base URLs managed by this organization
          - Contain the organization's name, location, and provider identifier 
        - Endpoint and Organization resources must be:
          - Collected into a Bundle resource formatted according to the standard adopted in FHIR v4.0.1: § 170.215\(a\) for publication
      
      The tests within this test kit are available for developers that would
      like to evaluate their service list against the specified format. This is
      a draft set of tests and may contain errors or issues, please provide
      feedback on these tests within the [GitHub
      Issues](https://github.com/inferno-framework/service-base-url-test-kit/issues).
    )
    version VERSION

    links [
      {
        label: 'Report Issue',
        url: 'https://github.com/onc-healthit/onc-certification-g10-test-kit/issues/'
      },
      {
        label: 'Open Source',
        url: 'https://github.com/onc-healthit/onc-certification-g10-test-kit/'
      }
    ]

    Dir.each_child(File.join(__dir__, '/service_base_url_test_kit/examples/')) do |filename|
      my_bundle = File.read(File.join(__dir__, 'service_base_url_test_kit/examples/', filename))
      if filename.end_with?('.erb')
        erb_template = ERB.new(my_bundle)
        my_bundle = JSON.parse(erb_template.result).to_json
        filename = filename.delete_suffix('.erb')
      end
      if filename.include?("CapabilityStatement")
        filename = filename.delete_suffix('.json') + "/metadata"
      end
      my_bundle_route_handler = proc { [200, { 'Content-Type' => 'application/json' }, [my_bundle]] }
      
      # Serve a JSON file at INFERNO_PATH/custom/service_base_url_test_kit_suite/examples/filename
      route :get, File.join('/examples/', filename), my_bundle_route_handler
    end

    # All FHIR validation requests will use this FHIR validator
    validator :default do
      url ENV.fetch('VALIDATOR_URL', 'http://validator_service:4567')

      exclude_message do |message|
        message.message.include?('A resource should have narrative for robust management')
      end
    end

    group from: :service_base_url_group
  end
end