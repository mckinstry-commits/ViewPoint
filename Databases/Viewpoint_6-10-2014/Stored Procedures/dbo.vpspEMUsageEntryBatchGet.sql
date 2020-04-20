SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Tom Jochums
-- Create date: 2/26/10
-- Description:	Retrieves EM Usage Posting batches that a VC User is able to access
-- =============================================
CREATE PROCEDURE [dbo].[vpspEMUsageEntryBatchGet]
	@Key_EMCo AS bCompany = Null, @VPUserName AS bVPUserName, @Key_BatchId AS bBatchID = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT @VPUserName AS VPUserName
		  ,HQBC.Co AS Key_EMCo
		  ,HQBC.Mth AS Key_Mth
		  ,CAST(HQBC.BatchId AS VARCHAR) AS Key_BatchId
		  ,CASE WHEN HQBC.InUseBy = @VPUserName THEN CAST(1 AS BIT) WHEN HQBC.InUseBy IS NOT NULL THEN 'In use by another user.' ELSE CAST(0 AS BIT) END AS LockedYN
		  ,HQBC.DateCreated
		  ,CASE WHEN HQBC.[Status] = 0 THEN 'Open' WHEN HQBC.[Status] = 5 THEN 'Posted' ELSE 'Unknown' END AS [Status]
		  ,HQBC.KeyID
		  ,HQBC.UniqueAttchID		  
		  ,HQCO.Name As CompanyName
	FROM HQBC
	JOIN HQCO on HQBC.Co = HQCO.HQCo
	WHERE Source = 'EMRev' 
	-- FOR THE FIRST ITERATION WE WILL ONLY SHOW OPEN BATCHES
	--AND (HQBC.[Status] = 0 OR HQBC.[Status] = 5) -- 0 = Open, 5 = Posted
	AND HQBC.[Status] = 0 -- 0 = Open, 5 = Posted
	AND HQBC.Co = ISNULL(@Key_EMCo, HQBC.Co)
	AND HQBC.CreatedBy = @VPUserName 
	AND (HQBC.InUseBy = @VPUserName OR HQBC.InUseBy IS NULL) 
	AND HQBC.BatchId = ISNULL(@Key_BatchId, HQBC.BatchId)
	ORDER BY HQBC.[Status] asc,  HQBC.Mth asc
END



GO
GRANT EXECUTE ON  [dbo].[vpspEMUsageEntryBatchGet] TO [VCSPortal]
GO
