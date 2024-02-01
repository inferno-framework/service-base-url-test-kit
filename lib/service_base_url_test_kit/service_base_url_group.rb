module ServiceBaseURLTestKit
  class ServiceBaseURLGroup < Inferno::TestGroup
    title 'Service Base URL List Tests'
    description %(    

    Verify that the server makes it's Service Base URL list publicly available in the Bundle resource format with valid Endpoint and Organization entries.
    This test group will query the provided url to the server's Service Base URL list and ensure the list is publicly accessible. It will then ensure that the 
    returned service base URL list is in the Bundle resource format containing it's service base URLs and related organizational details
    in valid Endpoint and Organization resources that follow the specifications detailed in the HTI-1 rule in the API Condition and Maintenance of Certification.

    For systems that provide the service base URL Bundle at a URL, please run all
    tests within this group.  While it is the expectation of the specification for
    the service base URL Bundle to be served at a public-facing endpoint, testers
    can run any individual component test if Bundles are not served via endpoint by
    pasting the Bundle as a test input.
    )

    id :service_base_url_group

    # @private
    def find_referenced_org(bundle_resource, endpoint_id)
      bundle_resource
      .entry
      .map(&:resource)
      .select { |resource| resource.resourceType == 'Organization' }
      .map { |resource| resource.endpoint }
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

    group do
      id :service_base_url_endpoint_query
      title 'Service Base URL Endpoint Query'
      description %(A server's Service Base URL list should be publicly available. 
      This test attempts to query the server's Service Base URL endpoint to ensure 
      it receives a 200 response.)
      run_as_group

      input :service_base_url_list_endpoint,
      title: 'Service Base URL List endpoint URL',
      description: 'The URL to the server\'s public Service Base URL List'

      http_client do
        url :service_base_url_list_endpoint
        headers 'Accept': 'application/json, application/fhir+json'
      end

      test do
        id :service_base_url_endpoint_query_test
        title 'Server returns publicly accessible Service Base URL List'
        description %(
          Verify that the server's list of Service Base URLs can be publicly accessed on the server.
        )

        output :bundle_response

        makes_request :bundle_request

        run do
          get
          assert_response_status(200)
          output bundle_response: resource.to_json
        end      
      end
    end

    group do
      id :service_base_url_bundle_tests
      title 'Service Base URL List Validation'
      description %(These tests ensure that the server's Service Base URL list is in the Bundle resource format, 
      with it's service base URLs and organizational details contained in valid Endpoint and Organization 
      entries that that follow the specifications detailed in the HTI-1 rule in the API Condition and 
      Maintenance of Certification.)
      run_as_group

      #  Valid BUNDLE TESTS
      test do
        id :service_base_url_valid_bundle
        title 'Server returns valid Bundle resource according to FHIR v4.0.1'
        description %(
          Verify that the returned Bundle of Service Base URLs is a valid Bundle resource and that it is not empty.
        )

        input :bundle_response,
          title: 'Service Base URL List Bundle'

        run do
          skip_if bundle_response.blank?, 'No Bundle response was provided'

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
        title 'Service Base URL List Bundle contains valid Endpoint resources.'
        description %(
          Verify that Bundle of Service Base URLs contains Endpoints that are valid Endpoint resources according to the format defined in FHIR v4.0.1.

          Each Endpoint must:
            - Contain must have elements including:
              - status
              - connectionType
              - address
            - Contain a URL in the address field
            - Have at least one Organization resource in the Bundle that references it
        )

        input :bundle_response,
          title: 'Service Base URL List Bundle'

        run do
          
          skip_if bundle_response.blank?, 'No Bundle response was provided'

          bundle_resource = FHIR.from_contents(bundle_response)

          skip_if bundle_resource.entry.empty?, 'The given Bundle does not contain any resources'

          assert_valid_bundle_entries(bundle: bundle_resource,
            resource_types: {
              'Endpoint': nil
            }
          )
          
          endpoint_ids =
            bundle_resource
              .entry
              .map(&:resource)
              .select { |resource| resource.resourceType == 'Endpoint' }
              .map(&:id)


          for endpoint_id in endpoint_ids
            endpoint_referenced_orgs = find_referenced_org(bundle_resource, endpoint_id)
            assert !endpoint_referenced_orgs.empty?, "Endpoint with id: #{endpoint_id} does not have any associated Organizations in the Bundle."

          end
        end      
      end

      # ENDPOINT VALID URL TESTS
      test do
        id :service_base_url_valid_urls
        title 'All Endpoint resource referenced URLS should be valid and available.'
        description %(
          Verify that Bundle of Service Base URLs contains Endpoints that contain service base URLs that are both valid and available.
        )

        output :testing

        input :bundle_response,
          title: 'Service Base URL List Bundle'

        run do
          skip_if bundle_response.blank?, 'No Bundle response was provided'

          bundle_resource = FHIR.from_contents(bundle_response)

          skip_if bundle_resource.entry.empty?, 'The given Bundle does not contain any resources'


          bundle_resource
          .entry
          .map(&:resource)
          .select { |resource| resource.resourceType == 'Endpoint' }
          .map(&:address)
          .each do |address|
            assert_valid_http_uri(address) 

            address = address.delete_suffix("/")
            get("#{address}/metadata", client: nil, headers: {'Accept': 'application/json, application/fhir+json'})
            assert_response_status(200)
            assert_resource_type(:capability_statement)        
          end
        end      
      end


      # ORGANIZATION TESTS
      test do
        id :service_base_url_valid_organizations
        title 'Service Base URL List Bundle contains valid Organization resources.'
        description %(

          Verify that Bundle of Service Base URLs contains Organizations that are valid Organization resources according to the format defined in FHIR v4.0.1.

          Each Organization must:
            - Contain must have elements including:
              - active
              - name
            - Include the organization's name, location, and provider identifier 
            - Use the endpoint field to reference Endpoints associated with the Organization:
              - Must reference only Endpoint resources in the endpoint field
              - Must reference at least one Endpoint resource in the endpoint field
              - Must reference only Endpoints that are contained in the Service Base URL Bundle
        )

        input :bundle_response,
          title: 'Service Base URL List Bundle'

        run do
          skip_if bundle_response.blank?, 'No Bundle response was provided'

          bundle_resource = FHIR.from_contents(bundle_response)

          skip_if bundle_resource.entry.empty?, 'The given Bundle does not contain any resources'

          assert_valid_bundle_entries(bundle: bundle_resource,
            resource_types: {
              'Organization': "http://hl7.org/fhir/us/core/StructureDefinition/us-core-organization"
            }
          )
          
          endpoint_ids =
            bundle_resource
              .entry
              .map(&:resource)
              .select { |resource| resource.resourceType == 'Endpoint' }
              .map(&:id)


          for organization in bundle_resource.entry.map(&:resource).select { |resource| resource.resourceType == 'Organization' }

            assert !organization.endpoint.empty?, "Organization with id: #{organization.id} does not have the endpoint field populated"
            assert !organization.address.empty?, "Organization with id: #{organization.id} does not have the address field populated"

            
            for endpoint_id_ref in organization.endpoint.map(&:reference)
              organization_referenced_endpts = find_referenced_endpoint(bundle_resource, endpoint_id_ref)
              assert !organization_referenced_endpts.empty?, "Organization with id: #{organization.id} references an Endpoint that is not contained in this bundle."
              
            end
          end 
        end      
      end
    end
  end
end
