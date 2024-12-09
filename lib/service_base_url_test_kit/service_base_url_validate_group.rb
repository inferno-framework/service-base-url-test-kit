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

    input :resource_validation_limit,
          title: 'Limit Validation to a Maximum Resource Count',
          description: %(
            Input a number to limit the number of Bundle entries that are validated. For very large bundles, it is
            recommended to limit the number of Bundle entries to avoid long test run times.
            To validate all, leave blank.
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

    input :endpoint_availability_limit,
          title: 'Endpoint Availability Limit',
          description: %(
            In the case where the Endpoint Availability Success Rate is 'All', input a number to cap the number of
            Endpoints that Inferno will send requests to check for availability. This can help speed up validation when
            there are large number of endpoints in the Service Base URL Bundle.
          ),
          optional: true

    def regex_match?(resource_id, reference)
      return false if resource_id.blank?

      %r{#{resource_id}(?:/[^\/]*|\|[^\/]*)*/?$}.match?(reference)
    end

    # @private
    def find_referenced_org(bundle_resource, endpoint_id)
      bundle_resource
        .entry
        .map(&:resource)
        .select { |resource| resource.resourceType == 'Organization' }
        .map(&:endpoint)
        .flatten
        .map(&:reference)
        .select { |reference| regex_match?(endpoint_id, reference) }
    end

    # @private
    def find_referenced_endpoint(bundle_resource, endpoint_id_ref)
      bundle_resource
        .entry
        .map(&:resource)
        .select { |resource| resource.resourceType == 'Endpoint' }
        .map(&:id)
        .select { |endpoint_id| regex_match?(endpoint_id, endpoint_id_ref) }
    end

    def find_parent_organization(bundle_resource, org_reference)
      bundle_resource
        .entry
        .map(&:resource)
        .select { |resource| resource.resourceType == 'Organization' }
        .find { |parent_org| regex_match?(parent_org.id, org_reference) }
    end

    def skip_message
      %(
        No Service Base URL request was made in the previous test, and no Service Base URL Publication Bundle
        was provided as input instead. Either provide a Service Base URL Publication URL to retrieve the Bundle via a
        HTTP GET request, or provide the Bundle as an input.
      )
    end

    def get_resource_entries(bundle_resource, resource_type)
      bundle_resource
        .entry
        .select { |entry| entry.resource.resourceType == resource_type }
        .uniq
    end

    def limit_bundle_entries(resource_validation_limit, bundle_resource)
      new_entries = []

      organization_entries = get_resource_entries(bundle_resource, 'Organization')
      endpoint_entries = get_resource_entries(bundle_resource, 'Endpoint')

      organization_entries.each do |organization_entry|
        break if resource_validation_limit <= 0

        new_entries.append(organization_entry)
        resource_validation_limit -= 1

        found_endpoint_entries = []
        organization_resource = organization_entry.resource

        if organization_resource.endpoint.present?
          found_endpoint_entries = find_referenced_endpoints(organization_resource.endpoint, endpoint_entries)
        elsif organization_resource.partOf.present?
          parent_org = find_parent_organization_entry(organization_entries, organization_resource.partOf.reference)

          unless parent_org.blank? || resource_already_exists?(new_entries, parent_org, 'Organization')
            new_entries.append(parent_org)
            resource_validation_limit -= 1

            parent_org_resource = parent_org.resource
            found_endpoint_entries = find_referenced_endpoints(parent_org_resource.endpoint, endpoint_entries)
          end
        end

        found_endpoint_entries.each do |found_endpoint_entry|
          next if resource_already_exists?(new_entries, found_endpoint_entry, 'Endpoint')

          new_entries.append(found_endpoint_entry)

          endpoint_entries.delete_if do |entry|
            entry.resource.resourceType == 'Endpoint' && entry.resource.id == found_endpoint_entry.resource.id
          end

          resource_validation_limit -= 1
        end
      end

      endpoint_entries.each do |endpoint_entry|
        break if resource_validation_limit <= 0

        new_entries.append(endpoint_entry)
        resource_validation_limit -= 1
      end

      new_entries
    end

    def find_parent_organization_entry(organization_entries, org_reference)
      organization_entries
        .find { |parent_org_entry| regex_match?(parent_org_entry.resource.id, org_reference) }
    end

    def find_referenced_endpoints(organization_endpoints, endpoint_entries)
      endpoints = []
      organization_endpoints.each do |endpoint_ref|
        found_endpoint = endpoint_entries.find do |endpoint_entry|
          regex_match?(endpoint_entry.resource.id, endpoint_ref.reference)
        end
        endpoints.append(found_endpoint) if found_endpoint.present?
      end
      endpoints
    end

    def resource_already_exists?(new_entries, found_resource_entry, resource_type)
      new_entries.any? do |entry|
        entry.resource.resourceType == resource_type && (entry.resource.id == found_resource_entry.resource.id)
      end
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
        assert_resource_type(:bundle, resource: bundle_resource)

        info do
          assert !bundle_resource.entry.empty?, %(
            The given Bundle does not contain any resources
          )
        end

        if resource_validation_limit.present?
          limited_entries = limit_bundle_entries(resource_validation_limit.to_i,
                                                 bundle_resource)
          bundle_resource.entry = limited_entries
        end

        scratch[:bundle_resource] = bundle_resource

        assert(bundle_resource.type.present?, 'The Service Base URL Bundle Bundle is missing the required `type` field')
        assert(bundle_resource.type == 'collection', 'The Service Base URL Bundle must be type `collection`')
        assert(bundle_resource.total.blank?, 'The `total` field is not allowed in `collection` type Bundles')

        entry_full_urls = []
        additional_resources = []

        bundle_resource.entry.each_with_index do |entry, index|
          assert(entry.resource.present?, %(
            Bundle entry #{index} missing the `resource` field. For Bundles of type collection, all entries must contain
            resources.
          ))

          unless ['Organization', 'Endpoint'].include?(entry.resource.resourceType)
            additional_resources.append(entry.resource.resourceType)
          end

          assert(entry.request.blank?, %(
            Bundle entry #{index} contains the `request` field. For Bundles of type collection, all entries must not
            have request or response elements
          ))
          assert(entry.response.blank?, %(
            Bundle entry #{index} contains the `response` field. For Bundles of type collection, all entries must not
            have request or response elements
          ))
          assert(entry.search.blank?, %(
            Bundle entry #{index} contains the `search` field. Entry.search is allowed only for `search` type Bundles.
          ))

          assert(entry.fullUrl.exclude?('/_history/'), %(
            Bundle entry #{index} contains a version specific reference in the `fullUrl` field
          ))

          full_url_exists = entry_full_urls.any? do |hash|
            hash['fullUrl'] == entry.fullUrl && hash['versionId'] == entry.resource&.meta&.versionId
          end

          assert(!full_url_exists, %(
            The Service Base URL Bundle contains entries with duplicate fullUrls (#{entry.fullUrl}) and versionIds
            (#{entry.resource&.meta&.versionId}). FullUrl must be unique in a bundle, or else entries with the same
            fullUrl must have different meta.versionId
          ))

          entry_full_urls.append({ 'fullUrl' => entry.fullUrl, 'versionId' => entry.resource&.meta&.versionId })
        end

        warning do
          unique_additional_resources = additional_resources.uniq
          assert(unique_additional_resources.empty?, %(
            The Service Base URL List contained the following additional resources other than Endpoint and
            Organization resources: #{unique_additional_resources.join(', ')}))
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
        bundle_resource = scratch[:bundle_resource]

        skip_if bundle_resource.blank?, 'No Bundle response was provided'

        skip_if bundle_resource.entry.empty?, 'The given Bundle does not contain any resources'

        endpoint_resources =
          bundle_resource
            .entry
            .map(&:resource)
            .select { |resource| resource.resourceType == 'Endpoint' }

        endpoint_resources.each do |endpoint|
          resource_is_valid?(resource: endpoint)

          endpoint_id = endpoint.id
          endpoint_referenced_orgs = find_referenced_org(bundle_resource, endpoint_id)
          next unless endpoint_referenced_orgs.empty?

          add_message('error', %(
            Endpoint with id: #{endpoint_id} does not have any associated Organizations in the Bundle.
          ))
        end

        error_messages = messages.select { |msg| msg[:type] == 'error' }
        non_error_messages = messages.reject { |msg| msg[:type] == 'error' }

        @messages = []
        @messages += error_messages.first(20) unless error_messages.empty?
        @messages += non_error_messages.first(50) unless non_error_messages.empty?

        if error_messages.count > 20 || non_error_messages.count > 50
          info_message = 'Inferno is only showing the first 20 error and 50 warning/information validation messages'
          messages << { type: 'info', message: info_message }
        end

        assert messages.empty? || messages.none? { |msg| msg[:type] == 'error' }, %(
          Some Endpoints in the Service Base URL Bundle are invalid
        )
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
        bundle_resource = scratch[:bundle_resource]

        skip_if bundle_resource.blank?, 'No Bundle response was provided'

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
          - For Endpoint information, the Organization must either:
            - Use the endpoint field to reference Endpoints associated with the Organization
              - Must reference only Endpoint resources in the endpoint field
              - Must reference at least one Endpoint resource in the endpoint field
              - Must reference only Endpoints that are contained in the Service Base URL Bundle
            - Use the partOf field to reference a parent Organization that already contains the applicable endpoint
            information in its own "Organization.endpoint" element
      )

      run do
        bundle_resource = scratch[:bundle_resource]

        skip_if bundle_resource.blank?, 'No Bundle response was provided'

        skip_if bundle_resource.entry.empty?, 'The given Bundle does not contain any resources'

        organization_resources = bundle_resource
          .entry
          .map(&:resource)
          .select { |resource| resource.resourceType == 'Organization' }

        warning do
          # This was requested to be included because a publication with only a single organization
          # seems like a likely error and should be checked manually.
          assert(organization_resources.length > 1,
                 'The provided Service Base URL List contains only 1 Organization resource')
        end

        organization_resources.each do |organization|
          resource_is_valid?(resource: organization)

          if organization.address.empty?
            add_message('error', "Organization with id: #{organization.id} does not have the address field populated")
          end

          if organization.endpoint.empty?
            if organization.partOf.blank?
              add_message('error', %(
                Organization with id: #{organization.id} does not have the endpoint or partOf field populated
              ))
              next
            end

            parent_organization = find_parent_organization(bundle_resource, organization.partOf.reference)

            if parent_organization.blank?
              add_message('error', %(
                Organization with id: #{organization.id} references parent Organization not found in the Bundle:
                #{organization.partOf.reference}
              ))
              next
            end

            if parent_organization.endpoint.empty?
              add_message('error', %(
                Organization with id: #{organization.id} has parent Organization with id: #{parent_organization.id} that
                does not have the `endpoint` field populated.
              ))
            end
          else
            endpoint_references = organization.endpoint.map(&:reference)
            endpoint_references.each do |endpoint_id_ref|
              organization_referenced_endpts = find_referenced_endpoint(bundle_resource, endpoint_id_ref)
              next unless organization_referenced_endpts.empty?

              add_message('error', %(
                Organization with id: #{organization.id} references an Endpoint #{endpoint_id_ref}
                that is not contained in this bundle.
              ))
            end
          end
        end

        error_messages = messages.select { |msg| msg[:type] == 'error' }
        non_error_messages = messages.reject { |msg| msg[:type] == 'error' }

        @messages = []
        @messages += error_messages.first(20) unless error_messages.empty?
        @messages += non_error_messages.first(50) unless non_error_messages.empty?

        if error_messages.count > 20 || non_error_messages.count > 50
          info_message = 'Inferno is only showing the first 20 error and 50 warning/information validation messages'
          add_message('info', info_message)
        end

        assert messages.empty? || messages.none? { |msg| msg[:type] == 'error' }, %(
          Some Organizations in the Service Base URL Bundle are invalid
        )
      end
    end
  end
end
