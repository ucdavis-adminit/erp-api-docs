# 6.3.11.2 Oracle SCM Procurement Locations

#### Summary

Oracle users will use location codes to record the ship-to address when creating requisitions in the Procurement module.

Oracle requires an inbound pipeline that will synchronize FacilitiesLink building and room data with the Procurement Locations.

#### General Process Flow

1. Each day, extract buildings and room records which were modified yesterday from the AIT INT database.
2. Transform the records into individual JSON records.
3. Determine whether the location has already been loaded into Oracle by checking the ERP_LOCATIONS table in the integration database.
   a. If so, set the appropriate record fields for update.
   b. If not, set the appropriate record fields for insert. 
   c. If it's inactive in FacilitiesLink and not already in Oracle, ignore it.
4. Record the location in the `#{int_db_staging_schema}.fac_facilitieslink_procurement_locations` table.
4. Write the records to a file named Location.dat and pack the file into a ZIP file.
5. Load the ZIP file into Oracle UCM using the UCM SOAP API.
6. Call HCM Data Loader SOAP API to import the contents of the ZIP file from UCM into Oracle.
7. Gather the HCM Process ID from the API response and log an entry into the Oracle Job Status table.

#### Maintenance History

1. [AEI-2228](https://afs-dev.ucdavis.edu/jira/browse/AEI-2228) FacilitiesLink import of campus buildings and rooms into Procurement module