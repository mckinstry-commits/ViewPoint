SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--CREATE procedure [dbo].[vspEMDepreciationDB]
CREATE procedure [dbo].[vspEMDepreciationDB]

/************************************************************************
* CREATED:	Dan Sochacki 07/08/2008     
* MODIFIED:    
*
* USAGE:
*	Prototyping Double Declining Depreciation Method
*
* TYPE:
*	Declining Balance Depreciation Method
*		- Full Year
*			- Depreciable Base * ((Decline Factor * 100%) / (Useful Life in Years))
*		- Partial Year
*			- Annual depreciation expense is multiplied by a fraction that has 
*				the number of months the asset depreciates as its numerator and 
*				twelve as its denominator. Since depreciation expense calculations 
*				are estimates to begin with, rounding the time period to the nearest 
*				month is acceptable for financial reporting purposes. 
*
* NOTES:
*	Will switch to Straight-line depreciation when it is more advantageous then Double Declining
*************************************************************************/

	   (@EMCo bCompany, @Equipment bEquip, @Asset VARCHAR(20),
		@PurchasePrice bDollar = NULL, @SalvageVal bDollar = NULL, @NumMonths INT = NULL, 
		@StartDate bDate = NULL, @FYEM bDate = NULL, @DeclineFactor DECIMAL(5,4) = NULL,
		@errmsg VARCHAR(MAX) OUTPUT)

AS
   
SET NOCOUNT ON

	DECLARE @DDDeprFactor		decimal(8,7),	-- YEARLY DEPRECIATION FACTOR
			@BookValue			bDollar,		-- ASSETS VALUE
			@BookFirstAmt		bDollar,		-- BOOK VALUE USED FOR FIRST MONTHS OF PARTIAL YEAR
			@BookLastAmt		bDollar,		-- BOOK VALUE USED FOR lAST MONTHS OF PARTIAL YEAR
			@FirstPartAmt		bDollar,		-- AMOUNT TO DEPRECIATE USED FOR FIRST MONTHS OF PARTIAL YEAR
			@LastPartAmt		bDollar,		-- AMOUNT TO DEPRECIATE USED FOR LAST MONTHS OF PARTIAL YEAR
			@FirstPartYR		int,			-- FIRST MONTHS OF THE YEAR		
			@LastPartYR			int,			-- LAST MONTHS OF THE YEAR
			@FirstPartFactor	decimal(8,7),	-- FIRST MONTHS DECIMAL % OF YEAR
			@LastPartFactor		decimal(8,7),	-- LAST MONTHS DECIMAL % OF YEAR
			@SLMonthlyAmt		bDollar,		-- STRAIGHT LINE DEPRECIATION MONTHLY AMOUNT
			@MonthlyDepr		bDollar,		-- AMOUNT OF DEPRECIATION TO BE TAKEN MONTHLY
			@AmtTaken			bDollar,		-- TOTAL AMOUNT OF DEPRECIATION TAKEN
			@UseSLFlag			bYN,			-- SET TO 'Y' WHEN DEPRECIATION SWITCH FROM DOUBLE DECLINING TO STRAIGHT LINE
			@MonthsRemaining	int,			-- NUMBER OF MONTHS LEFT TO BE DEPRECIATED
			@DeprMonth			bDate,
			@Counter			int,
			@rcode				int;


	------------------
	-- PRIME VALUES --
	------------------
	SET @errmsg = ''
	SET @rcode = 0
	SET @DDDeprFactor = 0
	SET @BookFirstAmt = 0
	SET @BookLastAmt = 0 
	SET @FirstPartAmt = 0
	SET @LastPartAmt = 0
	SET	@FirstPartYR = 0		
	SET	@LastPartYR = 0			
	SET	@FirstPartFactor = 0
	SET	@LastPartFactor	= 0
	SET @DeprMonth = @StartDate
	SET @MonthlyDepr = 0
	SET @Counter = 1
	SET @AmtTaken = 0
	SET @SLMonthlyAmt = 0
	SET @BookValue = 0
	SET @MonthsRemaining = 0
	SET @UseSLFlag = 'N'


	---------------------------------------
	-- CALCULATE DEPRECIATION PERCENTAGE --
	---------------------------------------
	SET @DDDeprFactor = (1.0/(@NumMonths/12.0)) * @DeclineFactor

	-----------------------------------------------------
	-- SET INITIAL AMOUNTS FOR FIRST YEAR DEPRECIATION --
	----------------------------------------------------- 
	SET @BookValue = @PurchasePrice
	SET @BookLastAmt = @PurchasePrice * @DDDeprFactor 

	IF @DDDeprFactor = 1
		BEGIN
			SET @BookLastAmt = @PurchasePrice * @DDDeprFactor - @SalvageVal
		END

	-----------------------------------
	-- CALCULATE YEAR PORTION VALUES --
	-----------------------------------
	SET @LastPartYR = ABS(DateDiff(m, @StartDate, @FYEM)) + 1
	SET @FirstPartYR = 12 - @LastPartYR
	SET @FirstPartFactor = (@FirstPartYR / 12.0)

	IF @LastPartYR > 0 
		BEGIN
			SET @LastPartFactor = (@LastPartYR / 12.0)
			SET @LastPartAmt = @LastPartFactor * @BookLastAmt
			SET @MonthlyDepr = @LastPartAmt / @LastPartYR
		END
	ELSE
		BEGIN
			SET @FirstPartAmt = @FirstPartFactor * @BookLastAmt
			SET @MonthlyDepr = @FirstPartAmt / @FirstPartYR
		END


	------------------------------
	-- CYCLE THROUGH ALL MONTHS --
	------------------------------
	WHILE @Counter != @NumMonths 
		BEGIN

			-------------------
			-- INSERT VALUES --
			-------------------
			INSERT EMDS (EMCo, Equipment, Asset, Month, AmtToTake, AmtTaken)
    		VALUES (@EMCo, @Equipment, @Asset, @DeprMonth, @MonthlyDepr, 0)

			-------------------
			-- UPDATE AMOUNT --
			-------------------
			SET @AmtTaken = @AmtTaken + @MonthlyDepr

			-------------------------------------
			-- CHECK FOR BEGINNING OF NEW YEAR --
			-------------------------------------
			IF MONTH(@DeprMonth) = MONTH(@FYEM)
				BEGIN

					-----------------------------------------------------------------
					-- CHECK FLAG TO SEE IF SWITCHED TO STRAIGHT LINE DEPRECIATION --
					-----------------------------------------------------------------
					IF @UseSLFlag = 'N'
						BEGIN
	
							------------------
							-- RESET VALUES --
							------------------
							SET @FirstPartAmt = 0
							SET @LastPartAmt = 0

							---------------------------------------------
							-- CALC/RECALC FIRST PART OF YEARS AMOUNTS --
							---------------------------------------------
							SET @BookFirstAmt = @BookLastAmt	
							SET @FirstPartAmt = @FirstPartFactor * @BookFirstAmt

							-----------------------
							-- RECALC NEW VALUES --
							-----------------------
							SET @BookValue = @PurchasePrice - @AmtTaken - @FirstPartAmt
							SET @MonthsRemaining = @NumMonths - @Counter

							----------------------------------
							-- CHECK FOR FINAL YEAR TO CALC --
							----------------------------------
							IF (@Counter + @FirstPartYR + @LastPartYR) < (@NumMonths - @FirstPartYR)
								BEGIN
									SET @BookLastAmt = @BookValue * @DDDeprFactor 
								END
							ELSE
								BEGIN
									------------------------------------------------------
									-- CALC LAST YEAR - TAKE INTO ACCOUNT SALVAGE VALUE --
									------------------------------------------------------
									SET @BookLastAmt = @BookValue - @SalvageVal					
								END

							SET @LastPartAmt = @LastPartFactor * @BookLastAmt
							SET @MonthlyDepr  = (@FirstPartAmt + @LastPartAmt) / (@FirstPartYR + @LastPartYR)

							------------------------------------------------
							-- CALC THE REMAINING MONTHS OF THE LAST YEAR --
							------------------------------------------------
							IF @MonthsRemaining <= @FirstPartYR
								BEGIN
									SET @MonthlyDepr  = @FirstPartAmt / @MonthsRemaining
								END

							----------------------------------------------------------------
							-- PROTECT AGAINST NEGATIVE DEPRECIATION - FORCE SWITCH TO SL --
							----------------------------------------------------------------
							IF (@FirstPartAmt + @LastPartAmt) > (@PurchasePrice - @SalvageVal - @AmtTaken)
								BEGIN
									SET @MonthlyDepr = 0
								END

							------------------------------------------------------------------------
							-- CHECK TO SEE IF IT IS TIME TO SWITCH TO STRAIGHT LINE DEPRECIATION --
							------------------------------------------------------------------------
							SET @SLMonthlyAmt = ((@PurchasePrice - @SalvageVal - @AmtTaken) / @MonthsRemaining)
														
							IF @SLMonthlyAmt > @MonthlyDepr
								BEGIN
									SET @MonthlyDepr = @SLMonthlyAmt
									SET @UseSLFlag = 'Y'
								END

						END --IF @UseSLFlag = 'N'

				END --IF MONTH(@DeprMonth) = MONTH(@FYEM)

			----------------------
			-- UPDATE VARIABLES --
			----------------------
			SET @DeprMonth = DateAdd(m, 1, @DeprMonth)
			SET @Counter = @Counter + 1

		END --WHILE @Counter != @NumMonths


		----------------------------------
		-- CALC LAST MONTH OF LAST YEAR --
		----------------------------------
		SET @MonthlyDepr = @PurchasePrice - @SalvageVal - @AmtTaken -- takes care of rounding errors

		-----------------------
		-- INSERT LAST MONTH --
		-----------------------
		INSERT EMDS (EMCo, Equipment, Asset, Month, AmtToTake, AmtTaken)
    	VALUES (@EMCo, @Equipment, @Asset, @DeprMonth, @MonthlyDepr, 0)

vspExit:
	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMDepreciationDB] TO [public]
GO
