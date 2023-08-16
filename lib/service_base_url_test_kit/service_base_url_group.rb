module ServiceBaseURLTestKit
  class ServiceBaseURLGroup < Inferno::TestGroup
    title 'Service Base URL List Tests'
    description %(    
    These tests verify that the server makes Service Base URL list publicly available in the Bundle format with valid Endpoint and Organization entries.

    A Certified API developer must publish, at no charge, the service base URLs and related organizational details that can be used by patients to access their electronic health information
    These service base URLs and organizational details must conform to the following:
      - Service based URLs must be publicly published in Endpoint resource format according to the standard adopted in § 170.215\(a\) - 
        FHIR 4.0.1 release 
      - Organization details for each service base URL must be publicly published in Organization resource format according to the implementation 
        specifications adopted in the US Core: § 170.215\(b\)\(1\)\)
      - Each Organization resource must contain:
        - A reference in the Organization.endpoint element, to the Endpoint resources containing service base URLs managed by this organization
        - The organization's name, location, and provider identifier 
      - Endpoint and Organization resources must be:
        - Collected into a Bundle resource formatted according to the standard adopted in FHIR v4.0.1: § 170.215\(a\) for publication
        - Reviewed quarterly and, as necessary, updated
    )

    id :service_base_url_group

    input :service_base_url_list_endpoint,
        title: 'Service Base URL List endpoint URL'

    http_client do
      url :service_base_url_list_endpoint
      headers 'Content-Type': 'application/json'
    end

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
    
    require 'uri'
    
    # @private
    def valid_url?(url)
      uri = URI.parse(url)
      uri.is_a?(URI::HTTP) && uri.host.present?
    rescue URI::InvalidURIError
      false
    end


    test do
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

    #  Valid BUNDLE TESTS
    test do
      title 'Server returns valid Bundle resource according to FHIR v4.0.1'
      description %(
        Verify that Bundle of Service Base URLs is a valid Bundle resource and that it is not empty.
      )

      input :bundle_response,
        title: 'Service Base URL List Bundle'

      run do
        bundle_resource = FHIR.from_contents(bundle_response)
        assert_valid_resource(resource: bundle_resource)

        assert_resource_type(:bundle, resource: bundle_resource)
        info do
          assert !bundle_resource.entry.empty?, %(
            The given bundle does not have any resources included in it.
          )
        end
      end      
    end

    # VALID ENDPOINT TESTS
    test do
      title 'Service Base URL List Bundle contains valid Endpoint resources.'
      description %(
        Verify that Bundle of Service Base URLs contains Endpoints that are valid Endpoint resources according to FHIR v4.0.1.

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
        bundle_resource = FHIR.from_contents(bundle_response)

        skip_if bundle_resource.entry.empty?, 'This test is being skipped because bundle is empty'

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
      title 'All Endpoint resource referenced URLS should be valid and available.'
      description %(
        Verify that Bundle of Service Base URLs contains Endpoints that contain URLs that are both valid and available.
      )

      output :testing

      input :bundle_response,
        title: 'Service Base URL List Bundle'

      run do
        bundle_resource = FHIR.from_contents(bundle_response)

        skip_if bundle_resource.entry.empty?, 'This test is being skipped because bundle is empty'


        bundle_resource
        .entry
        .map(&:resource)
        .select { |resource| resource.resourceType == 'Endpoint' }
        .map(&:address)
        .each do |address|
          assert valid_url?(address), "#{address} is not a valid URL" 

          client = FHIR::Client.new(address)
          client.capability_statement
          
          assert client.reply.response[:code] == 200, "Endpoint with address #{address} did not return a successful 200 response when querying its capability statement"
          cap_stat = FHIR.from_contents(client.reply.response[:body])
          assert cap_stat.resourceType == "CapabilityStatement", "Endpoint with address #{address} did not return a capability statement resource"          

        end
      end      
    end


    # ORGANIZATION TESTS
    test do
      title 'Service Base URL List Bundle contains valid Organization resources.'
      description %(
        Verify that Bundle of Service Base URLs contains Organizations that are valid Organization resources according to US Core.

        Each Organization must:
          - Follow the US Core implementation specification for the Organization resource
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
        bundle_resource = FHIR.from_contents(bundle_response)

        skip_if bundle_resource.entry.empty?, 'This test is being skipped because bundle is empty'

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
