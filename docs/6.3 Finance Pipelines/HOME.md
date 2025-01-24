# 6.3 Finance Pipelines


Integrations for these systems will be implemented as custom pipeline processors to transform the data and process or read files specific to the boundary application.  They _may_ use components of other common pipelines, especially on inbound, as all but Concur below send data into Oracle of the same types as the common inbound services.

| Boundary System                                                                       | Inbound Type | Outbound Type |
| ------------------------------------------------------------------------------------- | ------------ | ------------- |
| [6.3.4 CashNet](#/6.3%20Finance%20Pipelines/6.3.4%20CashNet/HOME ':ignore')           | SFTP         | Oracle FBDI   |
| [6.3.5 TouchNet](#/6.3%20Finance%20Pipelines/6.3.5%20TouchNet/HOME ':ignore')         | Database     | Oracle FBDI   |
| [6.3.18 AR Lockbox](#/6.3%20Finance%20Pipelines/6.3.18%20AR%20Lockbox/HOME ':ignore') | SFTP         | Oracle FBDI   |
