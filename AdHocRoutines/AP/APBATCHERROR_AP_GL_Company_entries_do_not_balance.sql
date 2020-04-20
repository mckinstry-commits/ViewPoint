/*
2015.01.29 - LWO - 
Utility procedure to identify AP batch errors where the 
error report shows "AP GL Company # entries do not balance"

Appears that APHB/APLB entries create GL entries in APGL that 
do not balance (e.g. debit and credit for each BatchSeq need to sum
up to $0)

Usage:  Change the value of the @APCo and @BatchId variable to 
represent the failing batch.

The results show the items  that need to be removed from the 
AP Batch to allow successful posting of the remaining entries.

The failing items need to be researched/corrected and processed in 
a subsequent batch.
*/

DECLARE @APCo		bCompany
DECLARE @BatchId	bBatchID

SET @APCo = 1
SET @BatchId = 11471

SELECT APCo, Mth, BatchId, BatchSeq, Vendor, Job, TransDesc, SUM(TotalCost)  AS TotalGLPosting
FROM APGL 
WHERE APCo=@APCo AND BatchId=@BatchId 
GROUP BY APCo, Mth, BatchId, BatchSeq, Vendor, Job, TransDesc 
HAVING SUM(TotalCost) <> 0
ORDER BY APCo, Mth, BatchId, BatchSeq
go