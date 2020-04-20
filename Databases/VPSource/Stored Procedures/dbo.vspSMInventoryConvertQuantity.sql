SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







/* =============================================
-- Author:		Jeremiah Barkley
-- Create date: 10/21/10
-- Description:	Convert a material quantity from one UM to another UM.
--
-- Modified:
--				JB 12/12/12 Not only an awesome date...but refactored and renamed this sproc.
=============================================*/
CREATE PROCEDURE [dbo].[vspSMInventoryConvertQuantity]
	@INCo AS bCompany,
	@INLocation AS bLoc,
	@MaterialGroup AS bGroup,
	@Material AS bMatl,
	@OriginalUM AS bUM,
	@OriginalQuantity AS bUnits, 
	@ConvertToUM AS bUM,
	@ConvertedQuantity AS bUnits OUTPUT,
	@msg as varchar(255) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @OriginalUMConversion bUnitCost, @ConvertedUMConversion bUnitCost, @BaseUnits bUnits, @errmsg varchar(255), @rcode int
	
	-- Get the Original UM conversion
	SELECT @OriginalUMConversion = CASE WHEN INMU.KeyID IS NOT NULL THEN INMU.Conversion WHEN HQMT.StdUM = @OriginalUM THEN 1.0 END FROM HQMT
	LEFT JOIN dbo.INMU ON HQMT.MatlGroup = INMU.MatlGroup AND HQMT.Material = INMU.Material AND INMU.INCo = @INCo AND INMU.Loc = @INLocation AND INMU.UM = @OriginalUM
	WHERE HQMT.MatlGroup = @MaterialGroup AND HQMT.Material = @Material 
	
	-- Get the Convert To UM conversion
	SELECT @ConvertedUMConversion = CASE WHEN INMU.KeyID IS NOT NULL THEN INMU.Conversion WHEN HQMT.StdUM = @ConvertToUM THEN 1.0 END FROM HQMT
	LEFT JOIN dbo.INMU ON HQMT.MatlGroup = INMU.MatlGroup AND HQMT.Material = INMU.Material AND INMU.INCo = @INCo AND INMU.Loc = @INLocation AND INMU.UM = @ConvertToUM
	WHERE HQMT.MatlGroup = @MaterialGroup AND HQMT.Material = @Material 
	
	IF (@OriginalUMConversion IS NULL OR @ConvertedUMConversion IS NULL OR @ConvertedUMConversion = 0)
	BEGIN
		SELECT @msg = 'Unable to convert the part quantity because the conversion information is missing.'
		RETURN 1
	END
	
	IF (@OriginalQuantity IS NOT NULL)
	BEGIN
		SET @BaseUnits = CONVERT(Numeric(12,3), (@OriginalQuantity * @OriginalUMConversion))
		SET @ConvertedQuantity = CONVERT(Numeric(12,3), (@BaseUnits / @ConvertedUMConversion))
	END
	
	RETURN 0
END




GO
GRANT EXECUTE ON  [dbo].[vspSMInventoryConvertQuantity] TO [public]
GO
