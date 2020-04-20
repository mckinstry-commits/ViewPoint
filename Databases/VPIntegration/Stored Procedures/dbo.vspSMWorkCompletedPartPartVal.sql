SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




/* =============================================
-- Author:		Jeremiah Barkley
-- Modified:	GP 7/28/2011 - TK-07143 changed bPO to varchar(30)
-- Create date: 8/26/2010
-- Description:	Part validation for SM Work Order Part Detail.
=============================================*/
CREATE PROCEDURE [dbo].[vspSMWorkCompletedPartPartVal]
	@SMCo AS dbo.bCompany,
	@Source AS tinyint,
	@INCo AS bCompany,
	@INLocation AS bLoc,
	@POCo AS bCompany,
	@PONumber AS varchar(30),
	@POItem AS bItem,
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
	

	IF (@Source = 0)
	BEGIN
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
	END
	ELSE IF (@Source = 1)
	BEGIN
		IF (@POItem IS NULL)
		BEGIN
			-- Validate the material in HQMT and get the Default UM and Taxable status
			SELECT 
				@PriceUMDefault = SalesUM, 
				@IsTaxable = Taxable, 
				@MaterialUMDefault = PurchaseUM, 
				@msg = [Description] 
			FROM HQMT 
			WHERE 
				MatlGroup = @MaterialGroup 
				AND Material = @Material
			IF @@ROWCOUNT = 0
			BEGIN
				SELECT @msg = 'Material not on file.', @IsValidMaterial = 'N'
				RETURN 0
			END
		END
		ELSE
		BEGIN
			-- Validate the material in HQMT and get the Taxable status
			SELECT @IsTaxable = Taxable
			FROM HQMT 
			WHERE MatlGroup = @MaterialGroup AND Material = @Material
			IF @@ROWCOUNT = 0
			BEGIN
				SELECT @msg = 'Material not on file.', @IsValidMaterial = 'N'
				RETURN 0
			END
		END
	END
	
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
GRANT EXECUTE ON  [dbo].[vspSMWorkCompletedPartPartVal] TO [public]
GO
