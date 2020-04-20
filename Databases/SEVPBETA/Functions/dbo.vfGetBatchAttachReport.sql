SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
--		Author: Lane Gresham
-- Create date: 11/02/11
-- Description:	Get SM & PO Batch Attach Reports Flags
-- =============================================
CREATE FUNCTION [dbo].[vfGetBatchAttachReport]
(	
	@Co bCompany
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT CASE WHEN ( SELECT AttachBatchReportsYN FROM SMCO
						WHERE SMCo = @Co) = 'N' THEN 0 ELSE 1 END SMCoAttachReport, 
	CASE WHEN ( SELECT AttachBatchReportsYN FROM POCO
				 WHERE POCo = @Co) = 'N' THEN 0 ELSE 1 END POCoAttachReport
)
GO
GRANT SELECT ON  [dbo].[vfGetBatchAttachReport] TO [public]
GO
