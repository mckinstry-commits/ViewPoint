SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspSMBatchList]
   /***********************************************************
    * Created:  ECV 03/28/11
    * Modified: 
    *			JB 12/6/12 Removed the PO Receipt Batches from the query.
    *
    *
    * Creates a list of SM batches
    *
    * INPUT PARAMETERS
    *   @SMCo                SM Co#
    *   @@ShowMyBatchesOnly  'Y' to only show batches created by current login
    *   @IncludePosted       'Y' to include Posted batches in list
    *   @IncludeOpen         'Y' to include Open batches in list
    *
    * OUTPUT PARAMETERS
    *
    *****************************************************/

(@SMCo bCompany, @ShowMyBatchesOnly bYN='Y', @IncludePosted bYN='N', @IncludeOpen bYN='N')
AS
SET NOCOUNT ON

DECLARE @CreatedBy bVPUserName 

IF (@ShowMyBatchesOnly = 'Y')
	SET @CreatedBy = suser_name();
	
SELECT DISTINCT 
	HQBC.Co,
	HQBC.Mth,
	HQBC.BatchId,
	CASE WHEN HQBC.[Status] = 0 THEN 'Open'
		WHEN HQBC.[Status] = 1 THEN 'Validating'
		WHEN HQBC.[Status] = 2 THEN 'Errors'
		WHEN HQBC.[Status] = 3 THEN 'Valid'
		WHEN HQBC.[Status] = 4 THEN 'Posting'
		WHEN HQBC.[Status] = 5 THEN 'Posted'
		WHEN HQBC.[Status] = 6 THEN 'Cancelled'
		END [Status],
		HQBC.InUseBy, HQBC.CreatedBy, HQBC.DateCreated, Source,
		HQBC.[Status] StatusId,
		HQBC.DatePosted
	FROM dbo.HQBC
	LEFT JOIN dbo.SMMiscellaneousBatch MB 
		ON MB.Co=HQBC.Co AND MB.Mth=HQBC.Mth AND MB.BatchId=HQBC.BatchId
	WHERE 
		HQBC.Co = @SMCo
		AND (NOT @ShowMyBatchesOnly = 'Y' OR HQBC.CreatedBy=@CreatedBy)
		AND HQBC.Source Like 'SM%'
		AND NOT (@IncludeOpen = 'N' AND HQBC.[Status] = 0)
		AND NOT (@IncludePosted = 'N' AND HQBC.[Status] = 5)
		AND NOT HQBC.[Status] = 6

GO
GRANT EXECUTE ON  [dbo].[vspSMBatchList] TO [public]
GO
