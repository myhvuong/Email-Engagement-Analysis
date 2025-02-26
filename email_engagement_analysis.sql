USE SFMC
;

WITH CTEBNC AS (
    -- Get bounce records
    SELECT JobID, SubscriberID, SubscriberKey
    FROM Bounce
), 

CTEATB AS (
    -- Static Airtable containing previous email sends
    SELECT 
        Email_Sequence,
        Email_Name,
        Institution_Code,
        Email_Recipients, -- To get total sends from previous email sends
        SFMC_Link_Name,
        Descriptive_Link_Text, -- To replace Click_LinkName
    FROM [NimbleWorkspaceMBRS].[dbo].[Airtable_Elem_Engmt_Email_Links]
), 

CTESNT AS (
    -- Filtering out bounced emails to get correct recipients
    SELECT 
        s.*,
        TRIM(j.EmailName) AS Sent_EmailName,
        bnc.SubscriberID AS bnc_SubscriberID,
        j.Category
    FROM Sent s

    LEFT JOIN JOB j on s.JobID = j.JobID
    LEFT JOIN CTEBNC bnc ON (s.JobID = bnc.JobID AND s.SubscriberID = bnc.SubscriberID)
  
    WHERE bnc.SubscriberID IS NULL  -- Exclude bounced emails
    AND j.Category NOT IN ('Test Send Emails')
), 

CTESNTCount AS (
    -- Aggregating recipients count per email job
    SELECT 
        Sent_EmailName,
        COUNT(SubscriberKey) AS TotalSent
    FROM CTESNT s
    GROUP BY Sent_EmailName
) 

-- Final query selecting from the main Click table and joining with CTEs
SELECT DISTINCT 
  job.JobID,
  job.EmailName,
  
  CASE 
      WHEN (atb.Email_Recipients IS NOT NULL AND snt.TotalSent IS NULL) THEN atb.Email_Recipients
      WHEN (atb.Email_Recipients IS NULL AND snt.TotalSent IS NOT NULL) THEN snt.TotalSent
      -- Prioritize recipients count aggregation from Sent table bc there are errors from Airtable
      WHEN (atb.Email_Recipients IS NOT NULL AND snt.TotalSent IS NOT NULL) THEN snt.TotalSent 
      ELSE NULL 
  END AS RecipientsCount,

  CASE 
      WHEN atb.Email_Name IS NOT NULL THEN atb.Email_Sequence
      WHEN CHARINDEX('__Email', Sent_EmailName) > 0 THEN 
        'Email ' + CAST(CAST(
            SUBSTRING(Sent_EmailName, CHARINDEX('__Email', Sent_EmailName) + 7, 2
            ) AS INT) AS VARCHAR)
      ELSE NULL 
    END AS EmailSequence,

  CASE 
    WHEN atb.Institution_Code IS NOT NULL THEN atb.Institution_Code
    WHEN CHARINDEX('__Email', Sent_EmailName) > 0 THEN 
      SUBSTRING(
          Sent_EmailName,
          LEN(Sent_EmailName) - CHARINDEX('_', REVERSE(Sent_EmailName)) + 2,
          LEN(Sent_EmailName)
        )
    ELSE NULL 
  END AS InstitutionCode
          
FROM Click AS clk

LEFT JOIN Job job ON clk.JobID = job.JobID
LEFT JOIN CTEATB atb ON CONCAT(TRIM(job.EmailName), '-', clk.LinkName) = atb.CA_Email_Link_Name
LEFT JOIN CTESNTCount snt ON TRIM(job.EmailName) = snt.Sent_EmailName;
