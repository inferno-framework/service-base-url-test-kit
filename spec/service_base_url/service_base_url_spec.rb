RSpec.describe ServiceBaseURLTestKit::ServiceBaseURLGroup do
  let(:suite) { Inferno::Repositories::TestSuites.new.find('service_base_url_test_kit_suite') }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:test_session) { repo_create(:test_session, test_suite_id: 'service_base_url_test_kit_suite') }
  let(:base_url) { 'http://example.com/fhir' }
  let(:service_base_url_list_endpoint) { 'http://example.com/fhir/bundleEndpointList' }
  let(:error_outcome) { FHIR::OperationOutcome.new(issue: [{ severity: 'error' }]) }

  let(:runnable) { suite }
  let(:validator_url) { runnable.find_validator(:default).url }
  
  let(:input) do
    {
      service_base_url_list_endpoint:
    }
  end
  let(:operation_outcome_success) do
    FHIR::OperationOutcome.new(
      issue: [
        {
          severity: 'information',
          code: 'informational',
          details: {
            text: 'All OK'
          }
        }
      ]
    )
  end
  let(:operation_outcome_success) do
    FHIR::OperationOutcome.new(
      issue: [
        {
          severity: 'information',
          code: 'informational',
          details: {
            text: 'All OK'
          }
        }
      ]
    )
  end
  let(:operation_outcome_failure) do
    FHIR::OperationOutcome.new(
      issue: [
        {
          severity: 'error',
          code: 'required',
          details: {
            text: 'Bundle.type: minimum required = 1, but only found 0 (from http://hl7.org/fhir/StructureDefinition/Bundle|4.0.1)'
          },
          expression: [
            'Bundle'
          ]
        }
      ]
    )
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

  #suite.groups.first.tests.first

  # require 'debug/open_nonstop'
  # debugger
  
  describe 'Service Base URL Tests' do
    let(:test) { suite }
    let(:bundle_resource_valid) { FHIR.from_contents(File.read('spec/fixtures/testBundleValid.json')) }
    let(:bundle_resource_invalid) { FHIR.from_contents(File.read('spec/fixtures/testBundleInvalid.json')) }
    let(:bundle_resource_InvalidEndpointRef) { FHIR.from_contents(File.read('spec/fixtures/testBundleIncorrectEndpointRef.json')) }
    let(:bundle_resource_MissingOrg) { FHIR.from_contents(File.read('spec/fixtures/testBundleMissingOrg.json')) }
    let(:capability_statement) { FHIR.from_contents(File.read('spec/fixtures/CapabilityStatement.json')) }

    it 'passes if a valid Bundle was received' do
      
      stub_request(:get, service_base_url_list_endpoint)
        .to_return(status: 200, body: bundle_resource_valid.to_json, headers: {})

      
      uri_template = Addressable::Template.new "#{base_url}/{id}/metadata"
      capability_statement_request = stub_request(:get, uri_template)
        .to_return(status: 200, body: capability_statement.to_json, headers: {})

      validation_request = stub_request(:post, "#{validator_url}/validate")
        .with(query: hash_including({}))
        .to_return(status: 200, body: operation_outcome_success.to_json)

      result = run(test, input)

      expect(result.result).to eq('pass'), "Expected a service base URL list that returns a publicly accessible valid Bundle resource to pass test."
      expect(capability_statement_request).to have_been_made.times(3)
    end

    it 'fails if an invalid Bundle was received' do
      
      stub_request(:get, service_base_url_list_endpoint)
        .to_return(status: 200, body: bundle_resource_invalid.to_json, headers: {})

      
      uri_template = Addressable::Template.new "#{base_url}/{id}/metadata"
      stub_request(:get, uri_template)
        .to_return(status: 200, body: capability_statement.to_json, headers: {})

      validation_request = stub_request(:post, "#{validator_url}/validate")
        .with(query: hash_including({}))
        .to_return(status: 200, body: operation_outcome_failure.to_json)

      result = run(test, input)

      expect(result.result).to eq('fail'), "Expected if validation of an invalid Bundle resource fails that the entire test fails."
    end


    it 'fails if Bundle contains an Organization that references a fake Endpoint' do
      
      stub_request(:get, service_base_url_list_endpoint)
        .to_return(status: 200, body: bundle_resource_InvalidEndpointRef.to_json, headers: {})

      
      uri_template = Addressable::Template.new "#{base_url}/{id}/metadata"
      stub_request(:get, uri_template)
        .to_return(status: 200, body: capability_statement.to_json, headers: {})

      validation_request = stub_request(:post, "#{validator_url}/validate")
        .with(query: hash_including({}))
        .to_return(status: 200, body: operation_outcome_success.to_json)

      result = run(test, input)

      expect(result.result).to eq('fail'), "Expected if Organization within the bundle references a fake Endpoint then test will fail."
    end

    it 'fails if Bundle contains an Endpoint that does have an associated Organization reference' do
      
      stub_request(:get, service_base_url_list_endpoint)
        .to_return(status: 200, body: bundle_resource_MissingOrg.to_json, headers: {})

      
      uri_template = Addressable::Template.new "#{base_url}/{id}/metadata"
      stub_request(:get, uri_template)
        .to_return(status: 200, body: capability_statement.to_json, headers: {})

      validation_request = stub_request(:post, "#{validator_url}/validate")
        .with(query: hash_including({}))
        .to_return(status: 200, body: operation_outcome_success.to_json)

      result = run(test, input)

      expect(result.result).to eq('fail'), "Expected if Endpoint within bundle does not have an Organization that references it then test will fail"
    end


  end

  #     it 'fails if a 200 is not received' do
  #       resource = FHIR::Patient.new(id: patient_id)
  #       stub_request(:get, "#{url}/Patient/#{patient_id}")
  #         .to_return(status: 201, body: resource.to_json)

  #       result = run(test, url: url, patient_id: patient_id)

  #       expect(result.result).to eq('fail')
  #       expect(result.result_message).to match(/200/)
  #     end

  #     it 'fails if a Patient is not received' do
  #       resource = FHIR::Condition.new(id: patient_id)
  #       stub_request(:get, "#{url}/Patient/#{patient_id}")
  #         .to_return(status: 200, body: resource.to_json)

  #       result = run(test, url: url, patient_id: patient_id)

  #       expect(result.result).to eq('fail')
  #       expect(result.result_message).to match(/Patient/)
  #     end

  #     it 'fails if the id received does not match the one requested' do
  #       resource = FHIR::Patient.new(id: '456')
  #       stub_request(:get, "#{url}/Patient/#{patient_id}")
  #         .to_return(status: 200, body: resource.to_json)

  #       result = run(test, url: url, patient_id: patient_id)

  #       expect(result.result).to eq('fail')
  #       expect(result.result_message).to match(/resource with id/)
  #     end
  #   end

  #   describe 'validation test' do
  #     let(:test) { group.tests.last }

  #     it 'passes if the resource is valid' do
  #       stub_request(:post, "#{ENV.fetch('VALIDATOR_URL')}/validate")
  #         .with(query: hash_including({}))
  #         .to_return(status: 200, body: FHIR::OperationOutcome.new.to_json)

  #       resource = FHIR::Patient.new
  #       repo_create(
  #         :request,
  #         name: :patient,
  #         test_session_id: test_session.id,
  #         response_body: resource.to_json
  #       )

  #       result = run(test)

  #       expect(result.result).to eq('pass')
  #     end

  #     it 'fails if the resource is not valid' do
  #       stub_request(:post, "#{ENV.fetch('VALIDATOR_URL')}/validate")
  #         .with(query: hash_including({}))
  #         .to_return(status: 200, body: error_outcome.to_json)

  #       resource = FHIR::Patient.new
  #       repo_create(
  #         :request,
  #         name: :patient,
  #         test_session_id: test_session.id,
  #         response_body: resource.to_json
  #       )

  #       result = run(test)

  #       expect(result.result).to eq('fail')
  #     end
    # end
  # end
end
