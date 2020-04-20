SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Chris Gall
-- Create date: 2/22/10
-- Description:	Retrieves JC Progress Entry batches that a VC User is able to access
-- =============================================
CREATE PROCEDURE [dbo].[vpspJCProgressBatchGet]
	@Key_JCCo AS bCompany, @Key_Job AS bJob, @VPUserName AS bVPUserName, @Key_BatchId AS bBatchID = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Need to select Posted and Unposted batches, so we need to Union the JCPP and JCCD
	--  tables to get specific batch information, such as, Job and ActualDate.
	SELECT @VPUserName AS VPUserName
		  ,HQBC.Co AS Key_JCCo
		  ,HQBC.Mth AS Key_Mth		  
		  ,CAST(HQBC.BatchId AS VARCHAR) AS Key_BatchId
		  ,JCPP.Job AS Key_Job
		  ,CASE WHEN InUseBy = @VPUserName THEN CAST(1 AS BIT) WHEN InUseBy IS NOT NULL THEN 'In use by another user.' ELSE CAST(0 AS BIT) END AS LockedYN
		  ,HQBC.DateCreated
		  ,CASE WHEN [Status] = 0 THEN 'Open' WHEN [Status] = 5 THEN 'Posted' ELSE 'Unknown' END AS [Status]
		  ,HQBC.KeyID
		  ,HQBC.UniqueAttchID
		  ,CAST(JCPP.ActualDate AS DateTime) AS ActualDate
	FROM HQBC
	RIGHT JOIN JCPP ON JCPP.Co = HQBC.Co AND JCPP.BatchId = HQBC.BatchId AND JCPP.Mth = HQBC.Mth
	WHERE HQBC.Source = 'JC Progres' 
	AND [Status] = 0 -- 0 = Open
	AND HQBC.Co = @Key_JCCo 
	AND CreatedBy = @VPUserName 
	AND (InUseBy = @VPUserName OR InUseBy IS NULL) 
	AND HQBC.BatchId = ISNULL(@Key_BatchId, HQBC.BatchId)
	AND JCPP.Job = @Key_Job
	GROUP BY
		   HQBC.Co
		  ,HQBC.Mth
		  ,HQBC.BatchId
		  ,InUseBy
		  ,DateCreated
		  ,[Status]
		  ,HQBC.KeyID
		  ,JCPP.Job
		  ,JCPP.ActualDate
		  ,HQBC.UniqueAttchID
		  ,CAST(JCPP.ActualDate AS DateTime)
	UNION
	SELECT @VPUserName AS VPUserName
		  ,HQBC.Co AS Key_JCCo
		  ,HQBC.Mth AS Key_Mth		  
		  ,CAST(HQBC.BatchId AS VARCHAR) AS Key_BatchId
		  ,JCCD.Job AS Key_Job
		  ,CASE WHEN InUseBy = @VPUserName THEN CAST(1 AS BIT) WHEN InUseBy IS NOT NULL THEN 'In use by another user.' ELSE CAST(0 AS BIT) END AS LockedYN
		  ,HQBC.DateCreated
		  ,CASE WHEN [Status] = 0 THEN 'Open' WHEN [Status] = 5 THEN 'Posted' ELSE 'Unknown' END AS [Status]
		  ,HQBC.KeyID
		  ,HQBC.UniqueAttchID
		  ,CAST(JCCD.ActualDate AS DateTime) AS ActualDate
	FROM HQBC
	-- JOIN based on status (Open batch details in JCPP, Posted batch details in JCCD)
	RIGHT JOIN JCCD ON JCCD.JCCo = HQBC.Co AND JCCD.BatchId = HQBC.BatchId AND JCCD.Mth = HQBC.Mth AND JCCD.Source = HQBC.Source
	WHERE HQBC.Source = 'JC Progres' 
	AND [Status] = 5 -- 5 = Posted
	AND HQBC.Co = @Key_JCCo 
	AND CreatedBy = @VPUserName 
	AND (InUseBy = @VPUserName OR InUseBy IS NULL) 
	AND HQBC.BatchId = ISNULL(@Key_BatchId, HQBC.BatchId)
	AND JCCD.Job = @Key_Job 
	GROUP BY
		   HQBC.Co
		  ,HQBC.Mth
		  ,HQBC.BatchId
		  ,InUseBy
		  ,DateCreated
		  ,[Status]
		  ,HQBC.KeyID
		  ,JCCD.Job
		  ,JCCD.ActualDate
		  ,HQBC.UniqueAttchID
		  ,CAST(JCCD.ActualDate AS DateTime)
	ORDER BY
		DateCreated DESC
END
GO
GRANT EXECUTE ON  [dbo].[vpspJCProgressBatchGet] TO [VCSPortal]
GO
