SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jeremiah Barkley
-- Create date: 12/13/11
-- Description:	Validation for the UM on the SMStandardTaskMaterial form
-- Modified:	
-- =============================================

CREATE PROCEDURE [dbo].[vspSMStandardTaskMaterialUMVal]
	@MaterialGroup AS bGroup, 
	@Material AS bMatl, 
	@UM AS bUM,
	@msg AS varchar(255) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @rcode int
	
	-- Determine how the UM needs to be validated depending on if the material is
	-- a valid material
	EXEC @rcode = dbo.bspHQMatlVal @MaterialGroup, @Material, NULL, NULL
	
	IF (@rcode = 0)
	BEGIN
		-- Validate the UM against the HQ Material
		SELECT @msg = HQUM.[Description] FROM
		(
			SELECT UM, MatlGroup, Material FROM dbo.HQMU
			UNION
			SELECT StdUM, MatlGroup, Material FROM dbo.HQMT
		) AllUM
		INNER JOIN dbo.HQUM ON HQUM.UM = AllUM.UM
		WHERE AllUM.MatlGroup = @MaterialGroup AND AllUM.Material = @Material AND AllUM.UM = @UM
		
		IF (@@ROWCOUNT = 0)
		BEGIN
			SELECT @rcode = 1, @msg = 'Invalid UM for the selected material.'
		END
	END
	ELSE
	BEGIN
		-- Validate the UM against HQUM
		EXEC @rcode = dbo.bspHQUMVal @UM, @msg OUTPUT
	END
    
    RETURN @rcode
END


GO
GRANT EXECUTE ON  [dbo].[vspSMStandardTaskMaterialUMVal] TO [public]
GO
