require_relative 'service_base_url_test_kit/service_base_url_group'
require 'erb'

module ServiceBaseURLTestKit
  class ServiceBaseURLTestSuite < Inferno::TestSuite
    id :service_base_url_test_kit_suite
    title 'Service Base URL Test Suite'
    description 'A service base url testing suite for Inferno'

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