# Email Click-Through Rate Analysis (SFMC)

## Overview

This document outlines my contributions to updating an existing SQL query for email engagement analysis. The modifications focus on improving automation and enabling real-time updates.

This SQL script enhances the analysis process by replacing manual Airtable updates with real-time data from the Sent table, ensuring automated and accurate tracking of click-through rates (CTR) for links and emails.

## Query Structure

1. **CTEBNC (Bounced Emails)**: Identifies bounced emails to exclude from the analysis.

2. **CTEATB (Airtable Email History)**: Provides historical email send data.

3. **CTESNT (Valid Sent Emails)**: Filters the Sent table to include only valid (non-bounced) email sends.

4. **CTESNTCount (Sent Email Aggregation)**: Calculates the total number of recipients for each email job, serving as the denominator for CTR in reporting.

5. **Final Query**:

* Joins click data with valid sent emails.
* Computes the recipients count by prioritizing Sent data aggregation over Airtable when discrepancies exist.
* Extracts key attributes like Email Sequence and Institution Code for reporting.
