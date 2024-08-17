# Service Base URL Test Kit

The **Service Base URL Test Kit** provides a set of tests that verify
conformance of Service Base URL publications to data format requirements as
described in [Conditions and Maintenance of Certification - Application
programming
interfaces](https://www.ecfr.gov/current/title-45/subtitle-A/subchapter-D/part-170/subpart-D/section-170.404#p-170.404(b)(2))
and the [ONC HTI-1 Final
Rule](https://www.healthit.gov/topic/laws-regulation-and-policy/health-data-technology-and-interoperability-certification-program).
Please review the [Application Programming Interfaces Certification Companion
Guide](https://www.healthit.gov/condition-ccg/application-programming-interfaces)
for additional guidance.

This Test Kit is provided as a tool to help developers identify potential issues
or problems with the structure of their Service Base URL publication.  Test
failures do not necessarily indicate non-conformance to the Conditions and
Maintenance of Certification.  Use of these tests is not required for the
participants of the ONC Health IT Certification Program. Please provide feedback
on these tests by reporting an issue in
[GitHub](https://github.com/inferno-framework/service-base-url-test-kit/issues),
or by reaching out to the team on the [Inferno FHIR Zulip
channel](https://chat.fhir.org/#narrow/stream/179309-inferno).

Relevant requirements from the [Conditions and Maintenance of Certification -
Application programming interfaces](https://www.ecfr.gov/current/title-45/subtitle-A/subchapter-D/part-170/subpart-D/section-170.404#p-170.404(b)(2)):

> Service Base URL publication:
> 
> For all Health IT Modules certified to § 170.315(g)(10), a Certified API
> Developer must publish, at no charge, the service base URLs and related
> organization details that can be used by patients to access their
> electronic health information, by December 31, 2024. This includes all
> customers regardless of whether the Health IT Modules certified to §
> 170.315(g)(10) are centrally managed by the Certified API Developer or
> locally deployed by an API Information Source. These service base URLs and
> organization details must conform to the following:
> 
>   - Service base URLs must be publicly published in Endpoint resource format
>     according to the standard adopted in § 170.215(a) (FHIR v4.0.1).
>   - Organization details for each service base URL must be publicly published in Organization
>     resource format according to the standard adopted in § 170.215(a) (FHIR v4.0.1). Each
>     Organization resource must contain: 
>     - A reference, in the Organization endpoint element, to the Endpoint
>       resources containing service base URLs managed by this organization.
>     - The organization’s name, location, and facility identifier.
>   - Endpoint and Organization resources must be:
>     - Collected into a Bundle resource formatted according to the standard
>       adopted in § 170.215(a) (FHIR v4.0.01) for publication; 
>     - and Reviewed quarterly and, as
>       necessary, updated.


## Local Use Instructions

This Test Kit requires either Docker Desktop or Podman to be run in a local
desktop environment.

- Clone this repository.
- Run `setup.sh` in this repo.
- Run `run.sh` in this repo.
- Navigate to `http://localhost`. The Service Base URL test suite will be
  available.

See the [Inferno Framework
Documentation](https://inferno-framework.github.io/inferno-core/getting-started.html#getting-started-for-inferno-users)
for more information on running Inferno.

## License
Copyright 2024 The MITRE Corporation

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
