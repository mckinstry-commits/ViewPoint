SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/* =============================================
-- Author:		David Solheim
-- Modified:	
-- Create date: 1/6/2013
-- Description:	Part validation for SM Work Order Material Detail.
=============================================*/
CREATE PROCEDURE [dbo].[vspSMWorkCompletedInventoryMaterialVal]
	@SMCo AS dbo.bCompany,
	@INCo AS bCompany,
	@INLocation AS bLoc,
	@MaterialGroup AS bGroup,
	@Material AS bMatl,
	@Job AS dbo.bJob = NULL,
	@SMCostType AS SMALLINT = NULL,
	@MaterialUMDefault AS bUM = NULL OUTPUT,
	@PriceUMDefault AS bUM = NULL OUTPUT,
	@IsTaxable AS bYN = 'Y' OUTPUT,
	@IsValidMaterial AS bYN OUTPUT,
	@JCCostType AS dbo.bJCCType OUTPUT,
	@msg AS varchar(255) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	IF (@MaterialGroup IS NULL)
	BEGIN
		SET @msg = 'Material Group is required.'
		RETURN 1
	END

	IF (@INCo IS NULL)
	BEGIN
		SET @msg = 'Inventory Company is required when Source is set to Inventory.'
		RETURN 1
	END
	
	IF (@INLocation IS NULL)
	BEGIN
		SET @msg = 'Inventory Location is required when Source is set to Inventory.'
		RETURN 1
	END

	-- Validate the material by INCo and IN Location.
	SELECT * FROM INMT WHERE INCo = @INCo AND Loc = @INLocation AND MatlGroup = @MaterialGroup AND Material = @Material
	IF @@ROWCOUNT = 0
	BEGIN
		SELECT @msg = 'Invalid Material.', @IsValidMaterial = 'N'
		RETURN 1
	END
	
	SELECT 
		@MaterialUMDefault = StdUM, 
		@PriceUMDefault = SalesUM, 
		@IsTaxable = Taxable, 
		@msg = [Description] 
	FROM HQMT 
	WHERE 
		MatlGroup = @MaterialGroup 
		AND Material = @Material

	
	SET @IsValidMaterial = 'Y'
	
	--TK-11897
    DECLARE @rcode TINYINT
    SET @rcode = 0
    
    EXEC	@rcode = vspSMJCCostTypeDefaultVal 
			@SMCo = @SMCo
			, @Job = @Job
			, @LineType = 4 -- Material
			, @MatlGroup = @MaterialGroup
			, @Material = @Material
			, @SMCostType = @SMCostType
			, @JCCostType = @JCCostType OUTPUT
			, @msg = @msg OUTPUT
    
    RETURN @rcode
END




GO
GRANT EXECUTE ON  [dbo].[vspSMWorkCompletedInventoryMaterialVal] TO [public]
GO
