SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 2/2/12
-- Description:	Returns the next seq available for a work completed record for a given work order
-- =============================================
CREATE FUNCTION [dbo].[vfSMGetNextWorkCompletedSeq]
(
	@SMCo bCompany, @WorkOrder int
)
RETURNS int
AS
BEGIN
	RETURN (SELECT ISNULL(MAX(WorkCompleted), 0) + 1
			FROM dbo.vSMWorkCompleted
			WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder)
END
GO
GRANT EXECUTE ON  [dbo].[vfSMGetNextWorkCompletedSeq] TO [public]
GO
