SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--CREATE procedure [dbo].[vspEMDepreciationMain]
CREATE procedure [dbo].[vspEMDepreciationMain]

/************************************************************************
* CREATED:	Dan Sochacki 07/08/2008     
* MODIFIED: Dan Sochacki 01/12/2009 - Issue: #131752 - had to make sure NumMonths >= MinMonths for DB AND SL  
*			Dan Sochacki 01/16/2009	- Issue: #131817 - delete schedule records after Disposal Month
*			Dan Sochacki 03/04/2009	- Issue: #132476 - Recalc DB from FYEM forward
*
*			
* USAGE:
*	Perform calculations and rules before determining depreication. 
*
* TYPES:
*	Straight Line 
*	Declining Balance
*************************************************************************/
	   (@EMCo bCompany, @Equipment bEquip, @Asset VARCHAR(20),
		@Method CHAR(1) = NULL, @PurchasePrice bDollar = NULL, @SalvageVal bDollar = NULL, 
		@NumMonths INT = NULL, @StartDate bDate = NULL, @FYEM bDate = NULL, 
		@ReCalculate bYN = NULL, @DeclineFactor DECIMAL(5,4) = NULL,
		@errmsg VARCHAR(MAX) OUTPUT)

AS
   
SET NOCOUNT ON

	DECLARE @AmtToDepr			bDollar,
			@MonthlyDepr		bDollar,
			@DeprAmtTaken		bDollar,
			@BeginDeprMonth		bDate,
			@FirstSchedMonth	bDate,
			@LastMonthTaken		bDate,
			@LastMonthClosed	bDate,
			@DisposalMonth		bDate,
			@FYBeginMonth		bDate,
			@MinMonths			int,
			@MonthDiff			int,
			@YearDiff			int,
			@rcode				int;


	------------------
	-- PRIME VALUES --
	------------------
	SET @AmtToDepr = @PurchasePrice
	SET @MonthlyDepr = 0
	SET @DeprAmtTaken = 0
	SET @BeginDeprMonth = @StartDate
	SET @MinMonths = 1
	SET @MonthDiff = 0
	SET @errmsg = ''
	SET @rcode = 0


	-- Issue: #131817
	------------------------
	-- GET DISPOSAL MONTH --
	------------------------
	SELECT	@DisposalMonth = MonthDisposed
      FROM	EMDP
	 WHERE	EMCo = @EMCo
	   AND	Equipment = @Equipment
	   AND	Asset = @Asset

	-----------------------------------------------------
	-- IF DISPOSAL MONTH EXISTS						   --
	-- DELETE ALL SCHEDULE RECORDS AFTER DISPOSAL DATE --
	-----------------------------------------------------
	IF @DisposalMonth IS NOT NULL
		BEGIN

			------------------------------------------
			-- CHECK TO MAKE SURE A SCHEDULE EXISTS --
			------------------------------------------
			IF EXISTS (select top 1 1 FROM EMDS WHERE EMCo = @EMCo and Equipment = @Equipment and Asset = @Asset)
				BEGIN
					--------------------------------------------------
					-- REMOVE ALL SCHEDULED MONTHS > DISPOSAL MONTH --
					--------------------------------------------------
					DELETE FROM EMDS 
						WHERE EMCo = @EMCo and Equipment = @Equipment and Asset = @Asset and Month > @DisposalMonth
				END
			ELSE
				BEGIN
					SET @errmsg = 'To calculate a Depreciation Schedule - remove Disposal Date and press Calculate again.'
					SET @rcode = 1
				END
			GOTO vspExit
		END


	--------------------------------------
	-- VERIFY FYEMO IS VALID			--
	--  1. NEEDED FOR DECLINING BALANCE --
	--	2. MUST EXIST					--
	--	3. THE YEAR HAS NOT BEEN CLOSED --
	--------------------------------------
	IF @Method = 'D'
		BEGIN

			-- Issue: #132476 --
			SELECT @FYBeginMonth = y.BeginMth
			  FROM GLCO o WITH (NOLOCK)
			  JOIN GLFY y WITH (NOLOCK) ON o.GLCo = y.GLCo
			 WHERE o.GLCo = @EMCo
			   AND y.FYEMO = @FYEM
			   AND o.LastMthGLClsd < y.FYEMO

			IF @FYBeginMonth IS NULL
				BEGIN
					SET @errmsg = CONVERT(VARCHAR, @FYEM, 101) + ' is not a valid FYEMO.'
					SET @rcode = 1
        			GOTO vspExit
				END

			--------------------------------------------
			-- CALCULATE THE MINIMUM NUMBER OF MONTHS --
			-- NECESSARY TO FIGURE DEPRECIATION 'D'   --
			--------------------------------------------
			SET @MinMonths = ROUND((@DeclineFactor * 12.0),0,1)
			IF ((@DeclineFactor * 12.0) % 1) <> 0 
				BEGIN
					SET @MinMonths = ROUND((@DeclineFactor * 12.0),0,1) + 1
				END

		END --IF @Method = 'D'

	------------------------------------------
	-- CHECK FOR RECALCULATING DEPRECIATION --
	------------------------------------------
	IF @ReCalculate = 'Y'
		BEGIN

			--------------------------------------------------
			-- GET FIRST MONTH AND TOTAL DEPRECIATION TAKEN --
			--------------------------------------------------
			SELECT  @FirstSchedMonth = MIN(Month), @DeprAmtTaken = SUM(AmtTaken)
			  FROM  EMDS
			 WHERE	EMCo = @EMCo
			   AND	Equipment = @Equipment
			   AND	Asset = @Asset
	
			-------------------------------------
			-- GET FIRST OPEN MONTH FOR RECALC --
			-------------------------------------
			SELECT	@LastMonthClosed = LastMthGLClsd
			  FROM	GLCO WITH (NOLOCK)
			 WHERE  GLCo = @EMCo
			
			-------------------------------------------
			-- GET LAST MONTH DEPRECIATION WAS TAKEN --
			-------------------------------------------									   
			SELECT	@LastMonthTaken = ISNULL(MAX(Month), @FirstSchedMonth) 
			  FROM	EMDS
			 WHERE	EMCo = @EMCo
			   AND	Equipment = @Equipment
			   AND	Asset = @Asset
			   AND	AmtTaken <> 0

			-- ------------------------------- --
			-- CAN NOT CHANGE START MONTH IF   --
			-- ALREADY TAKEN SOME DEPRECIATION --
			-- ------------------------------- --
			IF @DeprAmtTaken = 0
				BEGIN
					SET @BeginDeprMonth = @FirstSchedMonth
				END
			ELSE
				BEGIN
					---------------------------------------------------------------
					-- CALC NEW DEPRECIATION DATE AND NUMBER OF MONTHS REMAINING --
					---------------------------------------------------------------
					IF @LastMonthClosed > @LastMonthTaken
						BEGIN
							SET @BeginDeprMonth = DATEADD(m, 1, @LastMonthClosed)
							SET @NumMonths = @NumMonths - (DateDiff(m, @FirstSchedMonth, @LastMonthClosed)) - 1 
						END
					ELSE
						BEGIN
							SET @BeginDeprMonth = DATEADD(m, 1, @LastMonthTaken)
							SET @NumMonths = @NumMonths - (DateDiff(m, @FirstSchedMonth, @LastMonthTaken)) - 1
						END

					-- Issue: #132476 --
					-- START RECALC AT BEGINNING MONTH OF FYEM --
					IF @FYBeginMonth > @BeginDeprMonth
						BEGIN
							SET @BeginDeprMonth = @FYBeginMonth 
							SET @NumMonths = @NumMonths - (DateDiff(m, @FirstSchedMonth, @FYBeginMonth))
						END
				END

			----------------------------------------------
			-- DELETE ALL RECORDS FROM CALCULATED MONTH --
			----------------------------------------------
			IF @Method = 'S' OR (@NumMonths >= @MinMonths)
				BEGIN
					DELETE FROM EMDS 
						WHERE EMCo = @EMCo and Equipment = @Equipment and Asset = @Asset and Month >= @BeginDeprMonth
				END

			--------------------------------------
			-- CALC AMOUNT OF DEPRECIATION LEFT --
			--------------------------------------
			SET @AmtToDepr = @AmtToDepr - @DeprAmtTaken

			-----------------------------------------------------
			-- RESET BEGIN MONTH TO START/RESTART DEPRECIATION --
			-----------------------------------------------------
			IF @DeprAmtTaken = 0
				BEGIN
					SET @BeginDeprMonth = @StartDate
				END

		END --	IF @ReCalculate = 'Y'

		------------------------------
		-- CALL DEPRECIATION METHOD --
		-------------------------------------------------------
		-- MUST HAVE A MINIMUM NUMBER OF MONTHS TO CALCULATE --
		-------------------------------------------------------
		-- Issue: #131752
		IF (@NumMonths >= @MinMonths)
			BEGIN
	
				-------------------
				-- STRAIGHT LINE --
				-------------------
				IF @Method = 'S' 
						BEGIN

							EXECUTE @rcode = vspEMDepreciationSL @EMCo, @Equipment, @Asset, 
																 @AmtToDepr, @SalvageVal, 
																 @NumMonths, @BeginDeprMonth, 
																 @errmsg output
						END
				ELSE
					BEGIN
						-----------------------
						-- DECLINING BALANCE --
						-----------------------
						IF @Method = 'D' 
							BEGIN

								-----------------------------------------------------------------------------
								-- POSSIBLY RESET FYEM  - NECESSARY WHEN RECALCULATING FUTURE DEPRECAITION --
								-----------------------------------------------------------------------------
								SET @YearDiff = DATEDIFF(yy, @BeginDeprMonth, @FYEM)

								------------------------------------------------------
								-- CHECK DIFFERENCE BETWEEN NEW START DATE AND FYEM --
								------------------------------------------------------
								IF @YearDiff <= 0
									BEGIN
										SET @FYEM = DATEADD(yy, ABS(@YearDiff), @FYEM)
										SET @MonthDiff = DATEDIFF(m, @BeginDeprMonth, @FYEM)

										IF @MonthDiff < 0
											BEGIN
												SET @FYEM = DATEADD(yy, 1, @FYEM)
											END
									END
								ELSE
									BEGIN
										IF @MonthDiff < 0
											BEGIN
												SET @FYEM = DATEADD(yy, 1, @FYEM)
											END
									END

								-----------------------------------
								-- CALL DECLINING BALANCE METHOD --
								-----------------------------------
								EXECUTE @rcode = vspEMDepreciationDB @EMCo, @Equipment, @Asset,
																	 @AmtToDepr, @SalvageVal, 
																	 @NumMonths, @BeginDeprMonth, @FYEM, 
																	 @DeclineFactor, 
																	 @errmsg output
							END --IF @Method = 'D' 

					END --ELSE IF @Method = 'S'

			END --IF (@NumMonths >= @MinMonths)
		ELSE
			BEGIN
				SET @errmsg = @errmsg + CHAR(10) + 'Cannot calculate depreciation for less than ' + cast(@MinMonths AS VARCHAR(10)) + ' month(s)
								beginning with ' + convert(VARCHAR, @BeginDeprMonth, 1) +'.'
				SET @rcode = 1
			END

		-------------------------------------------------
		-- CHECK RETURN CODE FROM DEPRECIATION METHODS --
		-------------------------------------------------
		IF @rcode = 1
			BEGIN
				GOTO vspExit
			END


vspExit:
	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMDepreciationMain] TO [public]
GO
