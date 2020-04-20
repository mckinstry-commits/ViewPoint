SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/* =============================================
-- Author:		Jeremiah Barkley
-- Create date: 8/31/2010
-- Description:	Part UM validation for SM Work Order Part Detail.
=============================================*/
CREATE PROCEDURE [dbo].[vspSMWorkCompletedPartUMVal]
	@Source as tinyint,
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
	
	IF (@Source = 0)
	BEGIN
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
	END
	ELSE IF (@Source = 1)
	BEGIN
		-- validate whether or not the part is real
		EXEC @rcode = dbo.bspHQMatlVal @MaterialGroup, @Part, NULL, NULL
		
		IF (@rcode = 0)
		BEGIN
			-- if the part is real then validate the UM to that part
			-- Check in HQMT.StdUM AND in HQMU to validate UM
			SELECT @msg = HQUM.[Description] FROM dbo.HQUM JOIN dbo.HQMT ON HQMT.StdUM = HQUM.UM WHERE HQMT.MatlGroup = @MaterialGroup AND HQMT.Material = @Part AND HQMT.StdUM = @UM
			
			IF (@@ROWCOUNT = 0)
			BEGIN
				-- If it is not found check for it in HQMU
				SELECT @msg = HQUM.[Description] FROM dbo.HQMU JOIN dbo.HQUM ON HQMU.UM = HQUM.UM  WHERE HQMU.MatlGroup = @MaterialGroup AND HQMU.Material = @Part AND HQMU.UM = @UM
			
				IF (@@ROWCOUNT = 0)
				BEGIN
					SET @msg = 'Invalid UM for the current part.'
					RETURN 1
				END
			END
		END
		ELSE
		BEGIN
			-- if the part is not real just validate the UM
			SELECT @msg = HQUM.[Description] FROM dbo.HQUM WHERE UM = @UM
			
			IF (@@ROWCOUNT = 0)
			BEGIN
				SET @msg = 'Invalid UM.'
				RETURN 1
			END
		END
	END

	RETURN 0
END





GO
GRANT EXECUTE ON  [dbo].[vspSMWorkCompletedPartUMVal] TO [public]
GO
