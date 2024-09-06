module ServiceBaseURLTestKit
  class ServiceBaseURLBundleTestGroup < Inferno::TestGroup
    id :service_base_url_validate_list
    title 'Validate Service Base URL Publication'
    description %(
      These tests ensure that the developer's Service Base URL publication is in
      the Bundle resource format, with its service base URLs and organizational
      details contained in valid Endpoint and Organization entries that follow
      the specifications detailed in the HTI-1 rule and the API Condition and
      Maintenance of Certification.

      These tests may be run individually, bypassing the first test group, if the Service Base URL Publication Bundle
      input is populated and the Service Base URL Publication URL is left blank (or if it does not successfully return
      a Service Base URL Publication Bundle). You may insert your Service Base URL Publication Bundle in the JSON
      format in the Service Base URL Publication Bundle input to validate your list without Inferno needing to retrieve
      the Bundle via a public-facing endpoint.
    )
    run_as_group

    input :service_base_url_bundle,
          optional: true

    input :endpoint_availability_limit,
          title: 'Endpoint Availability Limit',
          description: %(
            In the case where the Endpoint Availability Success Rate is 'All', input a number to cap the number of
            Endpoints that Inferno will send requests to check for availability. This can help speed up validation when
            there are large number of endpoints in the Service Base URL Bundle.
          ),
          optional: true

    input :endpoint_availability_success_rate,
          title: 'Endpoint Availability Success Rate',
          description: %(
            Select an option to choose how many Endpoints have to be available and send back a valid capability
            statement for the Endpoint validation test to pass.
          ),
          type: 'radio',
          options: {
            list_options: [
              {
                label: 'All',
                value: 'all'
              },
              {
                label: 'At Least One',
                value: 'at_least_1'
              },
              {
                label: 'None',
                value: 'none'
              }
            ]
          },
          default: 'all'

    # @private
    def find_referenced_org(bundle_resource, endpoint_id)
      bundle_resource
        .entry
        .map(&:resource)
        .select { |resource| resource.resourceType == 'Organization' }
        .map(&:endpoint)
        .flatten
        .map(&:reference)
        .select { |reference| reference.include? endpoint_id }
    end

    # @private
    def find_referenced_endpoint(bundle_resource, endpoint_id_ref)
      bundle_resource
        .entry
        .map(&:resource)
        .select { |resource| resource.resourceType == 'Endpoint' }
        .map(&:id)
        .select { |endpoint_id| endpoint_id_ref.include? endpoint_id }
    end

    def skip_message
      %(
        No Service Base URL request was made in the previous test, and no Service Base URL Publication Bundle
        was provided as input instead. Either provide a Service Base URL Publication URL to retrieve the Bundle via a
        HTTP GET request, or provide the Bundle as an input.
      )
    end

    #  Valid BUNDLE TESTS
    test do
      id :service_base_url_valid_bundle
      title 'Server returns valid Bundle resource according to FHIR v4.0.1'
      description %(
        Verify that the returned Bundle of Service Base URLs is a valid Bundle resource and that it is not empty.
      )

      run do
        bundle_response = if service_base_url_bundle.blank?
                            load_tagged_requests('service_base_url_bundle')
                            skip skip_message if requests.length != 1
                            requests.first.response_body
                          else
                            service_base_url_bundle
                          end
        skip_if bundle_response.blank?, 'No Bundle response was provided'

        assert_valid_json(bundle_response)
        bundle_resource = FHIR.from_contents(bundle_response)
        assert_valid_resource(resource: bundle_resource)

        assert_resource_type(:bundle, resource: bundle_resource)
        info do
          assert !bundle_resource.entry.empty?, %(
            The given Bundle does not contain any resources
          )
        end
      end
    end

    # VALID ENDPOINT TESTS
    test do
      id :service_base_url_valid_endpoints
      title 'Service Base URL Publication contains valid Endpoint resources'
      description %(
        Verify that Bundle of Service Base URLs contains Endpoints that are
        valid Endpoint resources according to the format defined in FHIR v4.0.1.

        Each Endpoint must:
          - Contain must have elements including:
            - status
            - connectionType
            - address
          - Contain a URL in the address field
          - Have at least one Organization resource in the Bundle that references it
      )

      run do
        bundle_response = if service_base_url_bundle.blank?
                            load_tagged_requests('service_base_url_bundle')
                            skip skip_message if requests.length != 1
                            requests.first.response_body
                          else
                            service_base_url_bundle
                          end
        skip_if bundle_response.blank?, 'No Bundle response was provided'

        assert_valid_json(bundle_response)
        bundle_resource = FHIR.from_contents(bundle_response)

        skip_if bundle_resource.entry.empty?, 'The given Bundle does not contain any resources'

        assert_valid_bundle_entries(bundle: bundle_resource,
                                    resource_types: {
                                      Endpoint: nil
                                    })

        endpoint_ids =
          bundle_resource
            .entry
            .map(&:resource)
            .select { |resource| resource.resourceType == 'Endpoint' }
            .map(&:id)

        endpoint_ids.each do |endpoint_id|
          endpoint_referenced_orgs = find_referenced_org(bundle_resource, endpoint_id)
          assert !endpoint_referenced_orgs.empty?,
                 "Endpoint with id: #{endpoint_id} does not have any associated Organizations in the Bundle."
        end
      end
    end

    # ENDPOINT VALID URL TESTS
    test do
      id :service_base_url_valid_urls
      title 'All Endpoint resource referenced URLS should be valid and available'
      description %(
        Verify that Bundle of Service Base URLs contains Endpoints that contain service base URLs that are both valid
        and available.
      )

      run do
        bundle_response = if service_base_url_bundle.blank?
                            load_tagged_requests('service_base_url_bundle')
                            skip skip_message if requests.length != 1
                            requests.first.response_body
                          else
                            service_base_url_bundle
                          end
        skip_if bundle_response.blank?, 'No Bundle response was provided'

        assert_valid_json(bundle_response)
        bundle_resource = FHIR.from_contents(bundle_response)

        skip_if bundle_resource.entry.empty?, 'The given Bundle does not contain any resources'

        endpoint_list = bundle_resource
          .entry
          .map(&:resource)
          .select { |resource| resource.resourceType == 'Endpoint' }
          .map(&:address)
          .uniq

        if endpoint_availability_limit.present? && endpoint_availability_limit.to_i < endpoint_list.count
          info %(
            Only the first #{endpoint_availability_limit.to_i} endpoints of #{endpoint_list.count} total will be
            checked.
          )
        end

        one_endpoint_valid = false
        endpoint_list.each_with_index do |address, index|
          assert_valid_http_uri(address)

          next if endpoint_availability_success_rate == 'none' ||
                  (endpoint_availability_limit.present? && endpoint_availability_limit.to_i <= index)

          address = address.delete_suffix('/')

          response = nil
          warning do
            response = get("#{address}/metadata", client: nil, headers: { Accept: 'application/fhir+json' })
          end

          if endpoint_availability_success_rate == 'all'
            assert response.present?, "Encountered issues while trying to make a request to #{address}/metadata."
            assert_response_status(200)
            assert resource.present?, 'The content received does not appear to be a valid FHIR resource'
            assert_resource_type(:capability_statement)
          else
            if response.present?
              warning do
                assert_response_status(200)
                assert resource.present?, 'The content received does not appear to be a valid FHIR resource'
                assert_resource_type(:capability_statement)
              end
            end

            if !one_endpoint_valid && response.present? && response.status == 200 && resource.present? &&
               resource.resourceType == 'CapabilityStatement'
              one_endpoint_valid = true
            end
          end
        end

        if endpoint_availability_success_rate == 'at_least_1'
          assert(one_endpoint_valid, %(
            There were no Endpoints that were available and returned a valid Capability Statement in the Service Base
            URL Bundle'
          ))
        end
      end
    end

    # ORGANIZATION TESTS
    test do
      id :service_base_url_valid_organizations
      title 'Service Base URL Publication contains valid Organization resources'
      description %(

        Verify that Bundle of Service Base URLs contains Organizations that are valid Organization resources according
        to the format defined in FHIR v4.0.1.

        Each Organization must:
          - Contain must have elements including:
            - active
            - name
          - Include the organization's name, location, and facility identifier
          - Use the endpoint field to reference Endpoints associated with the Organization:
            - Must reference only Endpoint resources in the endpoint field
            - Must reference at least one Endpoint resource in the endpoint field
            - Must reference only Endpoints that are contained in the Service Base URL Bundle
      )

      run do
        bundle_response = if service_base_url_bundle.blank?
                            load_tagged_requests('service_base_url_bundle')
                            skip skip_message if requests.length != 1
                            requests.first.response_body
                          else
                            service_base_url_bundle
                          end
        skip_if bundle_response.blank?, 'No Bundle response was provided'

        assert_valid_json(bundle_response)
        bundle_resource = FHIR.from_contents(bundle_response)

        skip_if bundle_resource.entry.empty?, 'The given Bundle does not contain any resources'

        assert_valid_bundle_entries(bundle: bundle_resource,
                                    resource_types: {
                                      Organization: nil
                                    })

        organization_resources = bundle_resource
          .entry
          .map(&:resource)
          .select { |resource| resource.resourceType == 'Organization' }

        organization_resources.each do |organization|
          assert !organization.endpoint.empty?,
                 "Organization with id: #{organization.id} does not have the endpoint field populated"
          assert !organization.address.empty?,
                 "Organization with id: #{organization.id} does not have the address field populated"

          endpoint_references = organization.endpoint.map(&:reference)

          endpoint_references.each do |endpoint_id_ref|
            organization_referenced_endpts = find_referenced_endpoint(bundle_resource, endpoint_id_ref)
            assert !organization_referenced_endpts.empty?,
                   "Organization with id: #{organization.id} references an Endpoint that is not contained in this
                   bundle."
          end
        end
      end
    end
  end
end
