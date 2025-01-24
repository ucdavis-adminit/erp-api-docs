# 6.3.14.3 Dynamics SL ERP Sync


#### Summary

This pipeline extracts ERP Purchase Category data from the Integration Database and updates or creates in Dynamics SL as MaterialType.

#### General Process Flow

1. Pull all SCM Purchasing Categories
2. Lookup corresponding Material Type in DSL.
3. If the Material Type exists in DSL then update
   1. Only update if the MaterialType Status or Description will change
   2. Fields LUpd_Prog and LUpd_User will be updated with 'NIFI'
4. If the Material Type does not exist then create
   1. Create MaterialType record
   2. Validate against schema
   3. Fields Crtd_Prog and Crtd_User will be created with the value 'NIFI'
   4. Write Record

#### Pipeline Dependencies

* NONE


