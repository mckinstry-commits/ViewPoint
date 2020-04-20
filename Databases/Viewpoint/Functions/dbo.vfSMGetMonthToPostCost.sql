SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
--		Author: Lane Gresham
-- Create date: 10/28/11
-- Description:	Get Month To Post Cost
-- =============================================
CREATE FUNCTION [dbo].[vfSMGetMonthToPostCost]
(	
	@SMCo bCompany, @ServiceCenter varchar(10), @Division varchar(10), @MinDate bDate, @MaxDate bDate
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT DISTINCT MonthToPostCost FROM SMWorkCompletedAllCurrent
	WHERE SMWorkCompletedID IN (SELECT SMWorkCompletedID FROM vfSMGetWorkCompletedMiscellaneousToBeProcessed(@SMCo, NULL, @ServiceCenter, @Division, @MinDate, @MaxDate))
)

GO
GRANT SELECT ON  [dbo].[vfSMGetMonthToPostCost] TO [public]
GO
