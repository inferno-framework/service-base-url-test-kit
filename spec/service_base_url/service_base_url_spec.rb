RSpec.describe ServiceBaseURLTestKit::ServiceBaseURLGroup do
  let(:suite) { Inferno::Repositories::TestSuites.new.find('service_base_url') }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:test_session) { repo_create(:test_session, test_suite_id: 'service_base_url') }
  let(:base_url) { 'http://example.com/fhir' }
  let(:service_base_url_publication_url) { 'http://example.com/fhir/bundleEndpointList' }
  let(:runnable) { suite }
  let(:validator_url) { runnable.find_validator(:default).url }

  let(:input) do
    {
      service_base_url_publication_url:,
      endpoint_availability_success_rate: 'all'
    }
  end
  let(:validator_response_success) do
    {
      outcomes: [{
        fileInfo: {
          fileName: '000.json',
          fileContent: '{ "resourceType": "Bundle" }',
          fileType: 'json'
        },
        issues: []
      }],
      sessionId: '4d9d2dc3-5df1-461f-a4d6-bfc2788a1933'
    }
  end
  let(:validator_response_failure) do
    {
      outcomes: [{
        fileInfo: {
          fileName: '000.json',
          fileContent: '{ "resourceType": "Bundle" }',
          fileType: 'json'
        },
        issues: [{
          source: 'InstanceValidator',
          line: 1,
          col: 29,
          location: 'Bundle',
          message: 'Bundle.type: minimum required = 1, but only found 0 (from http://hl7.org/fhir/StructureDefinition/Bundle|4.0.1)',
          messageId: 'Validation_VAL_Profile_Minimum',
          type: 'STRUCTURE',
          level: 'ERROR',
          display: 'ERROR: Bundle: Bundle.type: minimum required = 1, but only found 0 (from http://hl7.org/fhir/StructureDefinition/Bundle|4.0.1)',
          error: true
        }]
      }],
      sessionId: 'b97dfb7c-f7c3-4980-81c3-8adc0024e75b'
    }
  end

  def run(runnable, inputs = {})
    test_run_params = { test_session_id: test_session.id }.merge(runnable.reference_hash)
    test_run = Inferno::Repositories::TestRuns.new.create(test_run_params)
    inputs.each do |name, value|
      session_data_repo.save(
        test_session_id: test_session.id,
        name:,
        value:,
        type: runnable.config.input_type(name) || 'text'
      )
    end
    Inferno::TestRunner.new(test_session:, test_run:).run(runnable)
  end

  describe 'Service Base URL Tests' do
    let(:test) { suite }
    let(:bundle_resource) { FHIR.from_contents(File.read('spec/fixtures/testBundleValid.json')) }
    let(:capability_statement) { FHIR.from_contents(File.read('spec/fixtures/CapabilityStatement.json')) }

    it 'passes if a valid Bundle was received' do
      stub_request(:get, service_base_url_publication_url)
        .to_return(status: 200, body: bundle_resource.to_json, headers: {})

      uri_template = Addressable::Template.new "#{base_url}/{id}/metadata"
      capability_statement_request = stub_request(:get, uri_template)
        .to_return(status: 200, body: capability_statement.to_json, headers: {})

      validation_request = stub_request(:post, "#{validator_url}/validate")
        .with(query: hash_including({}))
        .to_return(status: 200, body: validator_response_success.to_json)

      result = run(test, input)

      expect(result.result).to eq('pass'), %(
          Expected a service base URL publication that returns a publicly accessible valid Bundle to pass
      )
      expect(capability_statement_request).to have_been_made.times(3)
      expect(validation_request).to have_been_made.times(6)
    end

    it 'passes if a valid Bundle was inputted' do
      uri_template = Addressable::Template.new "#{base_url}/{id}/metadata"
      capability_statement_request = stub_request(:get, uri_template)
        .to_return(status: 200, body: capability_statement.to_json, headers: {})

      validation_request = stub_request(:post, "#{validator_url}/validate")
        .with(query: hash_including({}))
        .to_return(status: 200, body: validator_response_success.to_json)

      result = run(test, service_base_url_bundle: bundle_resource.to_json, endpoint_availability_success_rate: 'all')

      expect(result.result).to eq('pass'), %(
        Expected a valid inputted service base url Bundle to pass
    )
      expect(capability_statement_request).to have_been_made.times(3)
      expect(validation_request).to have_been_made.times(6)
    end

    it 'passes if a valid Bundle was received and resource_validation_limit input is entered' do
      stub_request(:get, service_base_url_publication_url)
        .to_return(status: 200, body: bundle_resource.to_json, headers: {})

      uri_template = Addressable::Template.new "#{base_url}/{id}/metadata"
      capability_statement_request = stub_request(:get, uri_template)
        .to_return(status: 200, body: capability_statement.to_json, headers: {})

      validation_request = stub_request(:post, "#{validator_url}/validate")
        .with(query: hash_including({}))
        .to_return(status: 200, body: validator_response_success.to_json)

      input['resource_validation_limit'] = '2'
      result = run(test, input)

      expect(result.result).to eq('pass'), %(
          Expected a service base URL publication that returns a publicly accessible valid Bundle to pass
      )
      expect(capability_statement_request).to have_been_made.times(1)
      expect(validation_request).to have_been_made.times(2)
    end

    it 'skips if no service base URL publication URL or Bundle input provided' do
      result = run(test)

      expect(result.result).to eq('skip'), %(
        Expect tests to skip if no service base URL publication URL or service base URL Bundle inputted.
    )
    end

    it 'fails if an invalid Bundle was received' do
      # Remove a required field from Bundle resource
      bundle_resource.type = ''

      stub_request(:get, service_base_url_publication_url)
        .to_return(status: 200, body: bundle_resource.to_json, headers: {})

      uri_template = Addressable::Template.new "#{base_url}/{id}/metadata"
      stub_request(:get, uri_template)
        .to_return(status: 200, body: capability_statement.to_json, headers: {})

      # validator returns a error operation outcome
      validation_request = stub_request(:post, "#{validator_url}/validate")
        .with(query: hash_including({}))
        .to_return(status: 200, body: validator_response_failure.to_json)

      result = run(test, input)

      expect(result.result).to eq('fail'), %(
          Expected if validation service responds with a validation fail or Bundle resource that is invalid.
      )
      expect(validation_request).to have_been_made.times(6)
    end

    it 'fails if Bundle contains endpoint that do not return a successful capability statement' do
      # change one of the Endpoint addresses to a URL that does not successfully return a capability statement
      bundle_resource.entry[4].resource.address = "#{base_url}/fake/address"

      stub_request(:get, service_base_url_publication_url)
        .to_return(status: 200, body: bundle_resource.to_json, headers: {})

      # this endpoint address capability statement endpoint will return a 404
      capability_statement_request_fail = stub_request(:get, "#{base_url}/fake/address/metadata")
        .to_return(status: 404, body: '', headers: {})

      uri_template = Addressable::Template.new "#{base_url}/{id}/metadata"
      capability_statement_request_success = stub_request(:get, uri_template)
        .to_return(status: 200, body: capability_statement.to_json, headers: {})

      validation_request = stub_request(:post, "#{validator_url}/validate")
        .with(query: hash_including({}))
        .to_return(status: 200, body: validator_response_success.to_json)

      result = run(test, input)

      expect(result.result).to eq('fail'), %(
          Expected test to fail when Bundle contains endpoint that does not return a successful 200
      )
      expect(capability_statement_request_success).to have_been_made.times(2)
      expect(capability_statement_request_fail).to have_been_made
      expect(validation_request).to have_been_made.times(6)
    end

    it 'passes and only checks the availability of number of endpoints equal to the endpoint availability limit' do
      stub_request(:get, service_base_url_publication_url)
        .to_return(status: 200, body: bundle_resource.to_json, headers: {})

      uri_template = Addressable::Template.new "#{base_url}/{id}/metadata"
      capability_statement_request_success = stub_request(:get, uri_template)
        .to_return(status: 200, body: capability_statement.to_json, headers: {})

      validation_request = stub_request(:post, "#{validator_url}/validate")
        .with(query: hash_including({}))
        .to_return(status: 200, body: validator_response_success.to_json)

      result = run(test, service_base_url_publication_url:, endpoint_availability_success_rate: 'all',
                         endpoint_availability_limit: 2)

      expect(result.result).to eq('pass')
      expect(capability_statement_request_success).to have_been_made.times(2)
      expect(validation_request).to have_been_made.times(6)
    end

    it 'passes if at least 1 endpoint is available when success rate input is set to at least 1' do
      bundle_resource.entry[4].resource.address = "#{base_url}/fake/address/3"
      bundle_resource.entry[0].resource.address = "#{base_url}/fake/address/1"

      stub_request(:get, service_base_url_publication_url)
        .to_return(status: 200, body: bundle_resource.to_json, headers: {})

      fake_uri_template = Addressable::Template.new "#{base_url}/fake/address/{id}/metadata"
      capability_statement_request_fail = stub_request(:get, fake_uri_template)
        .to_return(status: 404, body: '', headers: {})

      uri_template = Addressable::Template.new "#{base_url}/{id}/metadata"
      capability_statement_request_success = stub_request(:get, uri_template)
        .to_return(status: 200, body: capability_statement.to_json, headers: {})

      validation_request = stub_request(:post, "#{validator_url}/validate")
        .with(query: hash_including({}))
        .to_return(status: 200, body: validator_response_success.to_json)

      result = run(test, service_base_url_publication_url:, endpoint_availability_success_rate: 'at_least_1')

      expect(result.result).to eq('pass')
      expect(capability_statement_request_fail).to have_been_made.times(2)
      expect(capability_statement_request_success).to have_been_made
      expect(validation_request).to have_been_made.times(6)
    end

    it 'passes and does not retrieve any capability statements if success rate input set to none' do
      stub_request(:get, service_base_url_publication_url)
        .to_return(status: 200, body: bundle_resource.to_json, headers: {})

      uri_template = Addressable::Template.new "#{base_url}/{id}/metadata"
      capability_statement_request_success = stub_request(:get, uri_template)
        .to_return(status: 200, body: capability_statement.to_json, headers: {})

      validation_request = stub_request(:post, "#{validator_url}/validate")
        .with(query: hash_including({}))
        .to_return(status: 200, body: validator_response_success.to_json)

      result = run(test, service_base_url_publication_url:, endpoint_availability_success_rate: 'none')

      expect(result.result).to eq('pass')
      expect(capability_statement_request_success).to have_been_made.times(0)
      expect(validation_request).to have_been_made.times(6)
    end

    it 'fails if Bundle contains endpoint that has an invalid URL in the address field' do
      bundle_resource.entry[4].resource.address = 'invalid_url%.com'

      stub_request(:get, service_base_url_publication_url)
        .to_return(status: 200, body: bundle_resource.to_json, headers: {})

      uri_template = Addressable::Template.new "#{base_url}/{id}/metadata"
      capability_statement_request = stub_request(:get, uri_template)
        .to_return(status: 200, body: capability_statement.to_json, headers: {})

      validation_request = stub_request(:post, "#{validator_url}/validate")
        .with(query: hash_including({}))
        .to_return(status: 200, body: validator_response_success.to_json)

      result = run(test, input)

      expect(result.result).to eq('fail'), %(
          Expected test to fail when Bundle contains endpoint that has an invalid URL in address field
      )
      expect(capability_statement_request).to have_been_made.times(2)
      expect(validation_request).to have_been_made.times(6)
    end

    it 'fails if Bundle contains an Organization that does not have the endpoint field populated' do
      org = FHIR::Organization.new(
        name: 'Test Medical Center 4',
        active: true,
        identifier: [{
          system: 'http://hl7.org/fhir/sid/us-npi',
          value: '1396251542'
        }],
        address: [
          {
            line: ['200 River Green Ave'],
            city: 'Canton',
            state: 'GA',
            postalCode: '30114',
            country: 'United States of America'
          }
        ]
      )

      bundle_resource.entry.append(FHIR::Bundle::Entry.new(
                                     fullUrl: 'https://example.com/base/Organization/example-organization-4',
                                     resource: org
                                   ))

      stub_request(:get, service_base_url_publication_url)
        .to_return(status: 200, body: bundle_resource.to_json, headers: {})

      uri_template = Addressable::Template.new "#{base_url}/{id}/metadata"
      stub_request(:get, uri_template)
        .to_return(status: 200, body: capability_statement.to_json, headers: {})

      validation_request = stub_request(:post, "#{validator_url}/validate")
        .with(query: hash_including({}))
        .to_return(status: 200, body: validator_response_success.to_json)

      result = run(test, input)

      expect(result.result).to eq('fail'), %(
          Expected if Organization within the bundle does not have the endpoint field, then test will fail.
      )
      expect(validation_request).to have_been_made.times(7)
    end

    it 'passes if Bundle contains an Organization that has a parent org with the endpoint field populated' do
      child_org = FHIR::Organization.new(
        name: 'Test Medical Center 4',
        id: 'example-organization-4',
        active: true,
        identifier: [{
          system: 'http://hl7.org/fhir/sid/us-npi',
          value: '1396251542'
        }],
        address: [
          {
            line: ['200 River Green Ave'],
            city: 'Canton',
            state: 'GA',
            postalCode: '30114',
            country: 'United States of America'
          }
        ],
        partOf: {
          reference: 'Organization/example-organization-1'
        }
      )

      bundle_resource.entry.append(FHIR::Bundle::Entry.new(
                                     fullUrl: 'https://example.com/base/Organization/example-organization-4',
                                     resource: child_org
                                   ))

      stub_request(:get, service_base_url_publication_url)
        .to_return(status: 200, body: bundle_resource.to_json, headers: {})

      uri_template = Addressable::Template.new "#{base_url}/{id}/metadata"
      stub_request(:get, uri_template)
        .to_return(status: 200, body: capability_statement.to_json, headers: {})

      validation_request = stub_request(:post, "#{validator_url}/validate")
        .with(query: hash_including({}))
        .to_return(status: 200, body: validator_response_success.to_json)
      result = run(test, input)
      expect(result.result).to eq('pass')
      expect(validation_request).to have_been_made.times(7)
    end

    it 'fails if Bundle contains an Organization that references a fake Endpoint' do
      # add organization resource to bundle that does not reference an Endpoint contained in the Bundle
      org = FHIR::Organization.new(
        name: 'Test Medical Center 4',
        active: true,
        identifier: [{
          system: 'http://hl7.org/fhir/sid/us-npi',
          value: '1396251542'
        }],
        address: [
          {
            line: ['200 River Green Ave'],
            city: 'Canton',
            state: 'GA',
            postalCode: '30114',
            country: 'United States of America'
          }
        ],
        endpoint: [{ reference: 'Endpoint/fake-reference' }]
      )

      bundle_resource.entry.append(FHIR::Bundle::Entry.new(
                                     fullUrl: 'https://example.com/base/Organization/example-organization-4',
                                     resource: org
                                   ))

      stub_request(:get, service_base_url_publication_url)
        .to_return(status: 200, body: bundle_resource.to_json, headers: {})

      uri_template = Addressable::Template.new "#{base_url}/{id}/metadata"
      stub_request(:get, uri_template)
        .to_return(status: 200, body: capability_statement.to_json, headers: {})

      validation_request = stub_request(:post, "#{validator_url}/validate")
        .with(query: hash_including({}))
        .to_return(status: 200, body: validator_response_success.to_json)

      result = run(test, input)

      expect(result.result).to eq('fail'), %(
          Expected if Organization within the bundle references an Endpoint not in the Bundle, then test will fail.
      )
      expect(validation_request).to have_been_made.times(7)
    end

    it 'fails if Bundle contains an Endpoint that does have an associated Organization reference' do
      # Remove the last Organizaition entry so that one Endpoint does not have an Organization resource that references it
      bundle_resource.entry.delete_at(3)

      stub_request(:get, service_base_url_publication_url)
        .to_return(status: 200, body: bundle_resource.to_json, headers: {})

      uri_template = Addressable::Template.new "#{base_url}/{id}/metadata"
      stub_request(:get, uri_template)
        .to_return(status: 200, body: capability_statement.to_json, headers: {})

      validation_request = stub_request(:post, "#{validator_url}/validate")
        .with(query: hash_including({}))
        .to_return(status: 200, body: validator_response_success.to_json)

      result = run(test, input)

      expect(result.result).to eq('fail'), %(
          Expected if Endpoint within bundle does not have an Organization that references it, then test will fail.
      )
      expect(validation_request).to have_been_made.times(5)
    end
  end
end
