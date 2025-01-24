# 6.3 Payroll-HR Pipelines


Integrations for these systems will be implemented as custom pipeline processors to transform the data and process or read files specific to the boundary application.  They _may_ use components of other common pipelines, especially on inbound, as all but Concur below send data into Oracle of the same types as the common inbound services.

| Boundary System                                                              | Inbound Type   | Outbound Type |
| ---------------------------------------------------------------------------- | -------------- | ------------- |
| [6.3.7 UCPath](#/6.3%20Payroll-HR%20Pipelines/6.3.7%20UCPath/HOME ':ignore') | Database (ODS) | Oracle FBDI   |
