# 6.3.1.2 Traveller Reimbursements

### Data Flow Design

#### 1.Traveler Reimbursement Data Extract

1. We will be getting flow from Traveler Reimbursement funnel after Split SAE processing.
2. Select appropriate values to create Payment Request
3. Do not run records through GL and PPM validations
4. Don't have to provide kickout account - it is provided in consumer_mapping
5. Verify that date is in format `YYYY-MM-DD`
6. Convert the overall format of the data into the format required by the Payment Request
7. Validate against `ap_payment_request` schema
8. Feed into the validated input into an interim topic `in.<env>.internal.json.apPaymentRequest`
    1. Topic: `in.<env>.internal.json.apPaymentRequest`
    2. Headers: `.*`
    3. Kafka Key: `${source.id}`

### Questions

1. Do we need to validate if employee banking account is active? Check if `EmployeeBankingAccountisActive_291` == `Y` (Y - active)
2. if CHECK is selected and no address - do we enter Generic  Address? Ie. 1 Shield ave? In tech doc it sad stop processing? Do we error out?
3. If ACH is selected and no bank info found - do we write check instead? In tech docs noted to stop processing?  Do we  error out? Or write check?

### Traveler Reimbursement to Payment Input Mapping

| Payment Input Field            | Concur  Field                                       | Notes                                 |
| ------------------------------ | --------------------------------------------------- | ------------------------------------- |
| **Batch Source Information**   |                                                     |                                       |
| `consumerId`                   | UCD Concur                                          |                                       |
| `boundaryApplicationName`      | Concur                                              |                                       |
| `consumerReferenceId`          | Concur_yyyyMMddHHmmss                               |                                       |
| `consumerTrackingId`           | Concur_yyyyMMddHHmmss                               |                                       |
| `consumerNotes`                | (unset)                                             |                                       |
| `requestSourceType`            |                                                     | Do not populate - will be generated   |
| `requestSourceId`              |                                                     | Do not populate - will be generated   |
| **Payment Source Information** |                                                     |                                       |
| `paymentSourceName`            | UCD Concur                                          |                                       |
| **Payee Information**          |                                                     |                                       |
| `payeeName`                    | EmployeeLastName_6, EmployeeFirstName_7             |                                       |
| `payeeIdTypeCode`              | EMPLOYEE, STUDENT, OTHER                            |                                       |
| `payeeId`                      | EmployeeID_5                                        |                                       |
| **Payee Address**              |                                                     |                                       |
| `payeeAddressLine1`            | EmployeeCustom5_270                                 |                                       |
| `payeeAddressLine2`            | EmployeeCustom6_271                                 |                                       |
| `payeeAddressLine3`            | EmployeeCustom7_272                                 |                                       |
| `payeeAddressLine4`            |                                                     |                                       |
| `payeeCityName`                | EmployeeCustom8_273                                 |                                       |
| `payeeStateCode`               | EmployeeCustom9_274                                 |                                       |
| `payeeProvince`                | (none)                                              |                                       |
| `payeeCountryCode`             | EmployeeCustom11_276                                |                                       |
| `payeePostalCode`              | EmployeeCustom10_275                                |                                       |
| **Payment Details**            |                                                     |                                       |
| `invoiceNumber`                | ReportKey_20                                        |                                       |
| `invoiceDate`                  | ReportUserDefinedDate_25                            |                                       |
| `paymentDescription`           | ReportEntryExpenseTypeName_63                       |                                       |
| `paymentAmount`                | JournalAmount_169                                   |                                       |
| `paymentMethodCode`            |                                                     |                                       |
| **GL Segments**                |                                                     |                                       |
| `entity`                       | AllocationCustom14_204                              |                                       |
| `fund`                         | AllocationCustom7_197                               |                                       |
| `department`                   | AllocationCustom8_198                               |                                       |
| `account`                      | JournalAccountCode_167                              |                                       |
| `purpose`                      | AllocationCustom13_203                              |                                       |
| `glProject`                    | COALESCE(AllocationCustom9_199,'0000000000')        |                                       |
| `program`                      | COALESCE(AllocationCustom15_205, '000' )            |                                       |
| `activity`                     | COALESCE(AllocationCustom16_206, '000000' )         |                                       |
| **PPM Segments**               | PPM segment when AllocationCustom17_207 is NOT NULL |                                       |
| `ppmProject`                   | AllocationCustom10_200 - first part                 |                                       |
| `task`                         | AllocationCustom10_200 - second part                |                                       |
| `organization`                 | AllocationCustom11_201                              |                                       |
| `expenditureType`              | JournalAccountCode_167                              |                                       |
| `award`                        | null                                                |                                       |
| `fundingSource`                | null                                                |                                       |
| **ACH Payment Info**           | required when  ReportCustom5_45 != `STDCHECK`       |                                       |
| `eftRemitEmailAddress`         | EmployeeEmailAddress_265                            |                                       |
| `eftBankAccountNumber`         | ACHBankAccountNumber_16                             |                                       |
| `eftBankRoutingNumber`         | ACHBankRoutingNumber_17                             |                                       |
| `eftBankAccountTypeCode`       | EmployeeBankingBankAccountType_292                  | (CHCK for checking, SAVE for savings) |

### Outbound Flowfile Attributes

| Attribute Name         | Attribute Value               |
| ---------------------- | ----------------------------- |
| `consumer.id`          | UCD Concur                    |
| `data.source`          | sftp                          |
| `source.id`            | same as `requestSourceId`     |
| `boundary.system`      | Concur                        |
| `consumer.ref.id`      | same as `consumerReferenceId` |
| `consumer.tracking.id` | same as `consumerTrackingId`  |

### Sample Data
