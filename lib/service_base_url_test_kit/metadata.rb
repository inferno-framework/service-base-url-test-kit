require_relative 'version'

module ServiceBaseURLTestKit
  class Metadata < Inferno::TestKit
    id :service_base_url_test_kit
    title 'Service Base URL Test Kit'
    suite_ids ['service_base_url']
    tags ['Endpoint Publication']
    last_updated ::ServiceBaseURLTestKit::LAST_UPDATED
    version ::ServiceBaseURLTestKit::VERSION
    maturity 'Medium'
    authors ['Inferno Team']
    repo 'https://github.com/inferno-framework/service-base-url-test-kit'
    description <<~DESCRIPTION
      The Service Base URL Test Kit provides a set of tests that verify
      conformance of Service Base URL publications to data format requirements
      as described in
      [Conditions and Maintenance of Certification - Application programming interfaces](https://www.ecfr.gov/current/title-45/subtitle-A/subchapter-D/part-170/subpart-D/section-170.404#p-170.404(b)(2))
      and the
      [ONC HTI-1 Final Rule](https://www.healthit.gov/topic/laws-regulation-and-policy/health-data-technology-and-interoperability-certification-program).
      Please review the
      [Application Programming Interfaces Certification Companion Guide](https://www.healthit.gov/condition-ccg/application-programming-interfaces)
      for additional guidance. <!-- break -->This Test Kit is provided as a tool
      to help developers identify potential issues or problems with the
      structure of their Service Base URL publication. Test failures do not
      necessarily indicate non-conformance to the Conditions and Maintenance of
      Certification. Use of these tests is not required for participants of the
      ONC Health IT Certification Program. Please provide feedback on these
      tests by reporting an issue in
      [GitHub](https://github.com/inferno-framework/service-base-url-test-kit/issues),
      or by reaching out to the team on the
      [Inferno FHIR Zulip channel](https://chat.fhir.org/#narrow/stream/179309-inferno).
  
      This Test Kit specifically targets requirements provided within the Conditions
      and Maintenance of Certification. Testing for the related
      [SMART User-access Brands and Endpoints](http://hl7.org/fhir/smart-app-launch/STU2.2/brands.html)
      specification is provided separately within the
      [SMART App Launch Test Kit](https://inferno.healthit.gov/test-kits/smart-app-launch).
  
      Relevant requirements from the Conditions and Maintenance of
      Certification - Application programming interfaces:
  
      **Service Base URL publication:**
  
      For all Health IT Modules certified to § 170.315(g)(10), a Certified API
      Developer must publish, at no charge, the service base URLs and related
      organization details that can be used by patients to access their
      electronic health information, by December 31, 2024. This includes all
      customers regardless of whether the Health IT Modules certified
      to § 170.315(g)(10) are centrally managed by the Certified API Developer
      or locally deployed by an API Information Source. These service base URLs
      and organization details must conform to the following:
  
      - Service base URLs must be publicly published in Endpoint resource format
        according to the standard adopted in § 170.215(a) (FHIR v4.0.1).
      - Organization details for each service base URL must be publicly
        published in Organization resource format according to the standard
        adopted in § 170.215(a) (FHIR v4.0.1). Each Organization resource must
        contain:
        + A reference, in the Organization endpoint element, to the Endpoint resources containing service base URLs managed by this organization.
        + The organization’s name, location, and facility identifier.
      - Endpoint and Organization resources must be:
        + Collected into a Bundle resource formatted according to the standard adopted in § 170.215(a) (FHIR v4.0.1) for publication;
        + and Reviewed quarterly and, as necessary, updated.
  
      ## Providing Feedback and Reporting Issues
  
      We welcome feedback on the tests, including but not limited to the following areas:
  
      - Validation logic, such as potential bugs, lax checks, and unexpected failures.
      - Requirements coverage, such as requirements that have been missed, tests that
        necessitate features that the IG does not require, or other issues with the
        interpretation of the IG’s requirements.
      - User experience, such as confusing or missing information in the test UI.
  
      Please report any issues with this set of tests in the
      [issues section](https://github.com/inferno-framework/service-base-url-test-kit/issues)
      of the source code repository.
    DESCRIPTION
  end
end
