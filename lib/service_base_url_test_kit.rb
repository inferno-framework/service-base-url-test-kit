require_relative 'service_base_url_test_kit/service_base_url_group'
require 'erb'

module ServiceBaseURLTestKit
  class ServiceBaseURLTestSuite < Inferno::TestSuite
    id :service_base_url_test_kit_suite
    title 'Service Base URL Test Suite'
    description %(
      This test kit provides a draft set of tests to validate conformance to the
      [HTI-1](https://www.healthit.gov/topic/laws-regulation-and-policy/health-data-technology-and-interoperability-certification-program)
      [proposed amendment](https://www.federalregister.gov/d/2023-07229/p-195)
      to the API Condition and Maintenance of Certification to include the
      requirement for Certified API Developers with patient-facing apps to
      publish their service base URLs in [a specified
      format](https://www.federalregister.gov/d/2023-07229/p-2342).
      
      The tests within this test kit are available for developers that would
      like to evaluate their service list against the specified format.  This is
      a draft set of tests and may contain errors or issues, please provide
      feedback on these tests within the [GitHub
      Issues](https://github.com/inferno-framework/service-base-url-test-kit/issues).
      
      Several publicly available examples of service base URLs are available as
      'Presets'.  These have been included for reference to highlight how
      existing implementations may differ from the proposed specified format.
    )

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
    end

    # Tests and TestGroups can be written in separate files and then included
    # using their id
    group from: :service_base_url_group
  end
end