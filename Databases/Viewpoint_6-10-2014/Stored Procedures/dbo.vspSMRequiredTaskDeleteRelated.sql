SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

-- =============================================
--		Author:	Lane Gresham
-- Create date: 04/22/2013
-- Description:	Deletes related records connected
--				to the Task.
-- =============================================
CREATE PROCEDURE [dbo].[vspSMRequiredTaskDeleteRelated]
	@SMCo bCompany, 
	@EntitySeq int, 
	@Task int, 
	@msg varchar(255) = NULL OUTPUT
AS
BEGIN

	SET NOCOUNT ON

	DELETE dbo.vSMRequiredEquipment
	WHERE SMCo = @SMCo AND EntitySeq = @EntitySeq AND Task = @Task
	
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMRequiredTaskDeleteRelated] TO [public]
GO
