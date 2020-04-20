SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspPRCheckStubLoad]
/***********************************************************
* CREATED BY:  GG 09/12/01
* MODIFIED BY: bc 01/10/02 issue # 15853
*				EN 8/25/03  issue 22251 - do not include hrs/rate on earnings codes set up with method 'A'
*				EN 12/04/03 - issue 23061  added isnull check, with (nolock), and dbo
*				GG 5/13/04 - #23237 fix YTD accumulation
*				GG 8/9/04 - #25504 - corrected YTD amount - removed changes for #23237, modified changes for #15826
*				EN 10/22/04 - 25785  changed to declare @uprate as bUnitCost (was bRate) to resolve Arithmetic Overflow error when rate is over 2 digits to the left of the decimal point
*				EN 1/18/05 - 26698  rather than use LimitMth to determine year for split month spanning 2 years, 
*									changed to use BeginMth if MultiMth='N' or EndMth if MultiMth='Y'
*				EN 2/9/05 - 22569  exclude SSN from PRSP insert if PRCO_ExcludeSSN flag = 'Y'
*				GG 4/16/07 - #119932 bPRSX duplicate index error
*				EN 4/03/2009 #129888  for Australian allowances include hours with allowances
*				mh 02/19/2010 #137971 - modified to allow date compares to use other then calendar year.
*				MV 08/20/2012 TK-16945/TK-17298 insert new bPRSX ded rec for PaybackAmt/accum PaybackAmt from bPRDL in YTD
*				MV 09/20/2012 D-05949/TK18004 - create bPRSX for payback when PaybackOverrideYN flag = Y
*				MV 10/25/2012 TK-18862 - Initialize @PaybackOverrideYN flag to 'N'
*				MV 12/17/2012 TK-20207 AUS crib and meal addon earnings
*				EN 1/17/2013 D-06530/#142769/TK-20813 replaced code to locate YTD leave usage amount with call to 
*							 stored proc vspPRGetLeaveAccumsForPayStubs ... this resolves issue and normalizes code
*							 that was repeated in 3 places
*
* USAGE:
* Called by the PR Check Replacement program to load stub detail tables (bPRSP, bPRSX)
* in preparation for printing a computer check.
*
* INPUT PARAMETERS
*   @prco		    PR Co#
*   @prgroup		PR Group being paid
*   @prenddate		Pay Period ending date
*   @employee		Employee number
*   @payseq		Payment Seq#
*
* OUTPUT PARAMETERS
*   @msg      		error message if error occurs
*
* RETURN VALUE
*   0   success
*   1   fail
*******************************************************************/
(@prco bCompany = null, @prgroup bGroup = null, @prenddate bDate = null, @employee bEmployee = null,
 @payseq tinyint = null, @msg varchar(255) output)

as

set nocount on

	declare @rcode tinyint, @cmref bCMRef, @paiddate bDate, @paidmth bMonth, @ttlhrs bHrs,
	@ttlearned bDollar,	@ttldedns bDollar, @filestatus char(1), @exempts tinyint, @fedcode bEDLCode,
	@openEDL tinyint, @edltype char(1), @edlcode bEDLCode, @code varchar(10), @description bDesc,
	@rate bUnitCost, @amt bDollar, @hrs bHrs, @openTimecard tinyint, @openAddon tinyint,
	@a1 bDollar, @a2 bDollar, @a3 bDollar, @a4 bDollar,
	@PaybackAmt bDollar, @PaybackOverrideYN bYN,
	@method char(1), --issue 22251
	@DefaultCountry CHAR(2)

	--#129888 Australian allowances
	declare @routine varchar(10)

	declare @uprate bUnitCost, @uphrs bHrs

	--137971
	declare @yearendmth tinyint, @accumbeginmth bMonth, @accumendmth bMonth

	select @rcode = 0, @DefaultCountry = dbo.vfGetHQCODefaultCountry(@prco) --TK20207
     
	-- validate input parameters
	if @prco is null or @prgroup is null or @prenddate is null or @employee is null or @payseq is null
	begin
		select @msg = 'Must provide PR Co#, PR Group, PR Ending Date, Employee, and Pay Seq#.', @rcode = 1
		goto bspexit
	end

	-- get payment info from PR Employee Sequence Control
	select @cmref = CMRef, @paiddate = PaidDate, @paidmth = PaidMth
	from dbo.bPRSQ with (nolock)
	where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
	and Employee = @employee and PaySeq = @payseq
 
	if @@rowcount = 0
 	begin
 		select @msg = 'Missing PR Employee Sequence Control entry!', @rcode = 1
 		goto bspexit
 	end
 	
	if @cmref is null
 	begin
 		select @msg = 'CM Reference has not been assigned!', @rcode = 1
 		goto bspexit
 	end

	--137971
	select @yearendmth = case h.DefaultCountry when 'AU' then 6 else 12 end
	from bHQCO h with (nolock) 
	where h.HQCo = @prco

	exec vspPRGetMthsForAnnualCalcs @yearendmth, @paidmth, @accumbeginmth output, @accumendmth output, @msg output
	--end 137971
 
	 -- clear any existing stub info for this payment
	 delete dbo.bPRSX
	 where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
 		and Employee = @employee and PaySeq = @payseq

	 delete dbo.bPRSP
	 where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
 		and Employee = @employee and PaySeq = @payseq
     
	 -- initialize totals
	 select @ttlhrs = 0, @ttlearned = 0, @ttldedns = 0, @filestatus = null, @exempts = null
 
	 -- get Federal Tax deduction - used for filing status and # of exemptions
	 select @fedcode = TaxDedn
	 from dbo.bPRFI with (nolock) where PRCo = @prco
 	
	 -- get Employee Federal filing status and exemptions
	 select @filestatus = FileStatus, @exempts = RegExempts
	 from dbo.bPRED with (nolock)
	 where PRCo = @prco and Employee = @employee and DLCode = @fedcode
 
	-- add check stub header
	-- 22569 exclude SSN if PRCO_ExcludeSSN flag = 'Y'
	insert dbo.bPRSP (PRCo, PRGroup, PREndDate, Employee, PaySeq, PayMethod, CMRef, PaidDate,
 		LastName, FirstName, MidName, Address, City, State, Zip, SSN, FileStatus, Exempts,
 		SortName, SortOrder)
	select @prco, @prgroup, @prenddate, @employee, @payseq, 'C', @cmref, @paiddate,
	   e.LastName, e.FirstName, e.MidName, e.Address, e.City, e.State, e.Zip, 
		(case when c.ExcludeSSN='N' then e.SSN else '' end), @filestatus, @exempts,
 		e.SortName, 'E'
	from dbo.bPREH e with (nolock)
	join dbo.bPRCO c with (nolock) on c.PRCo=e.PRCo
	where e.PRCo = @prco and e.Employee = @employee
	
	if @@rowcount <> 1
 	begin
 		select @msg = 'Unable to prepare check stub information.  Missing Employee header record.', @rcode = 1
 		goto bspexit
 	end
     
	-- find all earnings, deductions, and liabilities to include on stub
	 
	-- initialize a cursor on PR Detail Totals and Employee Accums for all E/D/Ls processed within the year
	/*137971
	declare bcEDL cursor for
	select distinct EDLType, EDLCode
	from dbo.bPRDT d with (nolock)
	join dbo.bPRSQ s with (nolock) on s.PRCo = d.PRCo and s.PRGroup = d.PRGroup and s.PREndDate = d.PREndDate
		and s.Employee = d.Employee
	where d.PRCo = @prco and d.PRGroup = @prgroup and d.Employee = @employee
		and ((d.PREndDate = @prenddate and d.PaySeq <= @payseq) -- #25504 - exclude codes in later pay seq#s
		or (datepart(year,s.PaidMth)=datepart(year,@paidmth))) -- #25505 - include all codes paid in this year
	union
	select distinct EDLType, EDLCode
	from dbo.bPREA with (nolock)
	where PRCo = @prco and Employee = @employee
 		and datepart(year,Mth) = datepart(year,@paidmth)
	order by EDLType, EDLCode
	*/
	
	declare bcEDL cursor for
	select distinct EDLType, EDLCode
	from dbo.bPRDT d with (nolock)
	join dbo.bPRSQ s with (nolock) on s.PRCo = d.PRCo and s.PRGroup = d.PRGroup and s.PREndDate = d.PREndDate
		and s.Employee = d.Employee
	where d.PRCo = @prco and d.PRGroup = @prgroup and d.Employee = @employee
		and ((d.PREndDate = @prenddate and d.PaySeq <= @payseq) -- #25504 - exclude codes in later pay seq#s
		or s.PaidMth between @accumbeginmth and @accumendmth) -- #25505 - include all codes paid in this year
	union
	select distinct EDLType, EDLCode
	from dbo.bPREA with (nolock)
	where PRCo = @prco and Employee = @employee
 		and Mth between @accumbeginmth and @accumendmth
	order by EDLType, EDLCode
	--end 137971
	
	open bcEDL
	select @openEDL = 1     -- set open cursor flag
	     
EDL_loop:     -- process each earnings, deduction, and liability code
	fetch next from bcEDL into @edltype, @edlcode

	if @@fetch_status <> 0 goto EDL_end

	-- skip Liab if not to be printed for this PR Group
	if @edltype = 'L' and not exists (select 1 from dbo.bPRGB with (nolock) where PRCo = @prco
						and PRGroup = @prgroup and LiabCode = @edlcode) goto EDL_loop

	-- right justify EDLcode for bPRSX
	select @code = space(10-datalength(convert(varchar(10),@edlcode))) + convert(varchar(10),@edlcode)

	-- process dedns and liabs
	IF @edltype in ('D','L')
	BEGIN
		-- get d/l description
		select @description = 'Invalid'
		select @description = Description
		from dbo.bPRDL with (nolock)
		where PRCo = @prco and DLCode = @edlcode
 
     	-- get current Pay Period amount - TK-16945 get payback amount for Arrears/Payback
		SELECT @amt = 0
		SELECT @PaybackAmt = 0
		SELECT @PaybackOverrideYN = 'N'
     	SELECT @amt = (CASE WHEN UseOver = 'Y' THEN OverAmt ELSE Amount END),
     		   @PaybackAmt = (CASE WHEN PaybackOverYN = 'Y' THEN PaybackOverAmt ELSE PaybackAmt END),
     		   @PaybackOverrideYN = PaybackOverYN
     	FROM dbo.bPRDT with (nolock)
 		WHERE PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
         	and Employee = @employee and PaySeq = @payseq and EDLType = @edltype and EDLCode = @edlcode
 
     	-- update check stub detail, Amt2 = current amt, Amt3 = year-to-date amt (adjusted for updates to Accums)- TK16945 update PaybackAmt for Arrears/Payback	
     	UPDATE dbo.bPRSX
     	SET Amt2 = Amt2 + @amt	-- current amount
     	WHERE PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
 			and PaySeq = @payseq and Type = @edltype and Code = @code and Rate = 0
     	IF @@ROWCOUNT = 0
     	BEGIN
     		INSERT dbo.bPRSX 
     			(
     				PRCo, PRGroup, PREndDate, Employee, PaySeq, Type, Code, Rate, Description, Amt1, Amt2, Amt3
     			)
     		VALUES
     			(
     				@prco, @prgroup, @prenddate, @employee, @payseq, @edltype, @code, 0, @description, 0, @amt, 0
     			)
     	END
         	
 
     	-- accumulate total deductions -- TK16945 include paybackamt in total deductions
 		if @edltype = 'D' select @ttldedns = @ttldedns + @amt + @PaybackAmt 
 		
 		--  Update/Create bPRSX record for PaybackAmt TK-17298
	    IF (@PaybackAmt <> 0) OR (@PaybackOverrideYN = 'Y') --TK-18004 create PRSX payback if override = Y
	    BEGIN
			UPDATE dbo.bPRSX
			SET Amt2 = Amt2 + @PaybackAmt
			WHERE PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
 			and PaySeq = @payseq and Type = @edltype and Code = @code and Rate = .99999
			IF @@ROWCOUNT = 0
			BEGIN
				INSERT dbo.bPRSX 
     				(
     					PRCo, PRGroup, PREndDate, Employee, PaySeq, Type, Code, Rate, Description, Amt1, Amt2, Amt3
     				)
     			VALUES
     				(
     					@prco, @prgroup, @prenddate, @employee, @payseq, @edltype, @code, .99999, 'Payback - ' + LEFT(@description,20), 0, @PaybackAmt, 0
     				)
			END
		END
 		
    END -- End Dedn/Liab
 
		-- process earnings
		if @edltype = 'E'
		begin
			-- get earnings description
			select @description = 'Invalid'
			select @description = Description, @method = Method, --issue 22251
			@routine = Routine --#129888 for Australia allowances need routine to determine if hours s/b written to bPRSX
			from dbo.bPREC with (nolock)
			where PRCo = @prco and EarnCode = @edlcode
     
			-- initialize cursor to breakout earings by rate from PR Timecards
			declare bcTimecard cursor for
			select Rate, convert(numeric(10,2),sum(Hours)), convert(numeric(12,2),sum(Amt))
			from dbo.bPRTH with (nolock)
			where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
			and Employee = @employee and PaySeq = @payseq and EarnCode = @edlcode
     		group by Rate
 
     		open bcTimecard
            select @openTimecard = 1      -- set open cursor flag
 
Timecard_loop: -- process each set of Timecards grouped by Rate
     		
			fetch next from bcTimecard into @rate, @hrs, @amt

			if @@fetch_status <> 0 goto Timecard_end

			-- skip if hours, rate and amount are 0
			if @rate = 0 and @hrs = 0 and @amt = 0 goto Timecard_loop

			-- if amount based earnings use 0.00 hrs and rate 
			select @uphrs = @hrs, @uprate = @rate
			if @method = 'A' select @uphrs = 0, @uprate = 0	

			-- update or add earnings to PR Stub Detail
			update dbo.bPRSX
			set Amt1 = Amt1 + @uphrs, Amt2 = Amt2 + @amt
			where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
				and Employee = @employee and PaySeq = @payseq and Type = 'E' and Code = @code and Rate = @uprate
				
			if @@rowcount = 0
				insert dbo.bPRSX (PRCo, PRGroup, PREndDate, Employee, PaySeq, Type, Code, Rate, Description, Amt1, Amt2, Amt3)
				values (@prco, @prgroup, @prenddate, @employee, @payseq, 'E', @code, @uprate, @description, @uphrs, @amt, 0)
						
			-- accumulate total hours and earnings
			select @ttlhrs = @ttlhrs + @hrs, @ttlearned = @ttlearned + @amt


			goto Timecard_loop  -- next group of Timecards
 
Timecard_end:
			close bcTimecard
			deallocate bcTimecard
			select @openTimecard = 0
 
			-- initialize cursor to breakout earnings by rate from PR Timecard Addons
            DECLARE bcAddon CURSOR FOR
     		SELECT Rate, convert(numeric(12,2),sum(Amt))
            FROM dbo.bPRTA with (nolock)
     		WHERE PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
                 and Employee = @employee and PaySeq = @payseq and EarnCode = @edlcode
     		GROUP BY Rate
 
     		OPEN bcAddon
            SELECT @openAddon = 1      -- set open cursor flag
 
Addon_loop:    -- process each Addon group by Rate
            FETCH NEXT FROM bcAddon INTO @rate, @amt
 
			IF @@fetch_status <> 0 goto Addon_end

			--#129888 for Australian allowances determine hours and clear rate so that it does not display on check
			SELECT @uphrs = 0
			IF @routine = 'Allowance' OR @routine = 'AllowRDO' 
			BEGIN
				SELECT @uphrs = convert(numeric(12,2),@amt/@rate)
				SELECT @rate = 0
			END
			
			--TK-20207 AUS crib and meal allowance addon earnings
			IF @DefaultCountry = 'AU' AND @method = 'L'
			BEGIN
				IF @rate <> 0
				BEGIN
					SELECT @uphrs = convert(numeric(12,2),@amt/@rate)
				END
			END

			-- update or add earnings to PR Stub Detail (0.00 hours)
			UPDATE dbo.bPRSX
			SET Amt1 = Amt1 + @uphrs, Amt2 = Amt2 + @amt
			WHERE PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
			and Employee = @employee and PaySeq = @payseq and Type = 'E' and Code = @code and Rate = @rate

			IF @@ROWCOUNT = 0
			INSERT dbo.bPRSX 
							(
								PRCo, PRGroup, PREndDate, Employee, PaySeq, Type, Code, Rate,
								Description, Amt1, Amt2, Amt3
							)
			VALUES 
					(
						@prco, @prgroup, @prenddate, @employee, @payseq, 'E', @code, @rate,
						@description, @uphrs, @amt, 0
					)

			-- accumulate total earnings
			SELECT @ttlearned = @ttlearned + @amt

			GOTO Addon_loop  -- next group of Addons
 
Addon_end:
			CLOSE bcAddon
			DEALLOCATE bcAddon
			SELECT @openAddon = 0
     	  	    
        end	-- finished with earnings 
      
---------------- Find and update stub detail with YTD amounts - all types ----------------
    
		-- get YTD amounts from Employee Accums to pull prior amounts and adjustments
		/*137971
		select @a1 = isnull(sum(Amount),0)
       	from dbo.bPREA with (nolock)
        where PRCo = @prco and Employee = @employee	and datepart(year,Mth) = datepart(year,@paidmth)
        	and EDLType = @edltype and EDLCode = @edlcode
		*/
		
		select @a1 = isnull(sum(Amount),0)
       	from dbo.bPREA with (nolock)
        where PRCo = @prco and Employee = @employee	and Mth between @accumbeginmth and @accumendmth
        and EDLType = @edltype and EDLCode = @edlcode
		--end 137971
		
		-- get current amounts from current and earlier Pay Periods where Final Accum update has not been run
		/*137971
        select @a2 = isnull(sum( case d.UseOver when 'Y' then d.OverAmt else d.Amount end),0)
        from dbo.bPRDT d with (nolock)
       	join dbo.bPRSQ s with (nolock) on s.PRCo = d.PRCo and s.PRGroup = d.PRGroup and s.PREndDate = d.PREndDate
        	and s.Employee = d.Employee and s.PaySeq = d.PaySeq
       	join dbo.bPRPC c with (nolock) on c.PRCo = d.PRCo and c.PRGroup = d.PRGroup and c.PREndDate = d.PREndDate
       	where d.PRCo = @prco and d.Employee = @employee	and d.EDLType = @edltype and d.EDLCode = @edlcode
       		and ((d.PREndDate < @prenddate) or (d.PREndDate = @prenddate and d.PaySeq <= @payseq))
       		and ((s.PaidMth is null and c.MultiMth='N' and datepart(year,c.BeginMth) = datepart(year,@paidmth)) --26698
			or (s.PaidMth is null and c.MultiMth='Y' and datepart(year,c.EndMth) = datepart(year,@paidmth)) --26698
            	or (datepart(year,s.PaidMth) = datepart(year,@paidmth)))
       		and c.GLInterface = 'N'
		*/
		
		 -- TK-16945 include paybackamt in ytd sum when amount is from bPRDT
        SELECT @a2 = (ISNULL(SUM( CASE d.UseOver WHEN 'Y' THEN d.OverAmt ELSE d.Amount END),0)) 
					+ (ISNULL(SUM(CASE WHEN d.PaybackOverYN='Y' THEN d.PaybackOverAmt ELSE d.PaybackAmt END),0))
        FROM dbo.bPRDT d WITH (NOLOCK)
       	JOIN dbo.bPRSQ s with (nolock) on s.PRCo = d.PRCo and s.PRGroup = d.PRGroup and s.PREndDate = d.PREndDate
        	and s.Employee = d.Employee and s.PaySeq = d.PaySeq
       	JOIN dbo.bPRPC c with (nolock) on c.PRCo = d.PRCo and c.PRGroup = d.PRGroup and c.PREndDate = d.PREndDate
       	WHERE d.PRCo = @prco and d.Employee = @employee	and d.EDLType = @edltype and d.EDLCode = @edlcode
       		and ((d.PREndDate < @prenddate) or (d.PREndDate = @prenddate and d.PaySeq <= @payseq))
       		and ((s.PaidMth is null and c.MultiMth='N' and c.BeginMth between @accumbeginmth and @accumendmth) --26698
			or (s.PaidMth is null and c.MultiMth='Y' and c.EndMth between @accumbeginmth and @accumendmth) --26698
            	or s.PaidMth between @accumbeginmth and @accumendmth)
       		and c.GLInterface = 'N'
		--137971

				
		-- get old amounts from current and earlier Pay Periods where Final Accum update has not been run
		/*137971
       	select @a3 = isnull(sum(OldAmt),0)
       	from dbo.bPRDT d with (nolock)
       	join dbo.bPRPC c with (nolock) on c.PRCo = d.PRCo and c.PRGroup = d.PRGroup and c.PREndDate = d.PREndDate
       	where d.PRCo = @prco and d.Employee = @employee and d.EDLType = @edltype and d.EDLCode = @edlcode
       		and ((d.PREndDate < @prenddate) or (d.PREndDate = @prenddate and d.PaySeq <= @payseq))
       		and datepart(year,d.OldMth) = datepart(year,@paidmth)
       		and c.GLInterface = 'N'
		*/
		
		-- TK-16945 include PaybackAmt in ytd sum when oldamt is from PRDT
    	SELECT @a3 = (ISNULL(SUM(OldAmt),0)) + (ISNULL(SUM(CASE WHEN PaybackOverYN='Y' THEN PaybackOverAmt ELSE PaybackAmt END),0))
       	FROM dbo.bPRDT d with (nolock)
       	JOIN dbo.bPRPC c with (nolock) on c.PRCo = d.PRCo and c.PRGroup = d.PRGroup and c.PREndDate = d.PREndDate
       	WHERE d.PRCo = @prco and d.Employee = @employee and d.EDLType = @edltype and d.EDLCode = @edlcode
       		and ((d.PREndDate < @prenddate) or (d.PREndDate = @prenddate and d.PaySeq <= @payseq))
       		and d.OldMth between @accumbeginmth and @accumendmth
       		and c.GLInterface = 'N'
		--end 137971      		
       		
        -- get old amount from later Pay Periods - need to back out of accums
        /*137971
        select @a4 = isnull(sum(OldAmt),0)
        from dbo.bPRDT with (nolock)
        where PRCo = @prco and Employee = @employee and EDLType = @edltype and EDLCode = @edlcode
			and ((PREndDate > @prenddate) or (PREndDate = @prenddate and PaySeq > @payseq))
       		and datepart(year,OldMth) = datepart(year,@paidmth)
       	*/
       	
		-- TK-16945 include PaybackAmt in ytd sum when oldamt is from PRDT
        SELECT @a4 = (ISNULL(SUM(OldAmt),0)) + (ISNULL(SUM(CASE WHEN PaybackOverYN='Y' THEN PaybackOverAmt ELSE PaybackAmt END),0))
        FROM dbo.bPRDT with (nolock)
        WHERE PRCo = @prco and Employee = @employee and EDLType = @edltype and EDLCode = @edlcode
			and ((PREndDate > @prenddate) or (PREndDate = @prenddate and PaySeq > @payseq))
       		and OldMth between @accumbeginmth and @accumendmth
		--137971       		

		-- calculate ytd amt as accums + net from current and earlier Pay Pds - old from later Pay Pds
        select @amt = @a1 + (@a2 - @a3) - @a4

           
		-- determine rate of PRSX entry (if one exists) to change
		select @rate = min(Rate)
		from dbo.bPRSX with (nolock)
		where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
		and PaySeq = @payseq and Type = @edltype and Code = @code
 
      	if @rate is null select @rate = 0
 
		--update or insert check stub detail with year-to-date amount
		update dbo.bPRSX
		set Amt3 = Amt3 + @amt
		where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
		and Employee = @employee and PaySeq = @payseq and Type = @edltype
		and Code = @code and Rate = @rate
		
		if @@rowcount = 0
			insert dbo.bPRSX (PRCo, PRGroup, PREndDate, Employee, PaySeq, Type, Code, Rate,
			Description, Amt1, Amt2, Amt3)
			values (@prco, @prgroup, @prenddate, @employee, @payseq, @edltype, @code,
			@rate, @description, 0, 0, @amt)
 
		goto EDL_loop
 
EDL_end:
	close bcEDL
	deallocate bcEDL
	select @openEDL = 0

	-- #25504 remove zero entries from stub detail - TK-18004 do not delete if rec is payback
	DELETE dbo.bPRSX
	WHERE	PRCo = @prco and 
			PRGroup = @prgroup and 
			PREndDate = @prenddate	and 
			Employee = @employee and 
			PaySeq = @payseq and 
			Amt2 = 0 and 
			Amt3 = 0 AND
			Rate <> .99999 


 
 	/* finished with earnings, deductions, and liabilities */

-- add leave accums to check stub info
EXEC	@rcode = [dbo].[vspPRGetLeaveAccumsForPayStubs]
		@prco = @prco,
		@prgroup = @prgroup,
		@employee = @employee,
		@periodenddate = @prenddate,
		@yearbeginmth = @accumbeginmth,
		@payseq = @payseq,
		@msg = @msg OUTPUT

 
bspexit:

	if @openEDL = 1
	begin
		close bcEDL
		deallocate bcEDL
	end

	if @openTimecard = 1
	begin
		close bcTimecard
		deallocate bcTimecard
	end
	
	if @openAddon = 1
	begin
		close bcAddon
		deallocate bcAddon
	end
	
	if @rcode = 1 --select @msg = isnull(@msg,'') --+ char(13) + char(10) + 'bspPRCheckStubLoad'
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRCheckStubLoad] TO [public]
GO
