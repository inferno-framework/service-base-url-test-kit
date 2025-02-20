require_relative 'service_base_url_test_kit/metadata'
require_relative 'service_base_url_test_kit/version'
require_relative 'service_base_url_test_kit/service_base_url_test_group'
require 'erb'

module ServiceBaseURLTestKit
  class ServiceBaseURLTestSuite < Inferno::TestSuite
    id :service_base_url
    title 'Service Base URL Test Suite'
    description %(
      This Test Kit provides a set of tests that verify conformance of Service
      Base URL publications to data format requirements as described in
      [Conditions and Maintenance of Certification - Application programming
      interfaces](https://www.ecfr.gov/current/title-45/subtitle-A/subchapter-D/part-170/subpart-D/section-170.404#p-170.404(b)(2))
      and the [ONC HTI-1 Final
      Rule](https://www.healthit.gov/topic/laws-regulation-and-policy/health-data-technology-and-interoperability-certification-program).
      Please review the [Application Programming Interfaces Certification Companion
      Guide](https://www.healthit.gov/condition-ccg/application-programming-interfaces)
      for additional guidance.

      This Test Kit is provided as a tool to help developers identify potential
      issues or problems with the structure of their Service Base URL
      publication.  Test failures do not necessarily indicate non-conformance to
      the Conditions and Maintenance of Certification.  Use of these tests is
      not required for the participants of the ONC Health IT Certification Program.
      Please provide feedback on these tests by reporting an issue in
      [GitHub](https://github.com/inferno-framework/service-base-url-test-kit/issues),
      or by reaching out to the team on the [Inferno FHIR Zulip
      channel](https://chat.fhir.org/#narrow/stream/179309-inferno).

      Relevant requirements from the [Conditions and Maintenance of
      Certification - Application programming
      interfaces](https://www.ecfr.gov/current/title-45/subtitle-A/subchapter-D/part-170/subpart-D/section-170.404#p-170.404(b)(2)):

      Service Base URL publication:

      For all Health IT Modules certified to § 170.315(g)(10), a Certified API
      Developer must publish, at no charge, the service base URLs and related
      organization details that can be used by patients to access their
      electronic health information, by December 31, 2024. This includes all
      customers regardless of whether the Health IT Modules certified to §
      170.315(g)(10) are centrally managed by the Certified API Developer or
      locally deployed by an API Information Source. These service base URLs and
      organization details must conform to the following:

       - Service base URLs must be publicly published in Endpoint resource format
         according to the standard adopted in § 170.215(a) (FHIR v4.0.1).
       - Organization details for each service base URL must be publicly published in Organization
         resource format according to the standard adopted in § 170.215(a) (FHIR v4.0.1). Each
         Organization resource must contain:
          - The organization's name, location, and facility identifier.
          - Either:
            - A reference, in the Organization endpoint element, to the Endpoint
            resources containing service base URLs managed by this organization
            - A reference, in the Organization partOf element, to the parent Organization that contains the applicable
            endpoint information in its own "Organization.endpoint" element
       - Endpoint and Organization resources must be:
         - Collected into a Bundle resource formatted according to the standard
            adopted in § 170.215(a) (FHIR v4.0.1) for publication
         - Reviewed quarterly and, as necessary, updated.


    )
    version VERSION

    input_instructions <<~INSTRUCTIONS
      For systems that make their Service Base URL Bundle available at a public endpoint, please input
      the Service Base URL Publication URL to retrieve the Bundle from there in order to perform validation, and leave
      the Service Base URL Publication Bundle input blank.

      For systems that do not have a Service Base URL Bundle served at a public endpoint, testers can validate by
      providing the Service Base URL Publication Bundle as an input and leaving the Service Base URL Publication URL
      input blank.
    INSTRUCTIONS

    links [
      {
        label: 'Report Issue',
        url: 'https://github.com/inferno-framework/service-base-url-test-kit/issues'
      },
      {
        label: 'Open Source',
        url: 'https://github.com/inferno-framework/service-base-url-test-kit'
      },
      {
        label: 'Service base URL requirements',
        url: 'https://www.ecfr.gov/current/title-45/subtitle-A/subchapter-D/part-170/subpart-D/section-170.404#p-170.404(b)(2)'
      },
      {
        label: 'Certification Companion Guide',
        url: 'https://www.healthit.gov/condition-ccg/application-programming-interfaces'
      }
    ]

    Dir.each_child(File.join(__dir__, '/service_base_url_test_kit/examples/')) do |filename|
      my_bundle = File.read(File.join(__dir__, 'service_base_url_test_kit/examples/', filename))
      if filename.end_with?('.erb')
        erb_template = ERB.new(my_bundle)
        my_bundle = JSON.parse(erb_template.result).to_json
        filename = filename.delete_suffix('.erb')
      end
      filename = "#{filename.delete_suffix('.json')}/metadata" if filename.include?('CapabilityStatement')
      my_bundle_route_handler = proc { [200, { 'Content-Type' => 'application/json' }, [my_bundle]] }

      # Serve a JSON file at INFERNO_PATH/custom/service_base_url/examples/filename
      route :get, File.join('/examples/', filename), my_bundle_route_handler
    end

    VALIDATION_MESSAGE_FILTERS = [
      /A resource should have narrative for robust management/,
      /\A\S+: \S+: URL value '.*' does not resolve/
    ].freeze

    # All FHIR validation requests will use this FHIR validator
    fhir_resource_validator :default do
      exclude_message do |message|
        VALIDATION_MESSAGE_FILTERS.any? { |filter| filter.match? message.message }
      end
    end

    group from: :service_base_url_test_group
  end
end
