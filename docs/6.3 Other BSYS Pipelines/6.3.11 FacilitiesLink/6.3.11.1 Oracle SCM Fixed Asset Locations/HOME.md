# 6.3.11.1 Oracle SCM Fixed Asset Locations


#### Summary

Oracle users will use Value Sets to record asset location details in the Fixed Assets module.

Oracle requires inbound pipelines that will synchronize FacilitiesLink:
1. building data with the **UCD BUILDING CODE** value set.
2. room data with the **UCD ROOM** value set.

#### General Process Flow

1. Each day, extract buildings and room records which were modified yesterday from the AIT INT database.
2. Transform the records into individual JSON records that conform to the `in.internal.scmFixedAssetValueSet-value` schema.
3. Determine whether the location has already been loaded into Oracle by checking the VALUE_SET_TYPED_VALUES_PVO table in the PostgeSQL integration database.
   a. If so, perform an update.
   b. If not, perform an insert. 
4. Call the Oracle SCM REST API to upsert the location.

#### Maintenance History

1. [AEI-2229](https://afs-dev.ucdavis.edu/jira/browse/AEI-2229) FacilitiesLink import of campus buildings and rooms to Fixed Asset module
2. [INT-1391](https://afs-dev.ucdavis.edu/jira/browse/INT-1391) NIFI: Oracle FA Location Maintenance (6.3.11.1) - Exclude locations that have no CAAN numbers