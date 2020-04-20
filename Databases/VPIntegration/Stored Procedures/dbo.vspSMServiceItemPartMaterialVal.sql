SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/* =============================================
-- Author:		Jeremiah Barkley
-- Created:		8/24/11
-- Description:	Validation the Material for the SM Service Item Part.
-- Modified:	
=============================================*/
CREATE PROCEDURE [dbo].[vspSMServiceItemPartMaterialVal]
	@MaterialGroup AS bGroup,
	@Material AS bMatl,
	@Description AS varchar(60) = NULL OUTPUT,
	@DefaultUM AS bUM = NULL OUTPUT,
	@msg AS varchar(255) = NULL OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	IF (@MaterialGroup IS NULL)
	BEGIN
		SET @msg = 'Material Group is required.'
		RETURN 1
	END
	
	IF (@Material IS NULL)
	BEGIN
		SET @msg = 'Material is required.'
		RETURN 1
	END
	
	SELECT 
		@DefaultUM = StdUM, 
		@Description = [Description], 
		@msg = [Description]
	FROM dbo.HQMT
	WHERE 
		MatlGroup = @MaterialGroup 
		AND Material = @Material
	IF (@@ROWCOUNT = 0)
	BEGIN
		SELECT @msg = 'Material not on file.'
		RETURN 1
	END
	
	RETURN 0
	
END
GO
GRANT EXECUTE ON  [dbo].[vspSMServiceItemPartMaterialVal] TO [public]
GO
