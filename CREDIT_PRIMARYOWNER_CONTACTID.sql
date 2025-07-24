create or replace view CREDIT_PRIMARYOWNER_CONTACTID(
	"OpportunityId",
	"Beneficial Owner_ANY_ContactId",
	"Business Owner_ANY_ContactId",
	"Guarantor 2_ANY_ContactId",
	"Guarantor 3_ANY_ContactId",
	"Guarantor 4_ANY_ContactId",
	"Other_ANY_ContactId",
	"Signer_ANY_ContactId",
	"Signer Contact"
) as
    -- comment = '<comment>'
WITH
  "MANAGE COLUMNS" AS (
    SELECT
      "Id",
      "Application_In_Date__c",
      "Funded_Date__c"
    FROM
      "SFDC"."STAGE"."OPPORTUNITY"
  ),
  "FILTER" AS (
    SELECT
      *
    FROM
      "MANAGE COLUMNS"
    WHERE
      ("Application_In_Date__c" IS NOT NULL)
  ),
  "JOIN" AS (
    SELECT
      LHS.*,
      RHS."Id" AS "Id_RHS",
      RHS."Application_In_Date__c",
      RHS."Funded_Date__c"
    FROM
      "SFDC"."STAGE"."OPPORTUNITYCONTACTROLE" LHS
      RIGHT OUTER JOIN "FILTER" RHS ON LHS."OpportunityId" = RHS."Id"
  ),
  "PIVOT" AS (
    WITH
      "AGG" AS (
        SELECT
          "OpportunityId" AS "OpportunityId",
          "Role" AS "Role",
          ANY_VALUE("ContactId") AS "ANY_ContactId_aggTable"
        FROM
          "JOIN"
        WHERE
          "Role" IN (
            'Beneficial Owner',
            'Business Owner',
            'Guarantor 2',
            'Guarantor 3',
            'Guarantor 4',
            'Other',
            'Signer'
          )
        GROUP BY
          "OpportunityId",
          "Role"
      )
    SELECT
      "OpportunityId",
      MAX(
        IFF(
          "Role" = 'Beneficial Owner',
          "ANY_ContactId_aggTable",
          NULL
        )
      ) AS "Beneficial Owner_ANY_ContactId",
      MAX(
        IFF(
          "Role" = 'Business Owner',
          "ANY_ContactId_aggTable",
          NULL
        )
      ) AS "Business Owner_ANY_ContactId",
      MAX(
        IFF(
          "Role" = 'Guarantor 2',
          "ANY_ContactId_aggTable",
          NULL
        )
      ) AS "Guarantor 2_ANY_ContactId",
      MAX(
        IFF(
          "Role" = 'Guarantor 3',
          "ANY_ContactId_aggTable",
          NULL
        )
      ) AS "Guarantor 3_ANY_ContactId",
      MAX(
        IFF(
          "Role" = 'Guarantor 4',
          "ANY_ContactId_aggTable",
          NULL
        )
      ) AS "Guarantor 4_ANY_ContactId",
      MAX(
        IFF("Role" = 'Other', "ANY_ContactId_aggTable", NULL)
      ) AS "Other_ANY_ContactId",
      MAX(
        IFF("Role" = 'Signer', "ANY_ContactId_aggTable", NULL)
      ) AS "Signer_ANY_ContactId"
    FROM
      "AGG"
    GROUP BY
      "OpportunityId"
  )
SELECT
  *,
  COALESCE(
    "Signer_ANY_ContactId",
    "Guarantor 2_ANY_ContactId",
    "Guarantor 3_ANY_ContactId",
    "Guarantor 4_ANY_ContactId",
    'Unknown'
  ) "Signer Contact"
FROM
  PIVOT;