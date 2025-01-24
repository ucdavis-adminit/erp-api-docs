# 6.3 Other BSYS Pipelines


Integrations for these systems will be implemented as custom pipeline processors to transform the data and process or read files specific to the boundary application.  They _may_ use components of other common pipelines, especially on inbound, as all but Concur below send data into Oracle of the same types as the common inbound services.

| Boundary System                                                                                  | Inbound Type | Outbound Type |
| ------------------------------------------------------------------------------------------------ | ------------ | ------------- |
| [6.3.6 UCDH](#/6.3%20Other%20BSYS%20Pipelines/6.3.6%20UCDH/HOME ':ignore')                       | Database     | SFTP          |
| [6.3.8 EPM](#/6.3%20Other%20BSYS%20Pipelines/6.3.8%20EPM/HOME ':ignore')                         | Database     | S3            |
| [6.3.9 Reprographics](#/6.3%20Other%20BSYS%20Pipelines/6.3.9%20Reprographics/HOME ':ignore')     | Multiple     |               |
| [6.3.11 FacilitiesLink](#/6.3%20Other%20BSYS%20Pipelines/6.3.11%20FacilitiesLink/HOME ':ignore') |              |               |
| [6.3.12 EnergyCAP](#/6.3%20Other%20BSYS%20Pipelines/6.3.12%20EnergyCAP/HOME ':ignore')           |              |               |
| [6.3.13 FleetFocus M5](#/6.3%20Other%20BSYS%20Pipelines/6.3.13%20FleetFocus%20M5/HOME ':ignore') |              |               |
| [6.3.14 Dynamics SL](#/6.3%20Other%20BSYS%20Pipelines/6.3.14%20Dynamics%20SL/HOME ':ignore')     |              |               |
| [6.3.15 Fleet Parking](#/6.3%20Other%20BSYS%20Pipelines/6.3.15%20Fleet%20Parking/HOME ':ignore') | Database     |               |
