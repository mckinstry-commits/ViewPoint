SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/* =============================================
-- Author:		Jeremiah Barkley
-- Create date: 8/23/11
-- Description:	
=============================================*/
CREATE PROCEDURE [dbo].[vspSMServiceItemPartUMVal]
	@UM AS bUM,
	@MaterialGroup AS bGroup = NULL,
	@Material AS bMatl = NULL,
	@msg AS varchar(255) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @rcode int
	
	IF (@Material IS NULL)
	BEGIN
		SELECT @msg = [Description] FROM dbo.HQUM WHERE UM = @UM
		
		IF (@@ROWCOUNT = 0)
		BEGIN
			SET @msg = 'Invalid UM.'
			RETURN 1
		END
	END
	ELSE
	BEGIN
		SELECT @msg = HQUM.[Description] FROM dbo.HQUM JOIN dbo.HQMT ON HQMT.StdUM = HQUM.UM WHERE HQMT.MatlGroup = @MaterialGroup AND HQMT.Material = @Material AND HQMT.StdUM = @UM
		
		IF (@@ROWCOUNT = 0)
		BEGIN
			-- If it is not found check for it in HQMU
			SELECT @msg = HQUM.[Description] FROM dbo.HQMU JOIN dbo.HQUM ON HQMU.UM = HQUM.UM  WHERE HQMU.MatlGroup = @MaterialGroup AND HQMU.Material = @Material AND HQMU.UM = @UM
		
			IF (@@ROWCOUNT = 0)
			BEGIN
				SET @msg = 'Invalid UM for the current part.'
				RETURN 1
			END
		END
	END
	
	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspSMServiceItemPartUMVal] TO [public]
GO
