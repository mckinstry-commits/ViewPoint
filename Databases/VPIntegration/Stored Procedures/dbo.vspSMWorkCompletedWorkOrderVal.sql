SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vspSMWorkCompletedWorkOrderVal]
-- =============================================
-- Author:		Lane Gresham
-- Create date: 04/30/12
-- Description:	SM Work Completed WorkOrder Val
-- =============================================
	@SMCo bCompany, @WorkOrder int, @IsCancelledOK bYN, @ServiceSite varchar(20) = NULL OUTPUT, @JCCo dbo.bCompany = NULL OUTPUT, @Job dbo.bJob = NULL OUTPUT, @msg varchar(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @rcode int, @errmsg varchar(255)
	
	EXEC @rcode = vspSMWorkOrderVal @SMCo = @SMCo, @WorkOrder = @WorkOrder, @IsCancelledOK = @IsCancelledOK, @serviceSite = @ServiceSite OUTPUT, @JCCo = @JCCo OUTPUT, @Job = @Job OUTPUT, @msg = @msg OUTPUT
	
	IF @rcode <> 0 
	BEGIN
		RETURN @rcode
	END
	ELSE
	BEGIN
		IF @JCCo IS NOT NULL AND @Job IS NOT NULL
		BEGIN
			EXEC @rcode = bspJCJMPostVal @jcco = @JCCo, @job = @Job, @msg = @errmsg OUTPUT
			
			IF @rcode <> 0 
			BEGIN
				SET @msg = @errmsg
				RETURN @rcode
			END
			
		END
	END
	
    RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspSMWorkCompletedWorkOrderVal] TO [public]
GO
