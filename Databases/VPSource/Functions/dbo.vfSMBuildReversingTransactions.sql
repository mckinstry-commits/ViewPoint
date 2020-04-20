SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 11/1/11
-- Description:	Builds the reversing transactions for a given work completed record.
-- =============================================
CREATE FUNCTION [dbo].[vfSMBuildReversingTransactions]
(	
	@SMWorkCompletedID bigint
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT IsTransactionForSMDerivedAccount, GLCo, GLAccount, -Amount Amount, ActDate, [Description]
	FROM dbo.vSMWorkCompletedGL
		LEFT JOIN dbo.vSMGLDetailTransaction ON (vSMWorkCompletedGL.CostGLEntryID = vSMGLDetailTransaction.SMGLEntryID AND IsTransactionForSMDerivedAccount = 0) OR vSMWorkCompletedGL.CostGLDetailTransactionID = vSMGLDetailTransaction.SMGLDetailTransactionID
	WHERE SMWorkCompletedID = @SMWorkCompletedID
)

GO
GRANT SELECT ON  [dbo].[vfSMBuildReversingTransactions] TO [public]
GO
