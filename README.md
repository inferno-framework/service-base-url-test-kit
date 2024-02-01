# Service Base URL Test Kit


The **Service Base URL Test Kit** is a testing tool that provides a set of tests
to validate conformance to the
[HTI-1](https://www.healthit.gov/topic/laws-regulation-and-policy/health-data-technology-and-interoperability-certification-program)
[rule](https://www.federalregister.gov/d/2023-07229/p-195) to the API Condition
and Maintenance of Certification to include the requirement for Certified API
Developers with patient-facing apps to publish their service base URLs in [a
specified format](https://www.federalregister.gov/d/2023-07229/p-2342).

This HTI-1 rule requires that a Certified API developer must publish, at no
charge, the service base URLs and related organizational details that can be
used by patients to access their electronic health information. These service
base URLs and organizational details must conform to the following:
  - Service based URLs must be publicly published in Endpoint resource format
    according to the standard adopted in § 170.215(a) - FHIR 4.0.1 release 
  - Organization details for each service base URL must be publicly published in
    Organization resource format according to the standard adopted in §
    170.215(a) - FHIR 4.0.1 release 
  - Each Organization resource must contain:
    - A reference in the Organization.endpoint element, to the Endpoint
      resources containing service base URLs managed by this organization
    - The organization's name, location, and provider identifier 
    - Endpoint and Organization resources must be:
      - Collected into a Bundle resource formatted according to the standard
        adopted in FHIR v4.0.1: § 170.215(a) for publication
      - Reviewed quarterly and, as necessary, updated

The Service Base URL Test Kit is built using the [Inferno
Framework](https://inferno-framework.github.io/).  The Inferno Framework is
designed for reuse and aims to make it easier to build test kits for any
FHIR-based data exchange.

## Reporting Issues

This is a draft set of tests and may contain errors or issues, please provide
feedback on these tests within the [GitHub
Issues](https://github.com/inferno-framework/service-base-url-test-kit/issues).

## Instructions

- Clone this repo.
- Run `setup.sh` in this repo.
- Run `run.sh` in this repo.
- Navigate to `http://localhost`. The Service Base URL test suite will be
  available.

See the [Inferno Framework
Documentation](https://inferno-framework.github.io/inferno-core/getting-started.html#getting-started-for-inferno-users)
for more information on running Inferno.

## License
Copyright 2023 The MITRE Corporation

Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this file except in compliance with the License. You may obtain a copy of the
License at
```
http://www.apache.org/licenses/LICENSE-2.0
```
Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied. See the License for the
specific language governing permissions and limitations under the License.


## Trademark Notice

HL7, FHIR and the FHIR [FLAME DESIGN] are the registered trademarks of Health
Level Seven International and their use does not constitute endorsement by HL7.
