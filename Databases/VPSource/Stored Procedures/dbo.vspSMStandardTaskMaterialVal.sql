SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		Jeremiah Barkley
-- Create date: 12/13/11
-- Description:	Validation for the material on the SMStandardTaskMaterial form
-- Modified:	
-- =============================================

CREATE PROCEDURE [dbo].[vspSMStandardTaskMaterialVal]
	@MaterialGroup AS bGroup, 
	@Material AS bMatl, 
	@Description AS varchar(60) OUTPUT, 
	@DefaultUM AS bUM OUTPUT,
	@msg AS varchar(255) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @rcode int
	
	EXEC @rcode = dbo.bspHQMatlValWithInfo @MaterialGroup, @Material, NULL, @DefaultUM OUTPUT, NULL, NULL, NULL, NULL, NULL, @msg OUTPUT
	
	IF (@rcode = 0)
	BEGIN
		SELECT @Description = @msg
	END
    
    RETURN @rcode
END

GO
GRANT EXECUTE ON  [dbo].[vspSMStandardTaskMaterialVal] TO [public]
GO
