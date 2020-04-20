SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--CREATE procedure [dbo].[vspEMDepreciationSL]
CREATE procedure [dbo].[vspEMDepreciationSL]

/************************************************************************
* CREATED:	Dan Sochacki 07/08/2008     
* MODIFIED:    
*
* USAGE:
*	Calculate Straight-line Depreication 
*
* TYPES:
*	Straight Line Depreciation Method
*		- (Purchase Price of Asset - Approx Salvage Value)/ Est Useful Life of Asset
*************************************************************************/

	   (@EMCo bCompany, @Equipment bEquip, @Asset VARCHAR(20),
		@PurchasePrice bDollar = NULL, @SalvageVal bDollar = NULL, 
		@NumMonths INT = NULL, @StartDate bDate = NULL, 
		@errmsg VARCHAR(MAX) OUTPUT)

AS
   
SET NOCOUNT ON

	DECLARE @AmtToDepr			bDollar,
			@MonthlyDepr		bDollar,
			@AmtLeft			bDollar,
			@AmtTaken			bDollar,
			@DeprMonth			bDate,
			@Counter			int,
			@rcode				int;


	------------------
	-- PRIME VALUES --
	------------------
	SET @AmtToDepr = 0
	SET @MonthlyDepr = 0
	SET @AmtLeft = 0
	SET @AmtTaken = 0
	SET @DeprMonth = @StartDate
	SET @Counter = 1
	SET @errmsg = ''
	SET @rcode = 0


	-------------------------------
	-- CALC MONTHLY DEPRECIATION --
	-------------------------------
	SET @AmtToDepr = @PurchasePrice - @SalvageVal
	SET @MonthlyDepr = @AmtToDepr / @NumMonths
	SET @AmtLeft = @AmtToDepr

	-------------------------------------------
	-- CYCLE THROUGH ALL DEPRECIATION MONTHS --
	-------------------------------------------
	WHILE @Counter != @NumMonths 
		BEGIN

			-------------------
			-- INSERT VALUES --
			-------------------
			INSERT EMDS (EMCo, Equipment, Asset, Month, AmtToTake, AmtTaken)
        	VALUES (@EMCo, @Equipment, @Asset, @DeprMonth, @MonthlyDepr, 0)

			------------------
			-- CALC AMOUNTS --
			------------------
			SET @AmtTaken = @AmtTaken + @MonthlyDepr
			SET @AmtLeft = @AmtToDepr - @AmtTaken

			-------------------
			-- UPDATE VALUES --
			-------------------
			SET @DeprMonth = DateAdd(m, 1, @DeprMonth)
			SET @Counter = @Counter + 1
		END

		---------------------------------------------------------
		-- LAST MONTH OF LAST YEAR = AMOUNT LEFT TO DEPRECIATE --
		---------------------------------------------------------
		SET @MonthlyDepr = @AmtLeft

		-----------------------
		-- INSERT LAST MONTH --
		-----------------------
		INSERT EMDS (EMCo, Equipment, Asset, Month, AmtToTake, AmtTaken)
    	VALUES (@EMCo, @Equipment, @Asset, @DeprMonth, @MonthlyDepr, 0)
			
 
vspExit:
	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMDepreciationSL] TO [public]
GO
