SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
--		Author:	Lane Gresham
-- Create Date: 01-06-12
-- Description:	Returns the default for a Work Completed Reference No
--	  Modified:
-- =============================================
CREATE PROCEDURE [dbo].[vspSMReferenceNoDefault]
	@SMCo bCompany, 
	@WorkOrder int, 
	@Scope int, 
	@Date datetime, 
	@ReferenceNo varchar(60) OUTPUT,
	@msg varchar(255) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	
	SELECT TOP 1 @ReferenceNo = ReferenceNo FROM dbo.SMWorkCompleted
	WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder AND Scope = @Scope AND [Date] = @Date
	ORDER BY WorkCompleted DESC

	RETURN 0
	
END
GO
GRANT EXECUTE ON  [dbo].[vspSMReferenceNoDefault] TO [public]
GO
