SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO








/* =============================================
-- Author:		Jeremiah Barkley
-- Create date: 3/8/11
-- Description:	Determine the inventory cost of a part.  Cost Method is an 
				optional parameter (1-3) that will determine where cost is
				pulled from.  If it is NULL, the cost method will be pulled 
				from Inventory.  This is *Inventory's Cost* not to be confused
				with SM Part Cost (Inventory's price to SM).
-- Parameter Notes:
	@INCo
	@INLocation
	@MaterialGroup
	@Material
	@CostUM
	@Quantity		- Optional.  If provided the Cost Total will be calculated.
	@CostMethod		- Optional.  Will cost based on the provided cost method, otherwise it
					will determine the cost method normally.
	@CostPerUnit	- Returns the cost per unit.
	@CostECM		- Returns the cost per unit ECM.
	@CostPerEach	- Returns the Cost per Each (ECM factored out).
	@CostTotal		- Returns the Cost Total only if the quantity is provided.
	@msg			- Returns any error messages.
=============================================*/
CREATE PROCEDURE [dbo].[vspSMINMaterialCostGet]
	@INCo AS bCompany,
	@INLocation AS bLoc,
	@MaterialGroup AS bGroup,
	@Material AS bMatl,
	@CostUM AS bUM,
	@Quantity AS bUnits = NULL,
	@CostMethod AS int = NULL OUTPUT,
	@CostPerUnit AS bUnitCost OUTPUT,
	@CostECM AS bECM OUTPUT,
	@CostPerEach AS bUnitCost OUTPUT,
	@CostTotal AS bDollar OUTPUT,
	@msg AS varchar(255) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @IsStdUM bit, @UnitCost bUnitCost, @Conversion bUnitCost, @Factor int
	
	--Validate parameters are supplied correctly
	IF (@Material IS NULL OR @CostUM IS NULL OR @INCo IS NULL OR @INLocation IS NULL)
	BEGIN
		SELECT @msg = 'Not enough information has been provided to retrieve the material cost.'
		RETURN 1
	END
	
	-- Validate Cost Method if it was passed in
	IF (@CostMethod IS NOT NULL AND (@CostMethod < 0 OR @CostMethod > 3))
	BEGIN
		SELECT @msg = 'Invalid cost method provided to SMINMaterialCostGet'
		RETURN 1
	END
	
	-- Determine if this is the std UM or an additional UM
	SELECT @IsStdUM = 0
	SELECT @IsStdUM = 1 FROM HQMT WHERE HQMT.MatlGroup = @MaterialGroup AND HQMT.Material = @Material AND HQMT.StdUM = @CostUM
		
	
	
	IF (@CostMethod IS NULL OR @CostMethod = 0)
	BEGIN
		-- If the cost method is not provided then determine the cost method from INLM
		SELECT @CostMethod = CostMethod FROM INLM WHERE INCo = @INCo AND Loc = @INLocation
		
		-- If CostMethod is set to 0 (No Override) then get the cost method from INCO
		IF (@CostMethod = 0)
		BEGIN 
			SELECT @CostMethod = CostMethod FROM INCO WHERE INCo = @INCo
		END
	END
	
	-- Determine the cost
	IF (@IsStdUM = 1 OR @CostMethod = 1)
	BEGIN
		-- If this UM is the Standard UM OR the costing method is average then get the cost from INMT
		SELECT 
			@CostPerUnit = CASE 
							WHEN @CostMethod = 1 THEN INMT.AvgCost 
							WHEN @CostMethod = 2 THEN INMT.LastCost
							WHEN @CostMethod = 3 THEN INMT.StdCost 
							END,
			@CostECM = CASE 
							WHEN @CostMethod = 1 THEN INMT.AvgECM
							WHEN @CostMethod = 2 THEN INMT.LastECM
							WHEN @CostMethod = 3 THEN INMT.StdECM
							END
		FROM dbo.INMT
		WHERE
			INMT.INCo = @INCo
			AND INMT.Loc = @INLocation
			AND INMT.MatlGroup = @MaterialGroup
			AND INMT.Material = @Material
		
		IF (@@ROWCOUNT = 0)
		BEGIN
			SELECT @msg = 'Material is not set up in IN Location Materials'
			RETURN 1
		END
		
		-- If this is not the StdUM but it is average cost then convert the unit cost 
		-- so that it is in the cost UM
		IF (@IsStdUM <> 1 AND @CostMethod = 1)
		BEGIN
			SELECT @Conversion = Conversion 
			FROM dbo.INMU 
			WHERE 
				INMU.INCo = @INCo
				AND INMU.Loc = @INLocation
				AND INMU.MatlGroup = @MaterialGroup
				AND INMU.Material = @Material
				AND INMU.UM = @CostUM
				
			SELECT @CostPerUnit = @CostPerUnit * @Conversion
		END
	END
	ELSE
	BEGIN
		-- This is an additional UM AND not average cost UM so determine the Cost from INMU
		SELECT 
			@CostPerUnit = CASE 
							WHEN @CostMethod = '2' THEN INMU.LastCost
							WHEN @CostMethod = '3' THEN INMU.StdCost 
							END,
			@CostECM = CASE 
							WHEN @CostMethod = '2' THEN INMU.LastECM
							WHEN @CostMethod = '3' THEN INMU.StdCostECM
							END
		FROM INMU
		WHERE
			INMU.INCo = @INCo
			AND INMU.Loc = @INLocation
			AND INMU.MatlGroup = @MaterialGroup
			AND INMU.Material = @Material
			AND INMU.UM = @CostUM
		
		IF (@@ROWCOUNT = 0)
		BEGIN
			SELECT @msg = 'Price UM is not set up for this Material in IN Location Materials'
			RETURN 1
		END
	END
	
	-- Determine the CostPerEach
	SELECT @Factor = CASE @CostECM 
						WHEN 'M' THEN 1000
						WHEN 'C' THEN 100 
						ELSE 1
						END
	
	SELECT @CostPerEach = (@CostPerUnit / @Factor)
	
	IF (@Quantity IS NOT NULL)
	BEGIN
		SET @CostTotal = @CostPerEach * @Quantity
	END
	
	RETURN 0
END





GO
GRANT EXECUTE ON  [dbo].[vspSMINMaterialCostGet] TO [public]
GO
