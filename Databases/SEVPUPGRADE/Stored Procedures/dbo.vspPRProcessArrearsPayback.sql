
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspPRProcessArrearsPayback]
/***********************************************************
* CREATED BY:	CHS 08/16/2012 - B-10152 TK-17277 adding Payback
* MODIFIED BY:	CHS 08/16/2012 - B-10152 TK-17277 taking into account the override amount.
*				KK  09/13/2012 - B-10152 TK-17277 Removed Seq to account for reprocessing a payperiod in which an employee is reprocessed with a + net
*			 DAN SO 09/18/2012 - B-10152 TK-17277 - removed IF statement for LifeToDateBal - want to process paybacks no matter LifeToDateBal 
*													 - wrapped History table insert to only insert when @AmountToPayback <> 0
*													 - Cursor will only pick up Codes SubjectToArrearsPayback
*			 DAN SO 09/25/2012 - B-10152 TK-17277 - Life To Date Balances come from PRED NOT PRArrears
*			 DAN SO 09/28/2012 - B-10152 TK-17277 - Set deduction to zero when the deduction code does not have an associated Earnings code 
*														and there is an outstanding balance on that Deduction code
*													 - Removed the deletion of the Arrears History table - it is already being handle in PRPRocess
*			 DAN SO 09/28/2012 - B-10151 TK-18099 - Added code to process Arrears
*												     - Also moved cursor to support both Paybacks AND Arrears 
*				CHS	10/03/2012 - D-05997 TK-18315 Fix payback for EFTs.
*			 DAN SO 10/09/2012 - D-05975 TK-18128 Use PRDL.RateAmt1 WHEN PRED.RateAmt = 0
*				CHS 10/09/2012 - D-05975 TK-18128 Don't process arrears if net pay = 0
*				CHS 10/09/2012 - D-05975 TK-18128 RED.RateAmt = 0 - redo previously done to deduction when should have been payback
*				CHS 10/09/2012 - D-05975 TK-18128 fixed looping problem
*				CHS 10/15/2012 - D-06057 TK-18537 fixed Arrears EFT.
*				CHS 10/15/2012 - D-06057 TK-18537 fixed Payback Override Amount problem and made changes to EFT.
*				CHS 10/15/2012 - D-06057 TK-18537 fixed pretax that was broken by previous fix.
*			 DAN SO 12/20/2012 - D-06202 TK-20312 Explicitly close cursor
*				CHS	03/19/2013 - 44155 148256 fixed PRED.OverCalcs
*				EN  05/10/2013 - 49954/Task 49970 clear PRDL_OverProcess flag on liabilities when @PaybackRecalculate = 'Y' so that the liabs get recalculated correctly
*				KK  05/13/2013 - 47844/Task 47877 Changed the comparison when Netamt is 0 to only process payback when net amount is positive
*				KK  05/23/2013 - 47844/Task 47877 Removed clause in arrears processing to break when positive. This was preventing all DLCodes for Seq X to accrue arrears.
*
* USAGE:
*	called from PR PRocess to calculate Payback or to adjust Arrears.
*
* INPUT PARAMETERS
*   @PRCo		PR Company
*   @PRGroup	PR Group
*   @PREndDate	PR Ending Date
*   @Employee	Employee to process (null if processing all Employees)
*   @PaySequence	Payment Sequence # (null if processing all Seqs)
*
* OUTPUT PARAMETERS
*	@Recalculate	trigger recalculation of payroll
*   @errmsg     if something went wrong
*
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/
(@PRCo bCompany, 
 @PRGroup bGroup, 
 @PREndDate bDate, 
 @Employee bEmployee, 
 @PaySequence tinyint,
 @LoopBack char(1), 
 @PaybackRecalculate bYN OUTPUT,
 @errmsg varchar(255) OUTPUT)
    	 
    AS
    
    SET NOCOUNT ON
    
    DECLARE @MyMethod char(1), @DLCode bEDLCode, @PreTax bYN, @PaybackFactor bRate, 
			@PaybackAmount bDollar, @NetPay bDollar, @OpenDLCodes int, @DeductionAmount bDollar,
			--@AmountToPayback bDollar, 
			@PRDTKeyID BigInt, @rcode int, @LifeToDateBalance bDollar,
			@PaybackOverYN bYN, @PaybackOverAmt bDollar, @MaxSequence int,
			@UseOver bYN, @OverAmt bDollar, @LifeToDateArrears bDollar, @LifeToDatePayback bDollar,
			@SubjectAmt bDollar, @EligibleAmt bDollar, @TempKeyID bigint, @ArrearsPaybackFlag char(1),
			@EligibleForArrearsCalc char(1), @PayMethod char(1), @OpenDLCodesKeyID int, @OpenDLCodesPaybackOverAmt int
    
    SELECT @PaybackRecalculate = 'N', @rcode = 0    
    
    --------------------------------------------------------------------
    -- when we re-enter this code after having performed a pre-tax loop, 
    -- we don't want to calc payback or arrears again
    --------------------------------------------------------------------
    SELECT TOP 1 @ArrearsPaybackFlag = ArrearsPayback 
    FROM #EmployeePreTaxDedns
	WHERE PRCo = @PRCo 
			   AND PRGroup = @PRGroup
			   AND PREndDate = @PREndDate
			   AND Employee = @Employee
			   AND ArrearsPayback IS NOT NULL
  

	IF ISNULL(@ArrearsPaybackFlag, 'N') = 'A'
		BEGIN
		GOTO DLCodesSetZero
		END
			   
    IF ISNULL(@ArrearsPaybackFlag,'N') = 'P'
		BEGIN
		GOTO vspExit
		END
		
    IF ISNULL(@LoopBack,'N') = 'Y'
		BEGIN
		GOTO vspExit
		END		
    
	--------------------------------------------
	-- Calc NetPay -> (Earnings - Deductions) --
	--------------------------------------------
	SELECT @NetPay = ISNULL((SELECT Sum(Amount)
						FROM bPRDT
						WHERE PRCo = @PRCo 
							AND PRGroup = @PRGroup  
							AND PREndDate = @PREndDate
							AND Employee = @Employee 
							AND PaySeq = @PaySequence
							AND EDLType = 'E'
						GROUP BY PREndDate), 0) -
		
					ISNULL((SELECT Sum(Amount)
						FROM bPRDT
						WHERE PRCo = @PRCo 
							AND PRGroup = @PRGroup  
							AND PREndDate = @PREndDate
							AND Employee = @Employee 
							AND PaySeq = @PaySequence
							AND EDLType = 'D'
							AND UseOver = 'N'
						GROUP BY PREndDate), 0) -
		        
		        	ISNULL((SELECT Sum(OverAmt)
						FROM bPRDT
						WHERE PRCo = @PRCo 
							AND PRGroup = @PRGroup  
							AND PREndDate = @PREndDate
							AND Employee = @Employee 
							AND PaySeq = @PaySequence
							AND EDLType = 'D'
							AND UseOver = 'Y'
						GROUP BY PREndDate), 0) -
		        
		        	ISNULL((SELECT Sum(PaybackOverAmt)
						FROM bPRDT
						WHERE PRCo = @PRCo 
							AND PRGroup = @PRGroup  
							AND PREndDate = @PREndDate
							AND Employee = @Employee 
							AND PaySeq = @PaySequence
							AND EDLType = 'D'
							AND PaybackOverYN = 'Y'
						GROUP BY PREndDate), 0)
									
	-- we don't want to proceed with arrears processing if net pay is negative OR employee is not active for arrears
	IF @NetPay < 0 AND NOT EXISTS(SELECT TOP 1 1 FROM bPREH 
								  WHERE PRCo = @PRCo 
									AND Employee = @Employee 
									AND ArrearsActiveYN = 'Y')
	BEGIN
		RETURN 0
	END

	-- if we are in an arrears condition, 
	-- we need to look for any Payback Override 
	-- amounts and move them to the arrears history table

	------------------------------------------------------------
	-- SET UP CURSOR TO BE USED FOR PACKBACK OVERRIDE AMOUNTS
	------------------------------------------------------------
	-- bPRDL and bPRED both have to be marked eligible to be included in the cursor record set --
		DECLARE bcDLCodesPaybackOverAmt SCROLL CURSOR FOR
		SELECT 
			dl.PreTax, PaybackOverAmt, dl.DLCode 
			
		FROM bPRDL dl
			JOIN bPRED ed ON ed.PRCo = dl.PRCo AND ed.DLCode = dl.DLCode 
			JOIN bPRDT dt ON dt.PRCo = dl.PRCo AND dt.EDLCode = dl.DLCode AND dt.Employee = ed.Employee 
			JOIN bPRSQ sq ON sq.PRCo = sq.PRCo AND sq.PRGroup = dt.PRGroup AND sq.PREndDate = dt.PREndDate AND sq.Employee = ed.Employee AND sq.PaySeq = dt.PaySeq
		WHERE dl.PRCo = @PRCo 
			AND dl.DLType = 'D' 
			AND ed.Employee = @Employee
			AND ed.EmplBased = 'Y'
			AND dt.PRGroup = @PRGroup
			AND dt.EDLType = 'D'
			AND dt.PREndDate = @PREndDate
			AND dt.PaySeq = @PaySequence
			AND dl.SubjToArrearsPayback = 'Y'
			AND dt.PaybackOverYN = 'Y'
		ORDER BY ed.ProcessSeq, dl.DLCode ASC 
		
		OPEN bcDLCodesPaybackOverAmt
		SELECT @OpenDLCodesPaybackOverAmt = 1

		------------------------	
		-- START NEXT_ DLCode --
		------------------------
		NEXT_DLCodePaybackOverAmt:
		FETCH NEXT FROM bcDLCodesPaybackOverAmt into 
			@PreTax, @PaybackOverAmt, @DLCode
			
		IF @@fetch_status = -1 GOTO DecidePaybackArrears
		IF @@fetch_status <> 0 GOTO NEXT_DLCode		
		
			-- GET next Seq to be inserted into the vPRArrears table --			
			SELECT @MaxSequence = ISNULL(MAX(Seq + 1), 1)
			  FROM vPRArrears 
			 WHERE PRCo = @PRCo
			   AND Employee = @Employee 			
			   AND DLCode = @DLCode  		
			
			INSERT vPRArrears (PRCo, Employee, DLCode, Seq, Date, ArrearsAmt, 
								PaybackAmt, PRGroup, PREndDate, PaySeq, EDLType)
			VALUES	(@PRCo, @Employee, @DLCode, @MaxSequence, dbo.vfDateOnly(), 0, 
						@PaybackOverAmt, @PRGroup, @PREndDate, @PaySequence, 'D')		
		
			--------------------------------------------------
			-- need to look to see if this DLCcode is a pretax and if so, then
			-- preform pretax house keeping then force to recalculate
			--
			-- also, need to set the loop back flag so the payback will be calculated as part of the EFTs
			--------------------------------------------------				
			IF @PreTax = 'Y'
			BEGIN
					
				-- note the names of the variables are inacurate at this point and are confusing.
				-- set payback flag and update Dednamt
				UPDATE #EmployeePreTaxDedns 
				   SET DednAmt = DednAmt + @PaybackOverAmt,
					   ArrearsPayback = CASE WHEN @NetPay > 0 THEN 'P'
														      ELSE 'A'
										END
					   
				 WHERE PRCo = @PRCo 
				   AND PRGroup = @PRGroup
				   AND PREndDate = @PREndDate
				   AND Employee = @Employee
				   AND DLCode = @DLCode
				
				SELECT @PaybackRecalculate = 'Y'				
			END -- @PreTax = 'Y'	
				
				
			--------------------------------------------------				
			-- need to look to see if this DLCcode is a rate of another deduction and if so, then
			-- then force to recalculate
			--------------------------------------------------					
			IF EXISTS(SELECT TOP 1 1	FROM bPRED ed
											JOIN bPRDL dl on ed.PRCo = dl.PRCo AND ed.DLCode = dl.DLCode
										WHERE ed.PRCo = @PRCo 
											AND ed.Employee = @Employee
											AND ed.EmplBased = 'Y' 
											AND dl.Method = 'DN'
											AND dl.DednCode = @DLCode)

			BEGIN
				SELECT @PaybackRecalculate = 'Y'	
			END						
		
		-----------------------	
		-- GOTO NEXT_ DLCode --
		-----------------------
		GOTO NEXT_DLCodePaybackOverAmt		
		
		
		
DecidePaybackArrears:		

	-- we don't want to proceed with payback processing if there are no PRDL 
	-- codes in PRED for this employee which are subject to arrears
	IF NOT EXISTS(SELECT TOP 1 1
					FROM bPRDL l
					JOIN bPRED e ON e.PRCo = l.PRCo 
								AND e.DLCode = l.DLCode
					WHERE e.Employee = @Employee
					  AND l.SubjToArrearsPayback = 'Y')
	BEGIN
		-- D-06202 TK-20312 -- 
		-- If the cursor is open, explicitly close it --
		IF @OpenDLCodesPaybackOverAmt = 1
		BEGIN
			CLOSE bcDLCodesPaybackOverAmt
			DEALLOCATE bcDLCodesPaybackOverAmt
			SELECT @OpenDLCodesPaybackOverAmt = 0
		END		

		RETURN 0
	END										

	------------------------------------------------------------
	-- SET UP CURSOR TO BE USED FOR BOTH Paybacks AND Arrears --
	------------------------------------------------------------
	-- bPRDL and bPRED both have to be marked eligible to be included in the cursor record set --
	DECLARE bcDLCodes SCROLL CURSOR FOR
	SELECT 
		dl.DLCode, dl.PreTax, dt.KeyID as [PRDTKeyID], 
		
		CASE ed.OverCalcs 
			WHEN 'N' THEN dl.RateAmt1
			ELSE ed.RateAmt 
			END AS [DeductionAmount],	
		
		CASE ed.OverrideStdPaybackSettings
			WHEN 'N' 
			THEN dl.PaybackPerPayPeriod
			ELSE ed.PaybackPerPayPeriodOverride
			END AS [MyMethod],		 

		CASE ed.OverrideStdPaybackSettings 
			WHEN 'N' 
			THEN dl.PaybackFactor
			ELSE ed.PaybackFactorOverride			
			END AS [MyFactor],
		
		CASE ed.OverrideStdPaybackSettings 
			WHEN 'N' 
			THEN 
				CASE dl.PaybackPerPayPeriod
					WHEN 'F'
					THEN -- dl.RateAmt1 * dl.PaybackFactor
						CASE ed.OverCalcs 
						WHEN 'N' THEN dl.RateAmt1 * dl.PaybackFactor
						ELSE ed.RateAmt * dl.PaybackFactor
						END 
					ELSE dl.PaybackAmount
					END				
			ELSE 
				CASE ed.PaybackPerPayPeriodOverride
					WHEN 'F'
					THEN -- ed.RateAmt * ed.PaybackFactorOverride	
						CASE ed.OverCalcs 
						WHEN 'N' THEN dl.RateAmt1 * ed.PaybackFactorOverride
						ELSE ed.RateAmt * ed.PaybackFactorOverride
						END 					
					ELSE ed.PaybackAmountOverride
					END						
			END AS [MyPaybackAmount],

		PaybackOverYN, PaybackOverAmt, UseOver, OverAmt, 
		LifeToDateArrears, LifeToDatePayback, SubjectAmt, EligibleAmt,
		EligibleForArrearsCalc, PayMethod
		
	FROM bPRDL dl
		JOIN bPRED ed ON ed.PRCo = dl.PRCo AND ed.DLCode = dl.DLCode 
		JOIN bPRDT dt ON dt.PRCo = dl.PRCo AND dt.EDLCode = dl.DLCode AND dt.Employee = ed.Employee 
		JOIN bPRSQ sq ON sq.PRCo = sq.PRCo AND sq.PRGroup = dt.PRGroup AND sq.PREndDate = dt.PREndDate AND sq.Employee = ed.Employee AND sq.PaySeq = dt.PaySeq
	WHERE dl.PRCo = @PRCo 
		AND dl.DLType = 'D' 
		AND ed.Employee = @Employee
		AND ed.EmplBased = 'Y'
		AND dt.PRGroup = @PRGroup
		AND dt.EDLType = 'D'
		AND dt.PREndDate = @PREndDate
		AND dt.PaySeq = @PaySequence
		AND dl.SubjToArrearsPayback = 'Y'
		--AND dt.PaybackOverYN = 'N'
	ORDER BY ed.ProcessSeq, dl.DLCode ASC 
	
	OPEN bcDLCodes
	SELECT @OpenDLCodes = 1
		
	-----------------------------------------------------------------------------------------------------------------
	-- If NetPay > 0 - Begin looking into paybacks -- We only look at Payback if the employee has a positive net pay
	-----------------------------------------------------------------------------------------------------------------
	IF @NetPay > 0
	BEGIN
		------------------------	
		-- START NEXT_ DLCode --
		------------------------
		NEXT_DLCode:
		FETCH NEXT FROM bcDLCodes into 
			@DLCode, @PreTax, @PRDTKeyID, @DeductionAmount,
			@MyMethod, @PaybackFactor, @PaybackAmount,
			@PaybackOverYN, @PaybackOverAmt, @UseOver, @OverAmt, 
			@LifeToDateArrears, @LifeToDatePayback, @SubjectAmt, 
			@EligibleAmt, @EligibleForArrearsCalc, @PayMethod

		IF @@fetch_status = -1 GOTO vspExit
		IF @@fetch_status <> 0 GOTO NEXT_DLCode

		
		---------------------------------------------------------
		-- Calc LifeToDateBalance -> (ArrearsAmt - PaybackAmt) --
		---------------------------------------------------------
		SET @LifeToDateBalance = (@LifeToDateArrears - @LifeToDatePayback)
			
		-----------------------
		-- Determine Amounts --
		-----------------------		
		-- Deduction --
		IF @UseOver = 'Y'
			BEGIN
			SELECT @DeductionAmount = @OverAmt
			END
			
		---- Doing a payback on a DLCODE that does not have any earnings --
		---- set deduction amount to 0 - otherwise it would take a normal deduction when it should not --
		IF @SubjectAmt = 0 OR @EligibleAmt = 0
			BEGIN
			SET @DeductionAmount = 0
			GOTO NEXT_DLCode
			END
		
		-- if payback causes a negative netpay situation, then abort --
		IF @NetPay - @PaybackAmount < 0 
			BEGIN
			GOTO vspExit
			END
				
		-- this is for when payback is greater than arrears balance - we don't want to pay back more than is in arrears		
		-- Example: Owed: $25  Payback Amt: $50 -- new payback amount is now $25 --
		IF @LifeToDateBalance < @PaybackAmount	
			BEGIN
			SELECT @PaybackAmount = @LifeToDateBalance
			END
							
		--------------------------------------------------
		-- set the calculated payback value in bPRDT on the appropriate deduction code.
		--------------------------------------------------
		UPDATE bPRDT SET PaybackAmt = @PaybackAmount WHERE KeyID = @PRDTKeyID		
				
			
		----------------------------------------------------------------------------	
		-- don't make history table or pretax updates if there is a payback override
		----------------------------------------------------------------------------	
		IF @PaybackOverYN = 'N'
			BEGIN		

			---------------------------------------------
			-- HISTORY TABLE ENTRY - @PaybackAmount --
			---------------------------------------------	
			IF @PaybackAmount <> 0 OR @PaybackOverYN = 'Y'
				BEGIN
				-- GET next Seq to be inserted into the vPRArrears table --			
				SELECT @MaxSequence = ISNULL(MAX(Seq + 1), 1)
				  FROM vPRArrears 
				 WHERE PRCo = @PRCo
				   AND Employee = @Employee 			
				   AND DLCode = @DLCode  					
				
				INSERT vPRArrears (PRCo, Employee, DLCode, Seq, Date, ArrearsAmt, 
									PaybackAmt, PRGroup, PREndDate, PaySeq, EDLType)
				VALUES	(@PRCo, @Employee, @DLCode, @MaxSequence, dbo.vfDateOnly(), 0, 
							@PaybackAmount, @PRGroup, @PREndDate, @PaySequence, 'D')
				END
				
			--------------------------------------------------
			-- need to update @NetPay after it has been theoretically reduced by the payback
			--------------------------------------------------		
			SELECT @NetPay = @NetPay - @PaybackAmount
			
			--------------------------------------------------
			-- need to look to see if this DLCcode is a pretax and if so, then
			-- preform pretax house keeping then force to recalculate
			--
			-- also, need to set the loop back flag so the payback will calculated as part of the EFTs
			--------------------------------------------------				
			IF @PreTax = 'Y'
				BEGIN
					
				-- note the names of the variables are inacurate at this point and oare confusing.
				-- set payback flag and update Dednamt
				UPDATE #EmployeePreTaxDedns 
				   SET DednAmt = @DeductionAmount + @PaybackAmount,
					   ArrearsPayback = 'P'
				 WHERE PRCo = @PRCo 
				   AND PRGroup = @PRGroup
				   AND PREndDate = @PREndDate
				   AND Employee = @Employee
				   AND DLCode = @DLCode
				
				SELECT @PaybackRecalculate = 'Y'				
				END -- @PreTax = 'Y'			
				
			

			--------------------------------------------------				
			-- need to look to see if this DLCcode is a rate of another deduction and if so, then
			-- then force to recalculate
			--------------------------------------------------					
			IF EXISTS(SELECT TOP 1 1	FROM bPRED ed
											JOIN bPRDL dl on ed.PRCo = dl.PRCo AND ed.DLCode = dl.DLCode
										WHERE ed.PRCo = @PRCo 
											AND ed.Employee = @Employee
											AND ed.EmplBased = 'Y' 
											AND dl.Method = 'DN'
											AND dl.DednCode = @DLCode)

				BEGIN
				SELECT @PaybackRecalculate = 'Y'	
				END					
		
						
		END -- IF @PaybackOverYN = 'N'
		
		
		-----------------------	
		-- GOTO NEXT_ DLCode --
		-----------------------
		GOTO NEXT_DLCode
		
		-- remove Deposit Sequences
		DELETE dbo.bPRDS
		WHERE PRCo = @PRCo     			
			AND PRGroup = @PRGroup 
      		AND PREndDate = @PREndDate 
      		AND Employee = @Employee 
      		AND PaySeq = @PaySequence

		EXEC @rcode = bspPRProcessEmplEFT @PRCo, @PRGroup, @PREndDate, @Employee, @PaySequence, @errmsg OUTPUT	
		
	END 
		
	-- @NetPay >= 0.00
	ELSE
	BEGIN	

		------------------------
		-- ARREARS PROCESSING --
		------------------------					
			--------------------------------------------------
			-- BACKOUT DEDUCTIONS STARTING WITH LAST DLCODE --
			--------------------------------------------------
			FETCH LAST FROM bcDLCodes INTO 
				@DLCode, @PreTax, @PRDTKeyID, @DeductionAmount,
				@MyMethod, @PaybackFactor, @PaybackAmount,
				@PaybackOverYN, @PaybackOverAmt, @UseOver, @OverAmt, 
				@LifeToDateArrears, @LifeToDatePayback, @SubjectAmt, 
				@EligibleAmt, @EligibleForArrearsCalc, @PayMethod
							
			------------------------
			-- CYCLE THRU DLCODES --
			------------------------
			WHILE @@FETCH_STATUS = 0  
			BEGIN  
			
				IF(@EligibleForArrearsCalc = 'N')
					BEGIN
					GOTO FetchNextCode
					END
					
				IF(@UseOver = 'Y')
					BEGIN
					GOTO FetchNextCode
					END
					
		   				   			
		   		-- INSERT INTO TEMP TABLE --
		   		INSERT #ArrearsDLCodesProcessed (DLCodeKeyID) VALUES (@PRDTKeyID)
		   		
   				-- GET next sequence for HISTORY TABLE ENTRY --
				SELECT @MaxSequence = ISNULL(MAX(Seq + 1), 1)
				  FROM vPRArrears 
				 WHERE PRCo = @PRCo
				   AND Employee = @Employee 			
				   AND DLCode = @DLCode  
				   
				--------------------------------------------
				-- HISTORY TABLE ENTRY - @DeductionAmount --
				--------------------------------------------
				INSERT vPRArrears (PRCo, Employee, DLCode, Seq, Date, ArrearsAmt, 
									PaybackAmt, PRGroup, PREndDate, PaySeq, EDLType)
				VALUES (@PRCo, @Employee, @DLCode, @MaxSequence, dbo.vfDateOnly(), @DeductionAmount, 
							0, @PRGroup, @PREndDate, @PaySequence, 'D')
		   				  
				-- CHECK IF IT IS A PreTax DEDUCTION
				IF @PreTax = 'Y'
					BEGIN
						UPDATE #EmployeePreTaxDedns 
						   SET DednAmt = @PaybackOverAmt, ArrearsPayback = 'A'
						 WHERE PRCo = @PRCo 
						   AND PRGroup = @PRGroup
						   AND PREndDate = @PREndDate
						   AND Employee = @Employee
						   AND DLCode = @DLCode
													   
						SET @PaybackRecalculate = 'Y'
					END							
		   				   			
		   		-- TRACK UPDATED NetPay --
				SET @NetPay = @NetPay + @DeductionAmount

--KK Not sure if we need this. It is causing records to be skipped for arrears processing when seq 1 timecards = 0.00			
				---- IF @NetPay IS POSITIVE - then we are done processing --
				--If @NetPay > 0 
				--	BEGIN
				--		-- DONE PROCESSING --
				--		BREAK
				--	END
					
				---------------------------
				-- FETCH PREVIOUS RECORD --
				---------------------------
				FetchNextCode:
					FETCH PRIOR FROM bcDLCodes INTO 
						@DLCode, @PreTax, @PRDTKeyID, @DeductionAmount,
						@MyMethod, @PaybackFactor, @PaybackAmount,
						@PaybackOverYN, @PaybackOverAmt, @UseOver, @OverAmt, 
						@LifeToDateArrears, @LifeToDatePayback, @SubjectAmt, 
						@EligibleAmt, @EligibleForArrearsCalc, @PayMethod					
					
			END -- WHILE @@FETCH_STATUS = 0 
		
			IF @PaybackRecalculate = 'Y'
			BEGIN
				GOTO vspExit
			END
		
	END -- IF @NetPay > 0 ELSE    		
    		
    	
---------------------------
-- SET PROCESSED ARREARS --
---------------------------
DLCodesSetZero:
		DECLARE bcDLCodesKeyID CURSOR FOR
		SELECT DLCodeKeyID
		FROM #ArrearsDLCodesProcessed
			
		OPEN bcDLCodesKeyID
		SELECT @OpenDLCodesKeyID = 1
				
		FETCH NEXT FROM bcDLCodesKeyID INTO @TempKeyID
		
		-- cycle thru PRProcess temp table DLCodes --
		WHILE @@FETCH_STATUS = 0  
		BEGIN 
		
			UPDATE bPRDT SET Amount = 0 WHERE KeyID = @TempKeyID

			-- FETCH NEXT RECORD --
			FETCH NEXT FROM bcDLCodesKeyID INTO @TempKeyID
		END
		
	    SELECT @PaybackRecalculate = 'N'
		    
-----------------
-- End Routine --
-----------------
vspExit:	
----------------------------------------------------
-- Update any EFTs 
----------------------------------------------------
		DELETE dbo.bPRDS
		WHERE PRCo = @PRCo     			
			AND PRGroup = @PRGroup 
      		AND PREndDate = @PREndDate 
      		AND Employee = @Employee 
      		AND PaySeq = @PaySequence

	EXEC @rcode = bspPRProcessEmplEFT @PRCo, @PRGroup, @PREndDate, @Employee, @PaySequence, @errmsg OUTPUT	
	
	IF @OpenDLCodes = 1
	BEGIN
			CLOSE bcDLCodes
			DEALLOCATE bcDLCodes
			SELECT @OpenDLCodes = 0
	END		
			
	IF @OpenDLCodesKeyID = 1
	BEGIN
			CLOSE bcDLCodesKeyID
			DEALLOCATE bcDLCodesKeyID
			SELECT @OpenDLCodesKeyID = 0
	END		
						
	IF @OpenDLCodesPaybackOverAmt = 1
	BEGIN
			CLOSE bcDLCodesPaybackOverAmt
			DEALLOCATE bcDLCodesPaybackOverAmt
			SELECT @OpenDLCodesPaybackOverAmt = 0
	END		

	IF @PaybackRecalculate = 'Y'
	BEGIN
			--------------------------------------------------------------------------
			-- Reset Amounts to zero prior to ReCalc so that values are not doubled --
			--------------------------------------------------------------------------
			UPDATE bPRDT 
			   SET SubjectAmt = 0, EligibleAmt = 0, Amount = 0, OverProcess = 'N'
			 WHERE PRCo = @PRCo 
			   AND PRGroup = @PRGroup 
			   AND PREndDate = @PREndDate 
			   AND Employee = @Employee 
			   AND PaySeq = @PaySequence
			   AND EDLType <> 'E'
			   AND (EDLType = 'L' OR EDLCode NOT IN (SELECT DLCode FROM #EmployeePreTaxDedns))
    
			-- remove Timecard Liabilities
			DELETE dbo.bPRTL
    		WHERE PRCo = @PRCo 
    			AND PRGroup = @PRGroup 
    			AND PREndDate = @PREndDate 
    			AND Employee = @Employee 
    			AND PaySeq = @PaySequence
	    
			-- remove Craft Rate Detail
			DELETE dbo.bPRCX
			WHERE PRCo = @PRCo 
    			AND PRGroup = @PRGroup 
    			AND PREndDate = @PREndDate 
    			AND Employee = @Employee 
    			AND PaySeq = @PaySequence
	        
			-- remove Craft Accumulations not updated to AP
			DELETE dbo.bPRCA
			WHERE PRCo = @PRCo 
    			AND PRGroup = @PRGroup 
    			AND PREndDate = @PREndDate 
    			AND Employee = @Employee 
    			AND PaySeq = @PaySequence
				AND OldAPAmt = 0.00
				
			-- reset remaining Craft Accumulations
			UPDATE dbo.bPRCA
			SET Basis = 0.00, Amt = 0.00, EligibleAmt = 0.00, VendorGroup = null, Vendor = null
			WHERE PRCo = @PRCo 
    			AND PRGroup = @PRGroup 
    			AND PREndDate = @PREndDate 
    			AND Employee = @Employee 
    			AND PaySeq = @PaySequence
	    	
			-- remove Insurance Accumulations
			DELETE dbo.bPRIA
			WHERE PRCo = @PRCo     			
				AND PRGroup = @PRGroup 
    			AND PREndDate = @PREndDate 
    			AND Employee = @Employee 
    			AND PaySeq = @PaySequence
    			
			-- remove Deposit Sequences
			DELETE dbo.bPRDS
			WHERE PRCo = @PRCo     			
				AND PRGroup = @PRGroup 
    			AND PREndDate = @PREndDate 
    			AND Employee = @Employee 
    			AND PaySeq = @PaySequence
	END
			

				
RETURN @rcode			
GO

GRANT EXECUTE ON  [dbo].[vspPRProcessArrearsPayback] TO [public]
GO
