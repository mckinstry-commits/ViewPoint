SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







/* =============================================
-- Author:		Jeremiah Barkley
-- Create date: 1/12/11
-- Description:	Determine the invetory cost of a part.  Cost Method is an 
				optional parameter (1-3) that will determine where cost is
				pulled from.  If it is NULL, the cost method will be pulled 
				from Inventory.
=============================================*/
CREATE PROCEDURE [dbo].[vspSMPartInventoryCostGet]
	@INCo AS bCompany,
	@INLocation AS bLoc,
	@MaterialGroup AS bGroup,
	@Part AS bMatl,
	@CostUM AS bUM,
	@CostPerUnit AS bUnitCost OUTPUT,
	@CostECM AS bECM OUTPUT,
	@CostPerEach AS bUnitCost OUTPUT,
	@msg AS varchar(255) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	
	--Validate parameters are supplied correctly
	IF (@Part IS NULL OR @CostUM IS NULL OR @INCo IS NULL OR @INLocation IS NULL)
	BEGIN
		SELECT @msg = 'Not enough information has been provided to retrieve the part cost.'
		RETURN 1
	END

	DECLARE @ServicePriceOption tinyint, @IsStdUM bit, @Conversion bUnitCost, @BaseRate bUnitCost, 
		@ServiceRate bRate, @Factor int
	
	-- Determine if this is the std UM or an additional UM
	SELECT @IsStdUM = 0, @ServiceRate = NULL
	
	IF EXISTS(SELECT 1 FROM dbo.HQMT WHERE HQMT.MatlGroup = @MaterialGroup AND HQMT.Material = @Part AND HQMT.StdUM = @CostUM)
	BEGIN
		SET @IsStdUM = 1
	END
	
	-- Get the Service Sale pricing option from INCO
	SELECT @ServicePriceOption = ServicePriceOpt FROM dbo.INCO WHERE INCo = @INCo
	
	-- Determine the base amount from the pricing option
	IF (@IsStdUM = 1 OR @ServicePriceOption = 1)
	BEGIN
		-- Get the base rate from INMT if using the std UM OR if using average cost
		SELECT 
			@BaseRate = CASE 
							WHEN @ServicePriceOption = 1 THEN AvgCost
							WHEN @ServicePriceOption = 2 THEN LastCost
							WHEN @ServicePriceOption = 3 THEN StdCost
							WHEN @ServicePriceOption = 4 THEN StdPrice
							END,
			@CostECM = CASE 
							WHEN @ServicePriceOption = 1 THEN AvgECM
							WHEN @ServicePriceOption = 2 THEN LastECM
							WHEN @ServicePriceOption = 3 THEN StdECM
							WHEN @ServicePriceOption = 4 THEN PriceECM
							END,
			@ServiceRate = ServiceRate 
		FROM dbo.INMT 
		WHERE 
			INCo = @INCo 
			AND Loc = @INLocation
			AND MatlGroup = @MaterialGroup
			AND Material = @Part
			
		-- If this is not the StdUM but it is average cost then convert the unit cost 
		-- so that it is in the cost UM
		IF (@IsStdUM <> 1 AND @ServicePriceOption = 1)
		BEGIN
			SELECT @Conversion = Conversion 
			FROM dbo.INMU 
			WHERE 
				INCo = @INCo
				AND Loc = @INLocation
				AND MatlGroup = @MaterialGroup
				AND Material = @Part
				AND UM = @CostUM
				
			SET @BaseRate = @BaseRate * @Conversion
		END
	END
	ELSE
	BEGIN
		-- Get the base rate from INMU if using any additional UM and not average cost
		SELECT 
			@BaseRate = CASE 
							WHEN @ServicePriceOption = 2 THEN LastCost
							WHEN @ServicePriceOption = 3 THEN StdCost
							WHEN @ServicePriceOption = 4 THEN Price
							END,
			@CostECM = CASE 
							WHEN @ServicePriceOption = 2 THEN LastECM
							WHEN @ServicePriceOption = 3 THEN StdCostECM
							WHEN @ServicePriceOption = 4 THEN PriceECM
							END
		FROM dbo.INMU
		WHERE 
			INCo = @INCo 
			AND Loc = @INLocation
			AND MatlGroup = @MaterialGroup
			AND Material = @Part
			AND UM = @CostUM
	END
	
	-- Get the Markup/Discount from INMT if it was not already retrieved.
	IF (@ServiceRate IS NULL)
	BEGIN
		SELECT @ServiceRate = ServiceRate 
		FROM dbo.INMT 
		WHERE 
			INCo = @INCo 
			AND Loc = @INLocation
			AND MatlGroup = @MaterialGroup
			AND Material = @Part
	END
	
	-- Calculate the cost per unit
	IF (@ServicePriceOption = 4)
	BEGIN
		SET @CostPerUnit = @BaseRate - (@BaseRate * @ServiceRate)
	END
	ELSE
	BEGIN
		SET @CostPerUnit = @BaseRate + (@BaseRate * @ServiceRate)
	END
	
	-- Calculate the cost per Each
	SELECT @Factor = CASE @CostECM 
						WHEN 'M' THEN 1000
						WHEN 'C' THEN 100 
						ELSE 1
						END
	
	SELECT @CostPerEach = (@CostPerUnit / @Factor)
	
	RETURN 0
END




GO
GRANT EXECUTE ON  [dbo].[vspSMPartInventoryCostGet] TO [public]
GO
