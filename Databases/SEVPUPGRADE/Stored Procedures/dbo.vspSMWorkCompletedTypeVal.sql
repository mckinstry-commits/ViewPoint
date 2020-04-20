SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Vaterlaus
-- Modified:    
-- Create date: 1/10/2011
-- Description:	Validation that a Service Center exists before a Work Completed type can be selected.
-- =============================================
CREATE PROCEDURE [dbo].[vspSMWorkCompletedTypeVal]
	@SMCo bCompany, @WorkOrder int, @msg varchar(255) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @rcode int
	SET @rcode = 0

	IF EXISTS(SELECT 1 FROM SMWorkOrder WHERE SMCo = @SMCo and WorkOrder = @WorkOrder AND ServiceCenter IS NULL)
	BEGIN
		SET @msg = 'Service Center required on Work Order before Work Completed can be entered.'
		SET @rcode = 1
	END

	RETURN @rcode
END


GO
GRANT EXECUTE ON  [dbo].[vspSMWorkCompletedTypeVal] TO [public]
GO
