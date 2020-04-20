SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspPRProcess]
/***********************************************************
* CREATED BY: 	GG  01/21/1998
* MODIFIED BY:  GG  02/25/1999
*               GG  11/08/1999 - Fix removal of bPRDT records
*               GG  01/29/2001 - removed PRSQ.InUse
*               GG  01/30/2001 - added call to bspPRProcessCraftAccums to update craft earnings
*				GG	07/09/2002 - #17284 - refresh AP info in bPRDT
*				GG	07/09/2002 - #10865 - added AP info to bPRCA
*				EN	10/09/2002 - #18877 - change double quotes to single
*				GG	03/07/2003 - #19909 - provide fall back default description for AP Desc 
*				GG	02/10/2004 - #23698 - added scroll_locks to bcEmployeeSeq cursor to prevent errors 
*										  when multiple users process same payroll simultaneously
*				EN	03/17/2004 - #20559 - include AP Update info in bPRDT earnings entries where PREC_AutoAP = 'Y'
*				EN	04/22/2004 - #20559 - additional change to allow earnings & liabs to be backed out of AP if check is voided
*				EN	09/24/2004 - #20562 - change from using bPRCO_LiabDist to bPREC_IncldLiabDist to determine whether an earnings code is included in liab distribs
*				GG	10/15/2004 - #25292 - replace dynamic SQL
*				GG	09/21/2005 - #28443 - don't remove bPRSQ if paid, even if all timecards have been deleted, must void first 
*				GG	10/18/2007 - #125457/#125881 - added 'select top 1' to queries for performance
*				EN	11/13/2007 - #125437 - include MidName and Suffix in APDesc for bPRCA and bPRDT
*				EN	03/26/2008 - #127015 - added code to call Canadian Federal tax routine
*				EN	06/18/2008 - #127270 - call same Fed/State process procedures as for USA
*				EN	03/30/2009 - #129888 - For Australian allowances update allowance subject hours to PRDT SubjectAmt
*				EN	07/21/2009 - #134431 - Additional code to PRDT update to update SubjectAmt for AUS allowance subject hours
*				MV	11/03/2010 - #140541 - Pre-tax deduction processing
*				CHS	10/07/2011 - D-03053 - tightened up the frequency code join
*				CHS 10/28/2011 - B-06309 - added PreTaxCatchUpYN
*				CHS	07/16/2012 - D-03348 - #144933 fixed Pretax state problem
*				CHS	07/26/2012 - D-05606 - fixed Pretax state problem with multiple employees.
*				CHS 08/16/2012 - B-10152 - TK-17277 adding Payback
*				CHS 08/16/2012 - B-10152 - TK-17277 adding Payback - added delete of bPRDT line when PaybackOverYN = 'N'
*			  KK/EN 08/28/2012 - B-10150 - Process employees with no timecards for Arrears
*				KK  08/29/2012 - B-10150 - Moved call to process arrears for employees with no timecards before processing to 
*										   preserve the integrety of the employee and/or pay sequence being passed in
*				KK  09/04/2012 - B-10817 - TK-17504 delete entries in Arrears history table when all timecards are deleted from that pay period
*				CHS 09/10/2012 - B-10152 - TK-17277 adding Payback - added setting payback to zero before processing
*				CHS 09/13/2012 - B-10152 - TK-17277 fixed Payback problem with multiple employees - 
*            DAN SO 10/01/2012 - B-10151 - TK-18099 Temp table to hold Arrears processed KeyIDs
*				CHS	10/03/2012 - D-05997 - TK-18315 Fix payback for EFTs.
*				CHS 10/09/2012 - D-05975 - TK-18128 Fixed looping problem
*				KK  12/10/2012 - D-11193 - TK-20133 Call vspPRProcessAllowances for AU allowances processing
*				KK  05/21/2013 - 47844/Task 47877 Prevent reprocessing/deleting other sequences when a sequence is specified
*				KK  05/23/2013 - 47844/Task 47877 Added "mode" parameter when calling process arrears no timecards to process changed
 *			 KK/EN  08/12/2013 - 54576 Added parameters PreTaxGroup and PreTaxCatchUpYN to bspPRProcessEmplDednLiabCalc
*
* USAGE:
* Primary procedure used to process PR earnings.  Executes other PR Process procedures
* as needed to calculate Addons, Deductions, and Liabilities
*
* INPUT PARAMETERS
*   @prco	PR Company
*   @prgroup	PR Group
*   @prenddate	PR Ending Date
*   @employee	Employee to process (null if processing all Employees)
*   @payseq	Payment Sequence # (null if processing all Seqs)
*   @mode	'A' = All, 'C' = Only those needing processing, 'S' = Select Employee
*
* OUTPUT PARAMETERS
*   @errmsg     if something went wrong
*
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/
(@prco bCompany, 
 @prgroup bGroup, 
 @prenddate bDate, 
 @employee bEmployee, 
 @payseq tinyint,
 @mode char(1), 
 @errmsg varchar(255) output)

AS
SET NOCOUNT ON    
    
DECLARE @status tinyint,		@tsql varchar(255),			  @rcode int,				@earncode bEDLCode, 
		@hrs bHrs,				@amt bDollar,				  @fedtax bDollar,			@fedbasis bDollar, 
		@ppds tinyint,			@limitmth bMonth,			  @stddays tinyint,			@bonus bYN,
		@posttoall bYN,			@openEmployeeSeq tinyint,	  @openEarning tinyint,		@openAddon tinyint, 
		@openDLVendor tinyint,	@edltype char(1),			  @edlcode bEDLCode,		@edlvendorgroup bGroup, 
		@edlvendor bVendor,		@edvendorgroup bGroup,		  @edvendor bVendor,		@apdesc bDesc, 
		@edldesc bDesc,			@autoAP bYN,				  @vendorgroup bGroup,		@vendor bVendor, 
		@transbyemployee bYN,	@eapdesc bDesc,				  @suffix varchar(4),		@PreTaxEmployee bEmployee, 
		@PreTaxPaySeq tinyint,	@PreTaxProcessingSeq tinyint, @PreTaxDLCode bEDLCode,	@PreTaxCalcCategory varchar(1),
		@YearEndMth tinyint,	@AccumBeginMth bMonth,		  @AccumEndMth bMonth,		@OpenPreTaxProcessing int, 
		@DummyOutput bDollar,	@OpenDedGroup int,			  @PreTaxGroup tinyint,		@AccumAmt bDollar, 
		@TotalAccumAmt bDollar, @OpenDLCodes int,			  @TotalAmount bDollar,		@DednGroupLimit bDollar, 
		@DiffAmt bDollar,		@Craft bCraft,				  @Class bClass,			@Template smallint,
		@EffectDate bDate,		@OldCapLimit bDollar,		  @NewCapLimit bDollar,		@RecipOpt char(1),
		@JobCraft bCraft,		@OpenCraftCalcPrep int,		  @OpenEmplCalcPrep int,	@RemainingDiffAmt bDollar, 
		@DednAmt bDollar,		@AmtToUpdate bDollar,		  @EligibleAmt bDollar,		@PreTaxCatchUpDLCode bEDLCode,	
		@ArrearsActiveYN bYN,	@NetPay bDollar,			  @PaybackRecalculate bYN,	@PreTaxCatchUpYN bYN

-- #127015 declare variables for Canada taxes
DECLARE @country char(2), 
		@A bDollar,	  
		@PP bDollar,		 
		@maxCPP bDollar, 
		@EI bDollar,	  
		@maxEI bDollar, 
		@capstock bDollar, 
		@HD bDollar
    
--#129888 Australian Allowances
DECLARE @routine varchar(10),	
		@rate bUnitCost,			
		@subjectamt bDollar

SELECT	@rcode = 0, 
		@OpenPreTaxProcessing = 0, 
		@OpenDedGroup = 0, 
		@OpenDLCodes = 0, 
		@OpenCraftCalcPrep = 0, 
		@OpenEmplCalcPrep = 0
    
    -- check for input parameters
    if @mode not in ('A','S','C')
    	begin
    	select @errmsg = 'Processing mode must be All, Changed, or Select Employee!', @rcode = 1
    	goto bspexit
    	end
    -- determine number of annual Pay Periods for this PR Group
    select @ppds =
    	case PayFreq
    		when 'W' then 52
    		when 'B' then 26
    		when 'S' then 24
    		when 'M' then 12
    		else 0
    	end
    	from dbo.bPRGR with (nolock) where PRCo = @prco and PRGroup = @prgroup
    if @ppds = 0
    	begin
    	select @errmsg = 'Unable to determine the number of annual Pay Periods for the PR Group!', @rcode = 1
    	goto bspexit
    	end
    
    -- get info from Pay Period Control
    select @limitmth = LimitMth, @stddays = Days, @status = Status
    from dbo.bPRPC with (nolock)
    where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
    if @@rowcount = 0
    	begin
    	select @errmsg = 'PR Group and Ending Date not setup in Pay Period Control!', @rcode = 1
    	goto bspexit
    	end
    
    -- check Pay Period status
    if @status <> 0
    	begin
    	select @errmsg = 'Pay Period status must be Open!', @rcode = 1
    	goto bspexit
    	end
    
    select @rcode = 0
 
	-- #127015 read country assigned in HQCO
	select @country = DefaultCountry from dbo.bHQCO with (nolock) where HQCo = @prco
	if @country is null select @country = 'US'
	
	/* Process employees with no timecards for Arrears */ -- B-10150
	EXEC @rcode = vspPRGetEmplNoTimecardsForArrears @prco, @prgroup, @employee, @prenddate, @payseq, @mode, @errmsg output

	----------------------------------------------------------------------------------------------------------
	/* PREPARE FOR PRE-TAX DEDUCTION PROCESSING - #140541 */
	-- create temp table for Craft and Employee based pretax deductions 
	CREATE TABLE #EmployeePreTaxDedns
		(
			PRCo int, PRGroup int, PREndDate smalldatetime,
			Employee int, PaySeq tinyint, ProcessingSeq tinyint,
			CalcCategory varchar (1), DLCode int, BasisAmt float, DednAmt float,
			PreTaxGroup tinyint, PreTaxCatchUpYN char(1), ArrearsPayback char(1)
		)
		
	CREATE TABLE #EmployeePreTaxPRPE
		(
			PostSeq smallint, PostDate smalldatetime, EarnCode int, PreTaxDLCode int
		)	
		
	CREATE TABLE #ArrearsDLCodesProcessed -- B-10151 - TK-18099 --
		(
			  DLCodeKeyID bigint
		)
			
	-- Get AccumBeginMth and AccumEndMth for employee pretax processing
	SELECT @YearEndMth = CASE h.DefaultCountry WHEN 'AU' THEN 6 ELSE 12 END
	FROM dbo.bHQCO h  
	WHERE h.HQCo = @prco

	EXEC vspPRGetMthsForAnnualCalcs @YearEndMth, @limitmth, @AccumBeginMth output, @AccumEndMth output, @errmsg output

----------------------------------------------------------------------------------------------------------
/************ EMPLOYEE-SEQUENCE: Master cursor to cycle through Employee Payment Sequences **************/
----------------------------------------------------------------------------------------------------------
-- #23698 - added scroll_locks to cursor
DECLARE bcEmployeeSeq cursor scroll_locks for
SELECT Employee, PaySeq
FROM dbo.bPRSQ 
WHERE PRCo = @prco 
  AND PRGroup = @prgroup 
  AND PREndDate = @prenddate
  AND Employee = ISNULL(@employee,Employee)
  AND PaySeq = ISNULL(@payseq,PaySeq)
  AND Processed = CASE @mode WHEN 'C' THEN 'N' ELSE Processed END 

OPEN bcEmployeeSeq
SELECT @openEmployeeSeq = 1

-- Begin loop through Employee Pay Sequence cursor
next_EmployeeSeq:
	FETCH NEXT FROM bcEmployeeSeq INTO @employee, @payseq
	IF @@fetch_status = -1 GOTO end_EmployeeSeq
	IF @@fetch_status <> 0 GOTO next_EmployeeSeq
    
    	-- check for unposted timecards
    	if exists(select * from dbo.bPRTB b with (nolock)
    		join dbo.bHQBC h with (nolock) on b.Co = h.Co and b.Mth = h.Mth and b.BatchId = h.BatchId
    		join dbo.bPRPC p with (nolock) on p.PRCo = h.Co and p.PRGroup = h.PRGroup and p.PREndDate = h.PREndDate
        	where p.PRCo = @prco and p.PRGroup = @prgroup and p.PREndDate = @prenddate
    			and b.Employee = @employee and b.PaySeq = @payseq)
    	goto next_EmployeeSeq
    
		----------------------------------------------------------------------------------------------------------
		/* Remove/Reset records */
    	-- reset flags in Employee Payment Sequence control
    	update dbo.bPRSQ
        	set Processed = 'N'
    	where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee and PaySeq = @payseq
    	if @@rowcount <> 1
    		begin
    		select @errmsg = 'Unable to update Employee Seq Control entry!', @rcode = 1
    		goto bspexit
    		end
    
    	-- remove Timecard Addons
        delete dbo.bPRTA
        where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee and PaySeq = @payseq
    
    	-- remove Timecard Liabilities 
    	delete dbo.bPRTL
        	where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee and PaySeq = @payseq
    
    	-- remove Craft Rate Detail
    	delete dbo.bPRCX
        where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee and PaySeq = @payseq
        
    	-- remove Craft Accumulations not updated to AP
    	delete dbo.bPRCA
        where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee and PaySeq = @payseq
    		and OldAPAmt = 0.00
    		
    	-- reset remaining Craft Accumulations
    	update dbo.bPRCA
    	set Basis = 0.00, Amt = 0.00, EligibleAmt = 0.00, VendorGroup = null, Vendor = null --, APDesc = null
        where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee and PaySeq = @payseq
    	
    	-- remove Insurance Accumulations
    	delete dbo.bPRIA
        where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee and PaySeq = @payseq
    
    	-- remove Deposit Sequences
    	delete dbo.bPRDS
        where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee and PaySeq = @payseq
    
    	-- remove Pay Sequence Totals if no overrides or previous accumulations update
    	delete dbo.bPRDT
        where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee and PaySeq = @payseq
    		and OldHours = 0.00 and OldAmt = 0.00 and OldSubject = 0.00 and OldEligible = 0.00 and OldAPAmt = 0.00
			and UseOver = 'N' and PaybackOverYN = 'N'
			
    	-- reset calculated amounts in remaining Pay Sequence Totals
    	update dbo.bPRDT
        set Hours = 0, Amount = 0, SubjectAmt = 0, EligibleAmt = 0, OverProcess = 'N', VendorGroup = null, Vendor = null, PaybackAmt = 0
    	where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee and PaySeq = @payseq
    	    
    	-- If this employee has a record in any of the following tables go to ADDONS and DO NOT delete the record from PRSQ, 
    	--  if this record DOES NOT exist in any of these tables, delete the PRSQ record and go to the next Employee/Seq
    	if exists(select top 1 1 from dbo.bPRTH with (nolock) where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
    		and Employee = @employee and PaySeq = @payseq) 
    	BEGIN 
    	 -- 47844 reset arrears history table record ONLY when there is a timecard for processing or reprocessing for THIS record
			DELETE vPRArrears 
			WHERE PRCo = @prco AND PRGroup = @prgroup AND PREndDate = @prenddate AND Employee = @employee AND PaySeq = @payseq 
    		goto addons 
    	END
    	if exists(select top 1 1 from dbo.bPRDT with (nolock) where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
    		and Employee = @employee and PaySeq = @payseq) goto addons
    	if exists(select top 1 1 from dbo.bPRGL with (nolock) where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
    		and Employee = @employee and PaySeq = @payseq) goto addons
    	if exists(select top 1 1 from dbo.bPRJC with (nolock) where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
    		and Employee = @employee and PaySeq = @payseq) goto addons
    	if exists(select top 1 1 from dbo.bPREM with (nolock) where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
    		and Employee = @employee and PaySeq = @payseq) goto addons			
   		if exists(select top 1 1 from dbo.bPRSQ with (nolock) where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
   			and Employee = @employee and PaySeq = @payseq and CMRef is not null) goto addons --must first void check to remove CMRef (#28443)
   			
    	-- remove Employee Seq Control ONLY if nothing existed in the tables above for this Employee, then go to next employee
    	delete dbo.bPRSQ where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate 
    		and Employee = @employee and PaySeq = @payseq
   		goto next_EmployeeSeq
   		
    	/* End: Remove/Reset Records - If we did the delete, Goto next_EmployeeSeq, else Goto Addons */
    	----------------------------------------------------------------------------------------------------------
    	
    	/* Addons */
    	addons: 	-- process Craft/Class Addons
            -- get Posted to All flag from Employee Seq Control
    		select @posttoall = PostToAll
    	       	from dbo.bPRSQ with (nolock)
    	       	where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee and PaySeq = @payseq
            	if @@rowcount = 0
    	       		begin
    	       		select @errmsg = 'Missing Employee Seq Control entry!', @rcode = 1
    	       		goto bspexit
    	       		end
    
    		exec @rcode = bspPRProcessAddons @prco, @prgroup, @prenddate, @employee, @payseq, @stddays,
                			@posttoall, @errmsg output
    		if @rcode <> 0 goto bspexit
    
   		-- issue 20559 read employee name for APDesc / issue #125437 include MidName and Suffix if not null
   		select @eapdesc = isnull(FirstName,'') + ' ' + isnull(MidName,'') + ' ' + isnull(LastName,''), @suffix = Suffix
		from dbo.PREH with (nolock)
   		where PRCo = @prco and Employee = @employee

		if @suffix is not null select @eapdesc = @eapdesc + ', ' + @suffix
		
       	/* End: Addons */
       	----------------------------------------------------------------------------------------------------------
    	
    	/* Allowances */
		BEGIN TRY 
			EXEC vspPRProcessAllowances @PRCo = @prco
											, @PRGroup = @prgroup
											, @PREndDate = @prenddate
											, @Employee = @employee
											, @PaySeq = @payseq;
		END TRY
		BEGIN CATCH
			SET @errmsg = 'Error in vspPRProcessAllowances:' + ERROR_MESSAGE();
			RAISERROR(@errmsg,16,1);
		END CATCH
		/* End: Allowances */ --Allowance values have been stored in PRTA (TK-20133)
		
     	----------------------------------------------------------------------------------------------------------
    	/* Update Posted Earnings to Payment Sequence Totals */
    	declare bcEarning cursor for
    	select EarnCode, convert(numeric(10,2),sum(Hours)), convert(numeric(12,2),sum(Amt))
    	from dbo.bPRTH with (nolock)
    	where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee and PaySeq = @payseq
    	group by EarnCode
    
    	open bcEarning
    	select @openEarning = 1
    
    	-- loop through Posted Earnings cursor to update Payment Sequence Totals
    	next_Earning:
    		fetch next from bcEarning into @earncode, @hrs, @amt
    
    		if @@fetch_status = -1 goto end_Earning
    		if @@fetch_status <> 0 goto next_Earning
   
    		if @hrs <> 0.00 or @amt <> 0.00
    		BEGIN
   				--issue 20559 look up earnings AP Update info
   	 			select @apdesc = Description, @autoAP = AutoAP, @transbyemployee = TransByEmployee, 
   					@vendorgroup = VendorGroup, @vendor = Vendor
   				from dbo.bPREC with (nolock) 
   				where PRCo = @prco and EarnCode = @earncode
   		 		if @@rowcount = 0
   		 		BEGIN
   		 			select @errmsg = 'Earnings code:' + convert(varchar(4),@earncode) + ' not setup!', @rcode = 1
   		 			goto bspexit
   		 		END
   		 		
   				if @autoAP = 'Y'
   				BEGIN
   					if @transbyemployee = 'Y' select @apdesc = @eapdesc
   				END
   
    			update dbo.bPRDT
                set Hours = Hours + @hrs, Amount = Amount + @amt, 
   					VendorGroup = @vendorgroup, Vendor = @vendor, APDesc = @apdesc
    			where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
                      and PaySeq = @payseq and EDLType = 'E' and EDLCode = @earncode
                    
    			if @@rowcount = 0
    			BEGIN
    				insert dbo.bPRDT (PRCo, PRGroup, PREndDate, Employee, PaySeq, EDLType, EDLCode, Hours, Amount, SubjectAmt, EligibleAmt,
    					UseOver, OverAmt, OverProcess, VendorGroup, Vendor, APDesc, OldHours, OldAmt, OldSubject, OldEligible, OldMth,
                        OldVendor, OldAPMth, OldAPAmt)
    				values (@prco, @prgroup, @prenddate, @employee, @payseq, 'E', @earncode, @hrs, @amt, 0, 0, 'N', 0, 'N', 
   						@vendorgroup, @vendor, @apdesc, 0, 0, 0, 0, null, null, null, 0)
   				END
			END
			goto next_Earning
    
    	end_Earning:
    		close bcEarning
    		deallocate bcEarning
    		select @openEarning = 0
    	/* End: Update Posted Earnings to Payment Sequence Totals */
     	----------------------------------------------------------------------------------------------------------
     	
     	/* Update Addon Earnings and Allowance Earnings to Payment Sequence Totals */
    	declare bcAddon cursor for
    	select EarnCode, convert(numeric(12,2),sum(Amt)),
			Rate --#129888 also get sum of Rate to compute subject hours for Australian allowances
    	from dbo.bPRTA with (nolock)
    	where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee and PaySeq = @payseq
    	group by EarnCode, Rate
    
    	open bcAddon
    	select @openAddon = 1
    
    	-- loop through Addon Earnings cursor to update Payment Sequence Totals
    	next_Addon:
    		fetch next from bcAddon into @earncode, @amt, @rate
    
    		if @@fetch_status = -1 goto end_Addon
    		if @@fetch_status <> 0 goto next_Addon
    
    		if @amt <> 0.00
    			begin
   				--issue 20559 look up earnings AP Update info
				--#129888 also look up Routine ... need to update subject hours to SubjectAmt when Routine='RPSH'
   	 			select @apdesc = Description, @autoAP = AutoAP, @transbyemployee = TransByEmployee, 
   					@vendorgroup = VendorGroup, @vendor = Vendor, @routine = Routine
   				from dbo.bPREC with (nolock)
   				where PRCo = @prco and EarnCode = @earncode
   		 		if @@rowcount = 0
   		 			begin
   		 			select @errmsg = 'Earnings code:' + convert(varchar(4),@earncode) + ' not setup!', @rcode = 1
   		 			goto bspexit
   		 			end
   				if @autoAP = 'Y'
   					begin
   					if @transbyemployee = 'Y' select @apdesc = @eapdesc
   					end
   
				--#129888 for Australian allowances store units as SubjectAmt
				select @subjectamt = 0
				if @routine = 'Allowance' or @routine = 'AllowRDO' select @subjectamt = @amt / @rate

    			update dbo.bPRDT
                		set Amount = Amount + @amt, SubjectAmt = SubjectAmt + @subjectamt, VendorGroup = @vendorgroup, Vendor = @vendor, APDesc = @apdesc
    			where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee and PaySeq = @payseq
    				and EDLType = 'E' and EDLCode = @earncode
    			if @@rowcount = 0
    			insert dbo.bPRDT (PRCo, PRGroup, PREndDate, Employee, PaySeq, EDLType, EDLCode, Hours, Amount, SubjectAmt, EligibleAmt,
    				UseOver, OverAmt, OverProcess, VendorGroup, Vendor, APDesc, OldHours, OldAmt, OldSubject, OldEligible, OldMth,
                    OldVendor, OldAPMth, OldAPAmt)
    			values (@prco, @prgroup, @prenddate, @employee, @payseq, 'E', @earncode, 0, @amt, @subjectamt, 0, 'N', 0, 'N', 
   					@vendorgroup, @vendor, @apdesc, 0, 0, 0, 0, null, null, null, 0)
    			end
    		goto next_Addon
    
    	end_Addon:
    		close bcAddon
    		deallocate bcAddon
    		select @openAddon = 0
     	/* End: Addons/Update Addon Earnings to Payment Sequence Totals */
     	----------------------------------------------------------------------------------------------------------
     	
     	/* prepare for deduction and liability calculations */
    	-- see if this Payment Sequence is a Bonus Sequence
    	select @bonus = Bonus
        from dbo.bPRPS with (nolock)
        where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and PaySeq = @payseq
    	if @@rowcount = 0
    	   	begin
    	   	select @errmsg = 'Missing PR Sequence entry for this Pay Period!', @rcode = 1
    	   	goto bspexit
    	   	end

	----------------------------------------------------------------------------------------------------------
	/* BEGIN PRE-TAX DEDUCTION PROCESSING - #140541 */
			-- Clear Pre Tax temp table 
			DELETE FROM #EmployeePreTaxDedns
			DELETE FROM #EmployeePreTaxPRPE			
			-- B-10151 - TK-18099 --
			DELETE FROM #ArrearsDLCodesProcessed
			
			-- Load temp table with Craft based pretax deductions for current employee and pay seq
			INSERT INTO #EmployeePreTaxDedns
				(
					PRCo,PRGroup,PREndDate,
					Employee, PaySeq, ProcessingSeq,
					CalcCategory, DLCode, BasisAmt, DednAmt,
					PreTaxGroup, PreTaxCatchUpYN -- CHS 10/28/2011	- B-0630
				)			
			SELECT DISTINCT 
					t.PRCo, t.PRGroup,t.PREndDate,
					t.Employee,t.PaySeq,NULL, 
					'C',d.DLCode,0,0,d.PreTaxGroup, 'N'
			FROM dbo.bPRCI c
			JOIN dbo.bPRTH t ON c.PRCo=t.PRCo AND c.Craft=t.Craft 
			JOIN dbo.bPRDL d ON d.PRCo=c.PRCo AND d.DLCode=c.EDLCode
			WHERE t.PRCo=@prco AND t.PRGroup=@prgroup AND t.PREndDate=@prenddate AND 
				t.Employee=@employee AND t.PaySeq=@payseq AND
				d.DLType='D' AND d.PreTax='Y'			
				
			-- Load temp table with Employee based pretax deductions for current employee and pay seq
			INSERT INTO #EmployeePreTaxDedns
				(
					PRCo, PRGroup, PREndDate,
					Employee, PaySeq, ProcessingSeq,
					CalcCategory, DLCode, BasisAmt, DednAmt,
					PreTaxGroup, PreTaxCatchUpYN -- CHS 10/28/2011	- B-0630
				)			
			SELECT DISTINCT 
					t.PRCo, t.PRGroup,t.PREndDate,
					t.Employee,t.PaySeq, d.ProcessSeq,
					'E', l.DLCode,0,0,l.PreTaxGroup, l.PreTaxCatchUpYN -- CHS 10/28/2011	- B-0630
			FROM dbo.bPRTH t
			JOIN dbo.bPRED d ON d.PRCo=t.PRCo AND d.Employee=t.Employee 
			--CHS	10/07/2011	- D-03053 tightened up the frequency code join
			JOIN dbo.bPRAF f ON f.PRCo=d.PRCo AND f.Frequency=d.Frequency and t.PREndDate = f.PREndDate and  f.PRGroup = t.PRGroup
			JOIN dbo.bPRDL l ON l.PRCo=d.PRCo AND l.DLCode=d.DLCode
			WHERE t.PRCo=@prco AND t.PRGroup=@prgroup AND t.PREndDate=@prenddate AND 
				t.Employee=@employee AND t.PaySeq=@payseq AND
				l.DLType='D' AND l.PreTax='Y' AND d.EmplBased = 'Y'							

			-- Create a cursor and loop through each pre tax deduction
			DECLARE bcPreTaxProcessing CURSOR FOR
    		SELECT Employee, PaySeq, ProcessingSeq, CalcCategory, DLCode, PreTaxGroup, PreTaxCatchUpYN 
			FROM #EmployeePreTaxDedns
			ORDER BY ProcessingSeq, DLCode
	    
    		OPEN bcPreTaxProcessing
    		SELECT @OpenPreTaxProcessing = 1
    
    		-- loop through Pre Tax Processing cursor to update PRDT with pre tax ded amts
    	NEXT_PreTax:
    		FETCH NEXT FROM bcPreTaxProcessing into @PreTaxEmployee, @PreTaxPaySeq, @PreTaxProcessingSeq,
				@PreTaxCalcCategory, @PreTaxDLCode, @PreTaxGroup, @PreTaxCatchUpYN
	    
			IF @@fetch_status = -1 GOTO END_PreTax
			IF @@fetch_status <> 0 GOTO NEXT_PreTax

			-- Call CraftDednLiabCalc to calculate the amount of this craft pre tax deduction - bPRDT is updated
			IF @PreTaxCalcCategory = 'C'
			BEGIN
				-- Get all the craft/class/template records from PRTH for this employee and pre tax dedn code, cycle
				-- through each and get additional 'prep' information and fill bPRPE work table prior to doing the dedn calc
				DECLARE bcCraftCalcPrep CURSOR FOR
				SELECT DISTINCT h.Craft, h.Class, j.CraftTemplate
				FROM dbo.bPRTH h
				LEFT OUTER JOIN bJCJM j ON h.JCCo = j.JCCo AND h.Job = j.Job
				JOIN dbo.#EmployeePreTaxDedns e ON e.PRCo=h.PRCo AND e.PRGroup=h.PRGroup AND e.PREndDate=h.PREndDate
					AND e.Employee=h.Employee AND e.PaySeq=h.PaySeq 
				JOIN dbo.bPRCI c ON c.PRCo=h.PRCo AND c.Craft= h.Craft AND EDLType = 'D' AND c.EDLCode = @PreTaxDLCode 
				WHERE h.PRCo = @prco and h.PRGroup = @prgroup and h.PREndDate = @prenddate and h.Employee = @employee
     				AND h.PaySeq = @payseq AND h.Craft IS NOT NULL AND h.Class IS NOT NULL AND e.CalcCategory='C'
	
				OPEN bcCraftCalcPrep
				SELECT @OpenCraftCalcPrep=1

			NEXT_CraftCalcPrep:
				FETCH NEXT FROM bcCraftCalcPrep into @Craft,@Class,@Template
	    
				IF @@fetch_status = -1 GOTO END_CraftCalcPrep
				IF @@fetch_status <> 0 GOTO NEXT_CraftCalcPrep
			
				
				-- execute CraftCalcPrep to fill bPRPE and get additional required information for calculating craft pre-tax deduction amount			
				EXEC @rcode = dbo.bspPRProcessCraftCalcPrep @prco, @prgroup, @prenddate, @PreTaxEmployee, @PreTaxPaySeq,
					@PreTaxDLCode, @Craft, @Class, @Template, @EffectDate OUTPUT, @OldCapLimit OUTPUT,
					@NewCapLimit OUTPUT, @RecipOpt OUTPUT, @JobCraft OUTPUT, @errmsg OUTPUT
    			IF @rcode <> 0 GOTO bspexit
    			-- execute CraftDednLiabCalc to calculate the pre tax deduction amount - updates bPRDT
				EXEC @rcode = bspPRProcessCraftDednLiabCalc @prco, @PreTaxDLCode,@prgroup, @prenddate, @PreTaxEmployee,
					@PreTaxPaySeq, @ppds,@limitmth, @stddays, @bonus, @posttoall, @Craft,@Class, @Template, @EffectDate,
					@OldCapLimit,@NewCapLimit,@JobCraft,@RecipOpt,@errmsg output
    			IF @rcode <> 0 GOTO bspexit
    			
    			-- save PRPE info for rationing later in PRProcessGetBasis D-03348 
    			INSERT INTO #EmployeePreTaxPRPE
    						(PostSeq, PostDate, EarnCode, PreTaxDLCode)
				SELECT PostSeq, PostDate, EarnCode, @PreTaxDLCode
				FROM bPRPE
				WHERE VPUserName = SUSER_SNAME()
    			
    			-- Clear the work table bPRPE
    			DELETE dbo.bPRPE WHERE VPUserName = SUSER_SNAME()	
    			GOTO NEXT_CraftCalcPrep
    			
    		END_CraftCalcPrep:
    			IF @OpenCraftCalcPrep = 1
				BEGIN
					CLOSE bcCraftCalcPrep
    				DEALLOCATE bcCraftCalcPrep
    				SELECT @OpenCraftCalcPrep = 0
				END
			END -- end CalcCategory C - craft
			IF @PreTaxCalcCategory = 'E'
			BEGIN
				-- call EmplCalcPrep to fill bPRPE to prepare for calculating employee pre-tax deduction amounts
				EXEC @rcode = bspPRProcessEmplCalcPrep @prco, @prgroup, @prenddate, @PreTaxEmployee,
					@PreTaxPaySeq, @PreTaxDLCode
    			IF @rcode <> 0 GOTO bspexit	

				-- call EmplDednLiabCalc to calc employee pre-tax ded amount - bPRDT is updated. 
				EXEC @rcode = bspPRProcessEmplDednLiabCalc @prco, @PreTaxDLCode,@prgroup, @prenddate, @PreTaxEmployee,
					@PreTaxPaySeq, @ppds,@limitmth, @stddays, @bonus, @posttoall, @AccumBeginMth ,
					@AccumEndMth, @PreTaxGroup, @PreTaxCatchUpYN, @DummyOutput OUTPUT, @errmsg output
    			IF @rcode <> 0 GOTO bspexit
    			-- Clear the work table bPRPE before getting the next employee dlcode.
    			
    			
    			-- save PRPE info for rationing later in PRProcessGetBasis D-03348 
    			INSERT INTO #EmployeePreTaxPRPE
    						(PostSeq, PostDate, EarnCode, PreTaxDLCode)
				SELECT PostSeq, PostDate, EarnCode, @PreTaxDLCode
				FROM bPRPE
				WHERE VPUserName = SUSER_SNAME()
				
    			
    			DELETE dbo.bPRPE WHERE VPUserName = SUSER_SNAME()
			END -- end CalcCategory E - employee
		
		GOTO NEXT_PreTax

		END_PreTax:
			IF @OpenPreTaxProcessing = 1
			BEGIN
				CLOSE bcPreTaxProcessing
    			DEALLOCATE bcPreTaxProcessing
    			SELECT @OpenPreTaxProcessing = 0
			END
			
		-- Apply limits from PR Deduction Groups	
		IF EXISTS (SELECT * 
					FROM #EmployeePreTaxDedns WHERE PreTaxGroup IS NOT NULL)
		BEGIN
			-- Spin through temp table Deduction Groups
			DECLARE bcDedGroup CURSOR FOR
    		SELECT DISTINCT PreTaxGroup				
			FROM #EmployeePreTaxDedns
			WHERE PreTaxGroup IS NOT NULL		
			ORDER BY PreTaxGroup
	    
    		OPEN bcDedGroup
    		SELECT @OpenDedGroup = 1
    
    		-- loop through Temp table deduction groups to get limits
    	NEXT_DednGroup:
    		FETCH NEXT FROM bcDedGroup into  @PreTaxGroup
	    
			IF @@fetch_status = -1 GOTO END_DednGroup
			IF @@fetch_status <> 0 GOTO NEXT_DednGroup
			
			-- Get the limit amount for this deduction group 
			SELECT @DednGroupLimit = AnnualLimit 
			FROM dbo.bPRDeductionGroup g
			WHERE g.PRCo=@prco AND g.DednGroup=@PreTaxGroup
			
			-- If Deduction Group Limit is 0 skip
			IF @DednGroupLimit = 0.00 GOTO NEXT_DednGroup 
			
			-- Initialize amount variables		
			SELECT @TotalAmount = 0, @TotalAccumAmt = 0,
				@DiffAmt = 0,@TotalAmount = 0
			 
				-- Now loop through all DLCodes in temp table for this deduction group
				DECLARE bcDLCodes CURSOR FOR
				SELECT DLCode
				FROM #EmployeePreTaxDedns
				WHERE PreTaxGroup=@PreTaxGroup and PreTaxCatchUpYN = 'N' -- CHS 10/28/2011	- B-0630
				ORDER BY DLCode
				
				OPEN bcDLCodes
				SELECT @OpenDLCodes = 1
				
			NEXT_DLCode:
				FETCH NEXT FROM bcDLCodes into @PreTaxDLCode
			
				IF @@fetch_status = -1 GOTO END_DLCodes
				IF @@fetch_status <> 0 GOTO NEXT_DLCode

				-- Get accum amounts for this Dedn Code - ded amts from PREA and PRDT.
				EXEC @rcode = bspPRProcessGetAccums @prco, @prgroup, @prenddate, @employee, @payseq,
    				@PreTaxDLCode, 'D', 'A', @limitmth, 'N', @AccumAmt output,@DummyOutput output, 
    				@DummyOutput output, @DummyOutput output, @DummyOutput output, @errmsg output
    			IF @rcode <> 0 GOTO bspexit
    			-- Add accum amount for this dedn code to total accum amount
    			SELECT @TotalAccumAmt = @TotalAccumAmt + @AccumAmt
    			-- get next deduction code in this deduction group
    			GOTO NEXT_DLCode

    		END_DLCodes:
    			IF @OpenDLCodes = 1
				BEGIN
					CLOSE bcDLCodes
    				DEALLOCATE bcDLCodes
    				SELECT @OpenDLCodes = 0
				END
			-- add the total amount from Accums to the total amount from deduction codes in this deduction group
			SELECT @TotalAmount = @TotalAccumAmt 
			-- If the total amount of (Accums + deduction amounts) is over the limit, get the difference
			IF @TotalAmount > @DednGroupLimit 
			BEGIN
				SELECT 	@DiffAmt = @TotalAmount - @DednGroupLimit
				
				-- Get Dedn Amount from first DLCode in Deduction Group to apply DiffAmt to.
				SELECT TOP 1 @DednAmt = Amount, @PreTaxDLCode = e.DLCode, @EligibleAmt = d.EligibleAmt
				FROM dbo.bPRDT d
				JOIN #EmployeePreTaxDedns e ON e.PRCo=d.PRCo AND e.PRGroup=d.PRGroup AND e.PREndDate=d.PREndDate AND
						e.Employee=d.Employee AND e.PaySeq=d.PaySeq AND e.DLCode=d.EDLCode
				WHERE d.PRCo=@prco AND d.PRGroup=@prgroup AND d.PREndDate=@prenddate AND d.Employee=@employee AND 
					d.PaySeq=@payseq AND d.EDLType = 'D' AND e.PreTaxGroup=@PreTaxGroup AND d.EDLCode=e.DLCode
					AND PreTaxCatchUpYN = 'N' -- CHS 10/28/2011	- B-0630
				-- Calculate what to reduce the dedn amount by, dedn amount cannot go negative, any remaining amount to
				-- be reduced must be applied to the next dlcode in the deduction group
				IF @DednAmt - @DiffAmt < 0 -- dedn amt is less than the diffence between 
				BEGIN
					SELECT @AmtToUpdate = 0 -- set Dedn Amt to 0
					SELECT @EligibleAmt = 0 -- set Eligible Amt to 0
					SELECT @RemainingDiffAmt = @DiffAmt - @DednAmt -- Get remaining amount to reduce next dlcode by
				END
				ELSE
				BEGIN
					SELECT @AmtToUpdate = (@DednAmt - @DiffAmt) -- Get amount to update bPRDT
					SELECT @RemainingDiffAmt = 0
					IF @AmtToUpdate = 0
						BEGIN
						SELECT @EligibleAmt = 0
						END					
				END
				    	   				
				-- Update PRDT reduce the dedn Amt on the first dlcode in the deduction group
				UPDATE dbo.bPRDT SET Amount = @AmtToUpdate, EligibleAmt = @EligibleAmt  
				FROM dbo.bPRDT d
				JOIN #EmployeePreTaxDedns e ON e.PRCo=d.PRCo AND e.PRGroup=d.PRGroup AND e.PREndDate=d.PREndDate AND
						e.Employee=d.Employee AND e.PaySeq=d.PaySeq AND e.DLCode=d.EDLCode
				WHERE d.PRCo=@prco AND d.PRGroup=@prgroup AND d.PREndDate=@prenddate AND d.Employee=@employee AND 
					d.PaySeq=@payseq AND d.EDLType = 'D' AND e.PreTaxGroup=@PreTaxGroup AND d.EDLCode=@PreTaxDLCode
					AND PreTaxCatchUpYN = 'N' -- CHS 10/28/2011	- B-0630
					
				-- If there is a remaining amount to be applied, update the next DLCode in the Deduction Group
				IF @RemainingDiffAmt > 0 
				BEGIN
					-- Get the next Dedn Code in the Dedution Group to apply the remaining amount to
					SELECT TOP 1 @DednAmt = Amount, @PreTaxDLCode = DLCode, @EligibleAmt = d.EligibleAmt
					FROM dbo.bPRDT d
					JOIN #EmployeePreTaxDedns e ON e.PRCo=d.PRCo AND e.PRGroup=d.PRGroup AND e.PREndDate=d.PREndDate AND
							e.Employee=d.Employee AND e.PaySeq=d.PaySeq AND e.DLCode=d.EDLCode
					WHERE d.PRCo=@prco AND d.PRGroup=@prgroup AND d.PREndDate=@prenddate AND d.Employee=@employee AND 
						d.PaySeq=@payseq AND d.EDLType = 'D' AND e.PreTaxGroup=@PreTaxGroup AND d.EDLCode > @PreTaxDLCode
						AND PreTaxCatchUpYN = 'N' -- CHS 10/28/2011	- B-0630
					ORDER BY d.EDLCode 
					
	
					-- if remaining amount is greater than the dedn amt reduce it to 0
					IF @@ROWCOUNT > 0
						BEGIN
						
						IF (@DednAmt - @RemainingDiffAmt) < 0
							BEGIN
								SELECT @AmtToUpdate = 0 	
								SELECT @EligibleAmt = 0 -- set Eligible Amt to 0						
							END
						ELSE
							BEGIN
								SELECT @AmtToUpdate = @DednAmt - @RemainingDiffAmt
								IF @AmtToUpdate = 0
									BEGIN
									SELECT @EligibleAmt = 0
									END								
							END
							
						-- update PRDT with the remaining amount 
						UPDATE dbo.bPRDT SET Amount = @AmtToUpdate, EligibleAmt = @EligibleAmt 
						FROM dbo.bPRDT d
						JOIN #EmployeePreTaxDedns e ON e.PRCo=d.PRCo AND e.PRGroup=d.PRGroup AND e.PREndDate=d.PREndDate AND
								e.Employee=d.Employee AND e.PaySeq=d.PaySeq AND e.DLCode=d.EDLCode
						WHERE d.PRCo=@prco AND d.PRGroup=@prgroup AND d.PREndDate=@prenddate AND d.Employee=@employee AND 
							d.PaySeq=@payseq AND d.EDLType = 'D' AND e.PreTaxGroup=@PreTaxGroup AND d.EDLCode = @PreTaxDLCode
						END
				END -- End Remaining Amt
			END -- End Apply Limit amounts within this Deduction Group
			
			ELSE -- CHS 10/28/2011	- B-0630
			BEGIN

					-- update PRDT with zero for the catchup DL Code
					UPDATE dbo.bPRDT SET Amount = 0, EligibleAmt = 0
					FROM dbo.bPRDT d
					JOIN #EmployeePreTaxDedns e ON e.PRCo=d.PRCo AND e.PRGroup=d.PRGroup AND e.PREndDate=d.PREndDate AND
							e.Employee=d.Employee AND e.PaySeq=d.PaySeq AND e.DLCode=d.EDLCode
					WHERE d.PRCo=@prco AND d.PRGroup=@prgroup AND d.PREndDate=@prenddate AND d.Employee=@employee AND 
						d.PaySeq=@payseq AND d.EDLType = 'D' AND e.PreTaxGroup=@PreTaxGroup AND PreTaxCatchUpYN = 'Y'
						
			END

			GOTO NEXT_DednGroup
		END_DednGroup:
			IF @OpenDedGroup = 1
			BEGIN
				CLOSE bcDedGroup
    			DEALLOCATE bcDedGroup
    			SELECT @OpenDedGroup = 0
			END
		END --Apply limits from PR Deduction Groups	

		-- Update to #EmployeePreTaxDedns with the basis amt (SubjectAmt) and ded amt (Either Amount or OverAmt) from bPRDT.
		-- PRDT was updated with the deduction amounts in the cursor process above and the amount adjusted in bPRDT for limits if needed.  
		UPDATE #EmployeePreTaxDedns SET  
			BasisAmt = SubjectAmt,
			DednAmt = CASE d.UseOver WHEN 'Y' THEN d.OverAmt ELSE d.Amount END
		FROM dbo.bPRDT d
		JOIN #EmployeePreTaxDedns e ON e.PRCo=d.PRCo AND e.PRGroup=d.PRGroup AND e.PREndDate=d.PREndDate AND
				e.Employee=d.Employee AND e.PaySeq=d.PaySeq AND e.DLCode=d.EDLCode
		WHERE d.PRCo=@prco AND d.PRGroup=@prgroup AND d.PREndDate=@prenddate AND d.Employee=@employee AND 
			d.PaySeq=@payseq AND d.EDLType = 'D' 
			
	/* END PRE-TAX DEDUCTION PROCESSING */
	----------------------------------------------------------------------------------------------------------

	-- Redo calcs for Payback
	Payback_Recalculate:

	/* Calculate: Fed(US/CA/AU), State, Province, Local, Craft Accums, Craft(d/l), Insurance(d/l), Empl(d/l) */
	
		if @country in ('US','AU') --USA & Australia fed/state taxes
			begin
    		-- process Federal dedns and liabs
    		exec @rcode = bspPRProcessFed @prco, @prgroup, @prenddate, @employee, @payseq, @ppds, --issue 20562
            		@limitmth, @stddays, @bonus, @posttoall, @country, @fedtax output, @fedbasis output, @errmsg output
    		if @rcode <> 0 goto bspexit
    		
    		-- process Tax and Unemployment State dedns and liabs
			exec @rcode = bspPRProcessState @prco, @prgroup, @prenddate, @employee, @payseq, @ppds, --issue 20562
				@limitmth, @stddays, @bonus, @posttoall, @fedtax, @fedbasis, @errmsg output
    		if @rcode <> 0 goto bspexit
			end

		if @country = 'CA' --Canada fed/state taxes
			begin
    		-- process Federal dedns and liabs
    		exec @rcode = bspPRProcessFedCA @prco, @prgroup, @prenddate, @employee, @payseq, @ppds, --issue 20562
            		@limitmth, @stddays, @bonus, @posttoall, @fedtax output, @fedbasis output, @A output, 
					@PP output, @maxCPP output, @EI output, @maxEI output, @capstock output, @HD output, @errmsg output
    		if @rcode <> 0 goto bspexit

    		-- process Tax and Unemployment State dedns and liabs
			exec @rcode = bspPRProcessProvinceCA @prco, @prgroup, @prenddate, @employee, @payseq, @ppds, --issue 20562
				@limitmth, @stddays, @bonus, @posttoall, @A, @PP, @maxCPP, @EI, @maxEI, @capstock, @HD, @errmsg output
    		if @rcode <> 0 goto bspexit
			end

    	-- process Local dedns and liabs
        exec @rcode = bspPRProcessLocal @prco, @prgroup, @prenddate, @employee, @payseq, @ppds, --issue 20562
      		@limitmth, @stddays, @bonus, @posttoall, @fedtax, @fedbasis, @errmsg output
    	if @rcode <> 0 goto bspexit
    
        -- update posted and addon earnings to Craft report tables
        exec @rcode = bspPRProcessCraftAccums @prco, @prgroup, @prenddate, @employee, @payseq, @errmsg output
    	if @rcode <> 0 goto bspexit

        -- process Craft/Class dedns and liabs
        exec @rcode = bspPRProcessCraft @prco, @prgroup, @prenddate, @employee, @payseq, @ppds, --issue 20562
            @limitmth, @stddays, @bonus, @posttoall, @errmsg output
    	if @rcode <> 0 goto bspexit
        

        -- proccess Insurance dedns and liabs
        exec @rcode = bspPRProcessIns @prco, @prgroup, @prenddate, @employee, @payseq, @ppds, --issue 20562
            @limitmth, @stddays, @bonus, @posttoall, @errmsg output
    	if @rcode <> 0 goto bspexit


    	-- process Employee dedns and liabs
        exec @rcode = bspPRProcessEmpl @prco, @prgroup, @prenddate, @employee, @payseq, @ppds, --issue 20562
            @limitmth, @stddays, @bonus, @posttoall, @errmsg output
    	if @rcode <> 0 goto bspexit
        
	/* End: Calculate */
        
	----------------------------------------------------------------------------------------------
	/* Refresh AP info for manualy added PRDT entries -- cleared when processing begins (#17284)*/
    	declare bcDLVendor cursor for
    	select t.EDLType, t.EDLCode, l.VendorGroup, l.Vendor, l.Description
    	from dbo.bPRDT t with (nolock)
    	join dbo.bPRDL l with (nolock) on l.PRCo = t.PRCo and l.DLCode = t.EDLCode
    	where t.PRCo = @prco and t.PRGroup = @prgroup and t.PREndDate = @prenddate and t.Employee = @employee
    		and t.PaySeq = @payseq and t.EDLType in ('D','L') and t.UseOver = 'Y' and t.Vendor is null 
    		and l.AutoAP = 'Y'
   		union --issue 20559 include earnings
    	select 'E', t.EDLCode, c.VendorGroup, c.Vendor, c.Description
    	from dbo.bPRDT t with (nolock)
    	join dbo.bPREC c with (nolock) on c.PRCo = t.PRCo and c.EarnCode = t.EDLCode
    	where t.PRCo = @prco and t.PRGroup = @prgroup and t.PREndDate = @prenddate and t.Employee = @employee
    		and t.PaySeq = @payseq and t.EDLType = 'E' and t.UseOver = 'Y' and t.Vendor is null 
    		and c.AutoAP = 'Y'
    
    	open bcDLVendor
    	select @openDLVendor = 1
    
    	-- loop through Employee Pay Seq Detail to update auto AP info
    	next_DLVendor:
    		fetch next from bcDLVendor into @edltype, @edlcode, @edlvendorgroup, @edlvendor, @edldesc
    
    		if @@fetch_status = -1 goto end_DLVendor
    		if @@fetch_status <> 0 goto next_DLVendor
    
    		select @edvendorgroup = null, @edvendor = null, @apdesc = null
    
   		if @edltype <> 'E'
   			begin
   	 		-- check for Employee override 
   	 		select @edvendorgroup = VendorGroup, @edvendor = Vendor, @apdesc = APDesc
   	 		from dbo.bPRED with (nolock)
   	 		where PRCo = @prco and Employee = @employee and DLCode = @edlcode 
   			end
    	
    		-- update Employee Detail
    		update dbo.bPRDT
    		set VendorGroup = isnull(@edvendorgroup,@edlvendorgroup), Vendor = isnull(@edvendor,@edlvendor),
    			APDesc = isnull(@apdesc,@edldesc)	-- #19909 - use DL description if no Employee override
    		where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
    			and PaySeq = @payseq and EDLType = @edltype and EDLCode = @edlcode
    		if @@rowcount <> 1
    			begin
    			select @errmsg = 'Unable to update auto AP info in Employee Sequence Control!', @rcode = 1
    		   	goto bspexit
    		   	end
    		goto next_DLVendor
    
    	end_DLVendor:	-- finished with auto AP updates
    		close bcDLVendor
    		deallocate bcDLVendor
    		select @openDLVendor = 0
    	
    /* End: Refresh AP info for manualy added PRDT entries */

	----------------------------------------------------------------------------------------
	/* Arrears Payback processing - with timecards */
	EXEC @rcode = vspPRProcessArrearsPayback @prco, @prgroup, @prenddate, @employee, @payseq, 
											 @PaybackRecalculate, 
											 @PaybackRecalculate OUTPUT, @errmsg OUTPUT	
	IF @rcode <> 0 GOTO bspexit
	
	IF @PaybackRecalculate = 'Y' GOTO Payback_Recalculate -- @PaybackRecalculate = 'Y'					
	-- Otherwise, Reset flag for next employee --
	SELECT @PaybackRecalculate = 'N'--, @EFTRecalculate = 'N'
    -----------------------------------------------------------------------------------------	
    					  					
	-- unlock Employee Pay Sequence
	UPDATE dbo.bPRSQ
	SET Processed = 'Y'
	WHERE PRCo = @prco 
	  AND PRGroup = @prgroup 
	  AND PREndDate = @prenddate 
	  AND Employee = @employee 
	  AND PaySeq = @payseq
	IF @@rowcount <> 1
	BEGIN
		SELECT @errmsg = 'Unable to update Employee Sequence Control ''processed'' flag!', @rcode = 1
		GOTO bspexit
	END
    
GOTO next_EmployeeSeq

end_EmployeeSeq:
CLOSE bcEmployeeSeq
DEALLOCATE bcEmployeeSeq
SELECT @openEmployeeSeq = 0
----------------------------------------------------------------------------------------------------------
/************ End EMPLOYEE-SEQUENCE: Master cursor ******************************************************/
----------------------------------------------------------------------------------------------------------
    		
	--------------------------------------------------------------------------------------------
	/*	If we removed all entries from PRSQ therefore removing pay period,					  */
	/*	make sure to clear all entries from PRArrears as well(also updates LifeToDate in PRED)*/
	--------------------------------------------------------------------------------------------
	IF NOT EXISTS (SELECT * FROM dbo.bPRSQ 
				   WHERE PRCo = @prco
					 AND PRGroup = @prgroup
					 And PREndDate = @prenddate)
	BEGIN		
		DELETE FROM dbo.vPRArrears 
		WHERE PRCo = @prco
		  AND PRGroup = @prgroup
		  And PREndDate = @prenddate
	END
     
    bspexit:
    	if @openAddon = 1
    		begin
    		close bcAddon
    		deallocate bcAddon
    		end
    	if @openEarning = 1
    		begin
    		close bcEarning
    		deallocate bcEarning
    		end
    	if @openDLVendor = 1
    		begin
    		close bcDLVendor
    		deallocate bcDLVendor
    		end
    	if @openEmployeeSeq = 1
    		begin
    		close bcEmployeeSeq
    		deallocate bcEmployeeSeq
    		end
		IF @OpenPreTaxProcessing = 1
			BEGIN
				CLOSE bcPreTaxProcessing
    			DEALLOCATE bcPreTaxProcessing
    			SELECT @OpenPreTaxProcessing = 0
			END
		IF @OpenDedGroup = 1
			BEGIN
				CLOSE bcDedGroup
    			DEALLOCATE bcDedGroup
    			SELECT @OpenDedGroup = 0
			END
		IF @OpenDLCodes = 1
				BEGIN
					CLOSE bcDLCodes
    				DEALLOCATE bcDLCodes
    				SELECT @OpenDLCodes = 0
				END
		IF @OpenCraftCalcPrep = 1
				BEGIN
					CLOSE bcCraftCalcPrep
    				DEALLOCATE bcCraftCalcPrep
    				SELECT @OpenCraftCalcPrep = 0
				END

		IF (OBJECT_ID('tempdb..#EmployeePreTaxDedns') IS NOT NULL)
		DROP TABLE #EmployeePreTaxDedns;
    
    	return @rcode
GO
GRANT EXECUTE ON  [dbo].[bspPRProcess] TO [public]
GO
