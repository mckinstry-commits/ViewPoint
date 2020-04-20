SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







/* =============================================
-- Author:		Lane Gresham
-- Create date: 11/16/12
-- Modified By: 
--
--
-- Description:	Determine the cost of a purchase.
=============================================*/
CREATE PROCEDURE [dbo].[vspSMPurchaseCostGet]
	@CreateNewPOItem bYN,
	@POCo AS bCompany,
	@PONumber AS varchar(30),
	@POItem AS bItem,
	@POItemLine AS int,
	@MaterialGroup AS bGroup,
	@Part AS bMatl,
	@PartUM AS bUM,
	@Quantity AS bUnits, 
	@CostPerUnit AS bUnitCost OUTPUT,
	@CostECM AS bECM OUTPUT,
	@CostTotal AS bDollar OUTPUT,
	@msg as varchar(255) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @Factor int, @CostPerEach bUnitCost, @CostFactor int
	
	--Validate parameters are supplied correctly
	IF (@MaterialGroup IS NULL OR @PartUM IS NULL OR @Quantity IS NULL)
	BEGIN
		SELECT @msg = 'Not enough information has been provided to calculate the part cost.'
		RETURN 1
	END
	
	-- Handle costs from parts on a PO
	
	IF (@POCo IS NULL OR @PONumber IS NULL)
	BEGIN
		SELECT @msg = 'PO Company and PO Number are required for costing.'
		RETURN 1
	END
	
	IF (@CostTotal IS NOT NULL)
	BEGIN
		-- Cost Calculations if the total is provided.
		IF (@PartUM = 'LS')
		BEGIN
			-- Use the total cost
			SELECT @CostPerUnit = 0	--, @CostECM = 'E'
			RETURN 0
		END
		ELSE
		BEGIN
			-- Determine Cost per Unit based on total
			IF (@CostECM IS NULL)
			BEGIN
				SET @CostECM = 'E'
			END
			SELECT @CostFactor = CASE @CostECM 
									WHEN 'M' THEN 1000
									WHEN 'C' THEN 100 
									ELSE 1
									END
			
			IF (@Quantity <> 0)
			BEGIN
				SET @CostPerUnit = @CostTotal / @Quantity * @CostFactor
			END
			ELSE RETURN 0
		END
	END
	ELSE
	BEGIN
		-- Cost Calculations if total is not provided
		IF (~dbo.vfEqualsNull(@POItem) & ~dbo.vfEqualsNull(@POItemLine) = 1)
		BEGIN
			-- Get Costs from the PO
			SELECT 
				@CostPerUnit = POIT.OrigUnitCost, --Should this be CurUnitCost?
				@CostECM = POIT.OrigECM, --Should this be CurECM?
				@CostTotal = POItemLine.TotalCost
			FROM dbo.POItemLine
				INNER JOIN dbo.POIT ON POItemLine.POCo = POIT.POCo AND POItemLine.PO = POIT.PO AND POItemLine.POItem = POIT.POItem
			WHERE POItemLine.POCo = @POCo AND POItemLine.PO = @PONumber AND POItemLine.POItem = @POItem AND POItemLine.POItemLine = @POItemLine AND POItemLine.ItemType = 6 
	
			IF (@@ROWCOUNT = 0)
			BEGIN
				SET @msg = 'Invalid PO Item for this work order.'
				RETURN 1
			END
			
			IF (@PartUM = 'LS')
			BEGIN
				-- The total cost does not need to be calculated so exit
				RETURN 0
			END
		END
		ELSE
		BEGIN
			-- PO Item is null - This is a PO Item created on the fly
			IF (@PartUM = 'LS')
			BEGIN
				SELECT @CostPerUnit = 0	--, @CostECM = 'E'
				RETURN 0
			END
			
			IF (@CostPerUnit IS NULL)
			BEGIN
				-- Get Cost from HQ (This is used when adding a PO Item on the fly)
				SELECT
					@CostPerUnit = Cost,
					@CostECM = CostECM
				FROM dbo.HQMT
				WHERE
					MatlGroup = @MaterialGroup
					AND Material = @Part
					AND StdUM = @PartUM
					
				IF (@@ROWCOUNT = 0)
				BEGIN
					-- Try to get cost from HQMU (if the UM is an additional UM)
					
					SELECT
						@CostPerUnit = Cost,
						@CostECM = CostECM
					FROM dbo.HQMU
					WHERE
						MatlGroup = @MaterialGroup
						AND Material = @Part
						AND UM = @PartUM
					
					IF (@@ROWCOUNT = 0)
					BEGIN
						-- Default Cost Per Unit to 0 - This will occur when the Part is 
						-- on a PO and is not a valid part and therefore no cost can be found.
						SET @CostPerUnit = 0.00
					END
				END
			END

			-- Use the Cost Rate that was passed in, set a default ECM if none exists
			IF (@CostECM IS NULL)
			BEGIN
				SET @CostECM = 'E'
			END
		END
	
		SELECT @CostFactor = CASE @CostECM 
								WHEN 'M' THEN 1000
								WHEN 'C' THEN 100 
								ELSE 1
								END
								
		SELECT @CostPerEach = (@CostPerUnit / @CostFactor)
		SELECT @CostTotal = (@Quantity * @CostPerEach)
	END


	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMPurchaseCostGet] TO [public]
GO
