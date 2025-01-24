# 6.3 SCM Pipelines


Integrations for these systems will be implemented as custom pipeline processors to transform the data and process or read files specific to the boundary application.  They _may_ use components of other common pipelines, especially on inbound, as all but Concur below send data into Oracle of the same types as the common inbound services.

| Boundary System                                                                                       | Inbound Type | Outbound Type |
| ----------------------------------------------------------------------------------------------------- | ------------ | ------------- |
| [6.3.1 Concur](#/6.3%20SCM%20Pipelines/6.3.1%20Concur/HOME ':ignore')                                 | SFTP         | Oracle FBDI   |
| [6.3.2 AggieShip](#/6.3%20SCM%20Pipelines/6.3.2%20AggieShip/HOME ':ignore')                           | SFTP         | Oracle FBDI   |
| [6.3.3 SC Logic](#/6.3%20SCM%20Pipelines/6.3.3%20SC%20Logic/HOME ':ignore')                           | Database     | SFTP          |
| [6.3.10 Mail Center Manager](#/6.3%20SCM%20Pipelines/6.3.10%20Mail%20Center%20Manager/HOME ':ignore') | Database     | Oracle FBDI   |
