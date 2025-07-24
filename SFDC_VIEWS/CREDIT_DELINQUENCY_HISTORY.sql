create or replace view CREDIT_DELINQUENCY_HISTORY(
	"AmortRepaymentId",
	"Day End Date",
	"Last Expected Payment Date",
	"Last Expected Payment Amount",
	"Last Expected Payment Number",
	"Last Expected Payment Principal",
	"Last Expected Payment Interest",
	"Open Balance",
	"Weekly Payment Amount - Contractual",
	"Count of Expected Payments",
	"Amount Paid Principal",
	"Amount Paid Interest",
	"Last Payment Received Date",
	"Repayment Day End Date",
	"Repayment Id",
	"Next Payment Date",
	"Adj Last Payment Expected Date",
	"Total Expected Payments - Contractual",
	"Total RTR Amount Paid",
	"Payment Days Delinquent",
	"Delinquent Days Since Last Expected Payment",
	"Days Past Due"
) as
    -- comment = '<comment>'
WITH
  LastPayments AS (
    SELECT
      "Day_End_Date",
      "cmbls__Repayment__c" "AmortRepaymentId",
      LAST_VALUE("cmbls__Date__c") IGNORE NULLS OVER (
        PARTITION BY
          "Day_End_Date","AmortRepaymentId"
        ORDER BY
          "cmbls__Date__c" ASC ROWS BETWEEN UNBOUNDED PRECEDING
          AND UNBOUNDED FOLLOWING
      ) AS "Last Expected Payment Date",
      LAST_VALUE("cmbls__Payment_Amount__c") IGNORE NULLS OVER (
        PARTITION BY
          "Day_End_Date","AmortRepaymentId"
        ORDER BY
          "cmbls__Date__c" ASC ROWS BETWEEN UNBOUNDED PRECEDING
          AND UNBOUNDED FOLLOWING
      ) AS "Last Expected Payment Amount",
      LAST_VALUE("cmbls__Payment_Number__c") IGNORE NULLS OVER (
        PARTITION BY
          "Day_End_Date","AmortRepaymentId"
        ORDER BY
          "cmbls__Date__c" ASC ROWS BETWEEN UNBOUNDED PRECEDING
          AND UNBOUNDED FOLLOWING
      ) AS "Last Expected Payment Number",
      LAST_VALUE("cmbls__Principal_Payment__c") IGNORE NULLS OVER (
        PARTITION BY
         "Day_End_Date", "AmortRepaymentId"
        ORDER BY
          "cmbls__Date__c" ASC ROWS BETWEEN UNBOUNDED PRECEDING
          AND UNBOUNDED FOLLOWING
      ) AS "Last Expected Payment Principal",
      LAST_VALUE("cmbls__Interest_Payment__c") IGNORE NULLS OVER (
        PARTITION BY
          "Day_End_Date","AmortRepaymentId"
        ORDER BY
          "cmbls__Date__c" ASC ROWS BETWEEN UNBOUNDED PRECEDING
          AND UNBOUNDED FOLLOWING
      ) AS "Last Expected Payment Interest"
    FROM
      SFDC.HISTORY."CMBLS__AMORTIZATION_SCHEDULE__C"
    WHERE
      "cmbls__Date__c" <= "Day_End_Date" AND  "cmbls__Payment_Amount__c" > 0
  )
SELECT DISTINCT
  sch."cmbls__Repayment__c" "AmortRepaymentId",
  sch."Day_End_Date" "Day End Date",
  lp."Last Expected Payment Date",
  lp."Last Expected Payment Amount",
  lp."Last Expected Payment Number",
  lp."Last Expected Payment Principal",
  lp."Last Expected Payment Interest",
  iff(
    R."cmbls__Open_Balance__c" > 0
    AND R."cmbls__Status__c" != 'Write Off'
    AND R."cmbls__Funded_Date__c" IS NOT NULL,
    R."cmbls__Open_Balance__c",
    0
  ) "Open Balance",
  R."cmbls__Payment_Amount__c" "Weekly Payment Amount - Contractual",
  R."Count_of_Expected_Payments__c" "Count of Expected Payments",
  R."cmbls__Amount_Paid_Principal__c" "Amount Paid Principal",
 R."cmbls__Amount_Paid_Interest__c" "Amount Paid Interest",
 TO_DATE(CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', R."Last_Payment_Received_Date__c")) "Last Payment Received Date",
 R."Day_End_Date" "Repayment Day End Date",
  R."Id" "Repayment Id",
  R."cmbls__Next_Hit_Date__c" "Next Payment Date",

 -- CALCULATED FACTS
 
 iff("Last Expected Payment Date">="Last Payment Received Date",
"Last Expected Payment Date",
"Last Payment Received Date") "Adj Last Payment Expected Date",
"Weekly Payment Amount - Contractual"   * "Count of Expected Payments" "Total Expected Payments - Contractual",
"Amount Paid Interest" + "Amount Paid Principal" "Total RTR Amount Paid",

IFF("Open Balance" >0, ceil(("Total Expected Payments - Contractual"-"Total RTR Amount Paid")/"Weekly Payment Amount - Contractual",0),0) "Payment Days Delinquent",

IFF("Open Balance" >0 AND "Payment Days Delinquent" > 0, DATEDIFF( 'day', "Adj Last Payment Expected Date","Day End Date"),0) "Delinquent Days Since Last Expected Payment",

IFF((("Total Expected Payments - Contractual"-"Total RTR Amount Paid")/"Weekly Payment Amount - Contractual")*7-7+ zeroifnull("Delinquent Days Since Last Expected Payment")<0,0,(("Total Expected Payments - Contractual"-"Total RTR Amount Paid")/"Weekly Payment Amount - Contractual")*7-7+ zeroifnull("Delinquent Days Since Last Expected Payment")) "Days Past Due"
  
FROM
  LastPayments lp
  
  INNER JOIN SFDC.HISTORY."CMBLS__AMORTIZATION_SCHEDULE__C" sch ON 
  lp."Day_End_Date" = sch."Day_End_Date"
  AND lp."AmortRepaymentId" = sch."cmbls__Repayment__c"
  AND lp."Last Expected Payment Date" = sch."cmbls__Date__c" 

  FULL OUTER JOIN SFDC.HISTORY.CMBLS__REPAYMENT__C R
  ON  lp."Day_End_Date" = R."Day_End_Date"
  AND lp."AmortRepaymentId" = R."Id";