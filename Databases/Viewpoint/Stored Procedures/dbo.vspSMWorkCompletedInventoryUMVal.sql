SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/* =============================================
-- Author:		David Solheim
-- Create date: 1/7/2013
-- Description:	Inventory UM validation for SM Work Order Inventory Detail.
=============================================*/
CREATE PROCEDURE [dbo].[vspSMWorkCompletedInventoryUMVal]
	@INCo AS bCompany,
	@INLocation AS bLoc, 
	@MaterialGroup AS bGroup = NULL,
	@Part AS bMatl = NULL,
	@UM AS bUM,
	@msg AS varchar(255) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @rcode int
	
	IF (@MaterialGroup IS NULL)
	BEGIN
		SET @msg = 'Material Group is required to validate.'
		RETURN 1
	END
	
	IF (@Part IS NULL)
	BEGIN
		SET @msg = 'Part is required to validate.'
		RETURN 1
	END
	
	IF (@INCo IS NULL OR @INLocation IS NULL)
	BEGIN
		SET @msg = 'IN Company and Locaiton are required to validate.'
		RETURN 1
	END
	
	-- Check in HQMT.StdUM AND in HQMU to validate UM
	SELECT @msg = HQUM.[Description] FROM HQUM JOIN HQMT ON HQMT.StdUM = HQUM.UM WHERE HQMT.MatlGroup = @MaterialGroup AND HQMT.Material = @Part AND HQMT.StdUM = @UM
	
	IF (@@ROWCOUNT = 0)
	BEGIN
		-- If it is not found check for it in INMU
		SELECT @msg = HQUM.[Description] FROM dbo.INMU JOIN dbo.HQUM ON INMU.UM = HQUM.UM  WHERE INMU.INCo = @INCo AND INMU.Loc = @INLocation AND INMU.MatlGroup = @MaterialGroup AND INMU.Material = @Part AND INMU.UM = @UM
	
		IF (@@ROWCOUNT = 0)
		BEGIN
			SET @msg = 'Invalid UM for the current part.'
			RETURN 1
		END
	END

	RETURN 0
END





GO
GRANT EXECUTE ON  [dbo].[vspSMWorkCompletedInventoryUMVal] TO [public]
GO
