SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspPRDirectDepositStubProcess]
/***********************************************************
* Created: GG 05/18/07 - enhanced version of bspPRDirectDepositStubProcess for 6.0
* Modified:	GG 05/18/07 - #124605 - added sort options to match PR Check Print
*			GG 06/08/07 - #124797 - added override ChkSort in bPRSQ
*			EN 4/03/2009 #129888  for Australian allowances include hours with allowances
*			mh 02/19/2010 Issue 137971 - Modified date comparisons to allow for non calendar year accum.
*			mh 02/19/2010 #137971 - modified to allow date compares to use other then calendar year.
*			mh 08/17/2010 #140799 - Moved call to vspPRGetMthsForAnnualCalcs into process loop.
*			MV 04/06/11 #142543 - Use @prenddate instead of @endmth to get @ystdusage from bPRLH
*			JayR 07/3/2012 TK-16107  Removed unneeded grant.
*			MV 08/08/2012 TK-16945 - update Amt2 in bPRSX with bPRDT.PaybackAmt for deductions.  Update Amt3 with PaybackAmt where amount comes from bPRDT
*			MV 08/20/2012 TK-17298 - insert Payback Amount rec into bPRSX for deductions with a payback amount.
*			MV 09/20/2012 D-05949/TK18004 - create bPRSX for payback when PaybackOverrideYN flag = Y
			MV 10/25/2012 TK-18862 - Initialize @PaybackOverrideYN flag to 'N'
			MV 12/17/0112 TK-20207 - AU crib and meal allowance addon earnings.
*			EN 1/17/2013 D-06530/#142769/TK-20813 replaced code to locate YTD leave usage amount with call to 
*						 stored proc vspPRGetLeaveAccumsForPayStubs ... this normalizes code
*						 that was repeated in 3 places
*
* USAGE:
* Process payment information in preparation for printing direct deposit stubs.
* Payment information is added to Stub Print and Detail tables (bPRSP and bPRSX)
* Stubs are printed optionally after EFT text file has been created.
*
* INPUT PARAMETERS
*   @prco		    PR Company #
*   @prgroup		PR Group
*   @prenddate		Pay Period Ending Date
*   @payseq			Payment sequence # (used for restriction - optional)
*   @sortopt   		Sort option ('N'=Name,'E'=Employee#,'J'=Job,'C'=Chk Sort,'W'=Crew)
*   @beginsort 		Beginning SortName
*   @endsort		Ending SortName
*   @beginempl 		Beginning Employee number
*   @endempl		Ending Employee number
*   @beginjcco		Beginning JC company number
*   @endjcco		Ending JC company number
*   @beginjob		Beginning Job number
*   @endjob			Ending Job number
*   @beginchkord	Beginning Check Print Order
*   @endchkord		Ending Check Print Order
*	@begincrew		Beginning Crew
*	@endcrew		Ending Crew
*   @cmco 			CM Company number (optional)
*   @cmacct			CM Account number (optional)
*   @cmref 			CM Reference number (optional)
*              
* OUTPUT PARAMETERS
*   @msg      		error message if error occurs
*
* RETURN VALUE
*   0   success
*   1   fail
*******************************************************************/
	(@prco bCompany = null, @prgroup bGroup = null, @prenddate bDate = null,
	 @payseq tinyint = null, @sortopt char(1) = null, @beginsort bSortName = null,
	 @endsort bSortName = null, @beginempl bEmployee = null, @endempl bEmployee = null,
	 @beginjcco bCompany = null, @endjcco bCompany = null, @beginjob bJob = null,
	 @endjob bJob = null, @beginchkord varchar(10) = null, @endchkord varchar(10) = null,
	 @begincrew varchar(10) = null, @endcrew varchar(10) = null, @cmco bCompany = null,
	 @cmacct bCMAcct = null, @cmref bCMRef = null, @msg varchar(60) output)
as

set nocount on

declare @rcode tinyint, @employee bEmployee, @pseq tinyint, @paymethod varchar(1), @lastname varchar(30),
	@firstname varchar(30), @midname varchar(15), @sortname bSortName, @address varchar(60), @city varchar(30),
	@state varchar(2), @zip varchar(12), @ssn varchar(11), @jcco bCompany, @job bJob, @chksort varchar(10),
	@edltype varchar(1), @edlcode bEDLCode, @rate bUnitCost, @hrs bHrs, @amt bDollar, @paiddate bDate, @paidmth bMonth,
	@crew varchar(10), @uprate bUnitCost, @uphrs bHrs, @a1 bDollar, @a2 bDollar, @a3 bDollar, @a4 bDollar

declare @openPaySeq tinyint, @openEDL tinyint, @openTimecard tinyint, @openAddon tinyint,
	@fedcode bEDLCode, @code varchar(10), @description varchar(30), @filestatus varchar(1), @exempts tinyint,
	@useover bYN, @overamt bDollar,
	@status tinyint, @method char(1),@PaybackAmt bDollar, @PaybackOverrideYN bYN, @DefaultCountry Char(2)
     
--#129888 Australian allowances
declare @routine varchar(10)

select @rcode = 0, @DefaultCountry = dbo.vfGetHQCODefaultCountry(@prco) --TK20207 

--validate PR Co#, get Federal tax deduction code
select @fedcode = TaxDedn
from dbo.bPRFI (nolock) where PRCo = @prco
if @@rowcount = 0
    begin
    select @msg = 'Invalid PR Company #!', @rcode = 1
    goto vspexit
    end

-- validate Sort option
if @sortopt not in ('N','E','J','C','W')
	begin
	select @msg = 'Invalid sort order.  Must be N, E, J, C, or W!', @rcode = 1
	goto vspexit
	end

--137971
declare @yearendmth tinyint, @beginmth bMonth, @endmth bMonth

select @yearendmth = case h.DefaultCountry when 'AU' then 6 else 12 end
from bHQCO h with (nolock) 
where h.HQCo = @prco

--This needs to be called from within the Process Loop.  We do not know what the Paid Month is until
--we pull the data out of PRSQ.
--exec vspPRGetMthsForAnnualCalcs @yearendmth, @paidmth, @beginmth output, @endmth output, @msg output


-- initialize cursor on Payment Sequence based on Sort Option 
if @sortopt = 'N' -- Employee Sort Name
	declare bcPaySeq cursor for
	select e.SortName, s.Employee, s.PaySeq, s.PayMethod, s.CMRef, s.PaidDate, s.PaidMth,
		e.LastName, e.FirstName, e.MidName, e.Address, e.City, e.State, e.Zip,
		(case when c.ExcludeSSN = 'N' then e.SSN else '' end), e.JCCo, e.Job, isnull(s.ChkSort,e.ChkSort), e.Crew
	from dbo.bPRSQ s (nolock)
	join dbo.bPREH e (nolock) on e.PRCo = s.PRCo and e.Employee = s.Employee
	join dbo.bPRCO c (nolock) on c.PRCo = s.PRCo
	where s.PRCo = @prco and s.PRGroup = @prgroup and s.PREndDate = @prenddate and s.PaySeq = isnull(@payseq,s.PaySeq)
		and s.CMCo = isnull(@cmco,s.CMCo) and s.CMAcct = isnull(@cmacct,s.CMAcct)and s.CMRef = isnull(@cmref,s.CMRef)
		and s.PayMethod = 'E'
		and e.SortName >= isnull(@beginsort,'') and e.SortName <= isnull(@endsort,'~~~~~~~~~~~~~~~')
	order by e.SortName, s.Employee, s.PaySeq

if @sortopt = 'E' -- Employee #
	declare bcPaySeq cursor for
	select e.SortName, s.Employee, s.PaySeq, s.PayMethod, s.CMRef, s.PaidDate, s.PaidMth,
		e.LastName, e.FirstName, e.MidName, e.Address, e.City, e.State, e.Zip,
		(case when c.ExcludeSSN='N' then e.SSN else '' end), e.JCCo, e.Job, isnull(s.ChkSort,e.ChkSort), e.Crew
	from dbo.bPRSQ s (nolock)
	join dbo.bPREH e (nolock) on e.PRCo = s.PRCo and e.Employee = s.Employee
	join dbo.bPRCO c (nolock) on c.PRCo = s.PRCo
	where s.PRCo = @prco and s.PRGroup = @prgroup and s.PREndDate = @prenddate and s.PaySeq = isnull(@payseq,s.PaySeq)
		and s.CMCo = isnull(@cmco,s.CMCo) and s.CMAcct = isnull(@cmacct,s.CMAcct)and s.CMRef = isnull(@cmref,s.CMRef)
		and s.PayMethod = 'E'
		and s.Employee >= isnull(@beginempl,0) and s.Employee <= isnull(@endempl,999999)
	order by s.Employee, s.PaySeq

if @sortopt = 'J' -- Job and Employee # - not all restrictions exist in where clause
	declare bcPaySeq cursor for
	select e.SortName, s.Employee, s.PaySeq, s.PayMethod, s.CMRef, s.PaidDate, s.PaidMth,
   		e.LastName, e.FirstName, e.MidName, e.Address, e.City, e.State, e.Zip, 
		(case when c.ExcludeSSN = 'N' then e.SSN else '' end), e.JCCo, e.Job, isnull(s.ChkSort,e.ChkSort), e.Crew
	from dbo.bPRSQ s (nolock)
	join dbo.bPREH e (nolock) on e.PRCo = s.PRCo and e.Employee = s.Employee
	join dbo.bPRCO c (nolock) on c.PRCo = s.PRCo
	where s.PRCo = @prco and s.PRGroup = @prgroup and s.PREndDate = @prenddate and s.PaySeq = isnull(@payseq,s.PaySeq)
		and s.CMCo = isnull(@cmco,s.CMCo) and s.CMAcct = isnull(@cmacct,s.CMAcct)and s.CMRef = isnull(@cmref,s.CMRef)
		and s.PayMethod = 'E'
		and isnull(e.JCCo,0) >= isnull(@beginjcco,0) and isnull(e.JCCo,0) <= isnull(@endjcco,255)
	order by e.JCCo, e.Job, isnull(s.ChkSort,e.ChkSort), s.Employee, s.PaySeq
     
if @sortopt = 'C' -- Employee Check Sort for a range
	declare bcPaySeq cursor  for
	select e.SortName, s.Employee, s.PaySeq, s.PayMethod, s.CMRef, s.PaidDate, s.PaidMth,
		e.LastName, e.FirstName, e.MidName, e.Address, e.City, e.State, e.Zip,
		(case when c.ExcludeSSN = 'N' then e.SSN else '' end), e.JCCo, e.Job, isnull(s.ChkSort,e.ChkSort), e.Crew
	from dbo.bPRSQ s (nolock)
	join dbo.bPREH e (nolock) on e.PRCo = s.PRCo and e.Employee = s.Employee
	join dbo.bPRCO c (nolock) on c.PRCo = s.PRCo
	where s.PRCo = @prco and s.PRGroup = @prgroup and s.PREndDate = @prenddate and s.PaySeq = isnull(@payseq,s.PaySeq)
		and s.CMCo = isnull(@cmco,s.CMCo) and s.CMAcct = isnull(@cmacct,s.CMAcct)and s.CMRef = isnull(@cmref,s.CMRef)
		and s.PayMethod = 'E'
		and coalesce(s.ChkSort,e.ChkSort,'') >= isnull(@beginchkord,'') and coalesce(s.ChkSort,e.ChkSort,'') <= isnull(@endchkord,'~~~~~~~~~~')
	order by isnull(s.ChkSort,e.ChkSort), s.Employee, s.PaySeq
     
if @sortopt = 'W' -- Crew for a range
	declare bcPaySeq cursor  for
	select e.SortName, s.Employee, s.PaySeq, s.PayMethod, s.CMRef, s.PaidDate, s.PaidMth,
		e.LastName, e.FirstName, e.MidName, e.Address, e.City, e.State, e.Zip,
		(case when c.ExcludeSSN='N' then e.SSN else '' end), e.JCCo, e.Job, isnull(s.ChkSort,e.ChkSort), e.Crew
	from dbo.bPRSQ s (nolock)
	join dbo.bPREH e (nolock) on e.PRCo = s.PRCo and e.Employee = s.Employee
	join dbo.bPRCO c (nolock) on c.PRCo = s.PRCo
	where s.PRCo = @prco and s.PRGroup = @prgroup and s.PREndDate = @prenddate and s.PaySeq = isnull(@payseq,s.PaySeq)
		and s.CMCo = isnull(@cmco,s.CMCo) and s.CMAcct = isnull(@cmacct,s.CMAcct)and s.CMRef = isnull(@cmref,s.CMRef)
		and s.PayMethod = 'E'
		and isnull(e.Crew,'') >= isnull(@begincrew,'') and isnull(e.Crew,'') <= isnull(@endcrew,'~~~~~~~~~~')
	order by e.Crew, isnull(s.ChkSort,e.ChkSort), s.Employee, s.PaySeq
     
open bcPaySeq
select @openPaySeq = 1      -- set open cursor flag

-- process each row in cursor
PaySeq_loop:
	fetch next from bcPaySeq into @sortname, @employee, @pseq, @paymethod, @cmref, @paiddate, @paidmth,
		@lastname, @firstname, @midname, @address, @city, @state, @zip, @ssn, @jcco, @job, @chksort, @crew
     
	if @@fetch_status <> 0 goto PaySeq_end
     
	if @sortopt = 'J'   -- apply Job/Employee sort restrictions - include all Employees within Job range
		begin
		if isnull(@jcco,0) = isnull(@beginjcco,0) and isnull(@job,'') < isnull(@beginjob,'') goto PaySeq_loop
		if isnull(@jcco,0) = isnull(@beginjcco,0) and isnull(@job,'') = isnull(@beginjob,'')
			and @employee < isnull(@beginempl,0) goto PaySeq_loop
		if isnull(@jcco,0) = isnull(@endjcco,255) and isnull(@job,'') > isnull(@endjob,'~~~~~~~~~~') goto PaySeq_loop
		if isnull(@jcco,0) = isnull(@endjcco,255) and isnull(@job,'') = isnull(@endjob,'~~~~~~~~~~')
			and @employee > isnull(@endempl,999999) goto PaySeq_loop
		end

	if @sortopt = 'C'   -- apply Check Order/Employee # restrictions - include all Employees within Check Order range
		begin
		if isnull(@chksort,'') = isnull(@beginchkord,'') and @employee < isnull(@beginempl,0) goto PaySeq_loop
		if isnull(@chksort,'') = isnull(@endchkord,'~~~~~~~~~~') and @employee > isnull(@endempl,999999) goto PaySeq_loop
		end

	if @sortopt = 'W'   -- apply Crew/Employee # restrictions - include all Employees within Check Order range
		begin
		if isnull(@crew,'') = isnull(@begincrew,'') and @employee < isnull(@beginempl,0) goto PaySeq_loop
		if isnull(@crew,'') = isnull(@endcrew,'~~~~~~~~~~') and @employee > isnull(@endempl,999999) goto PaySeq_loop
		end
     
    --137971 get Beginning and Ending Months for YTD accums
	exec vspPRGetMthsForAnnualCalcs @yearendmth, @paidmth, @beginmth output, @endmth output, @msg output
	
	-- get Employee Federal filing status and exemptions
	select @filestatus = null, @exempts = null
	select @filestatus = FileStatus, @exempts = RegExempts
	from dbo.bPRED (nolock)
	where PRCo = @prco and Employee = @employee and DLCode = @fedcode

	-- add stub header
	insert dbo.bPRSP (PRCo, PRGroup, PREndDate, Employee, PaySeq, PayMethod, CMRef, PaidDate,
		LastName, FirstName, MidName, Address, City, State, Zip, SSN, FileStatus, Exempts,
		SortName, ChkSort, JCCo, Job, SortOrder, Crew)
	values (@prco, @prgroup, @prenddate, @employee, @pseq, @paymethod, @cmref, @paiddate,
		@lastname, @firstname, @midname, @address, @city, @state, @zip, @ssn, @filestatus, @exempts,
		@sortname, @chksort, @jcco, @job, @sortopt, @crew)
    
	-- find all earnings, deductions, and liabilities to include on the deposit advice stub

	-- initialize a cursor on PR Detail Totals and Employee Accums for all E/D/Ls processed within the year
	declare bcEDL cursor for
	/*137971
	select distinct EDLType, EDLCode
	from dbo.bPRDT d (nolock)
	join dbo.bPRSQ s (nolock) on s.PRCo = d.PRCo and s.PRGroup = d.PRGroup and s.PREndDate = d.PREndDate
		and s.Employee = d.Employee
	where d.PRCo = @prco and d.PRGroup = @prgroup and d.Employee = @employee
	and ((d.PREndDate = @prenddate and d.PaySeq <= @pseq) -- #25504 - exclude codes in later pay seq#s
		or (datepart(year,s.PaidMth)=datepart(year,@paidmth))) -- #25505 - include all codes paid in this year
	union
	select distinct EDLType, EDLCode
	from dbo.bPREA (nolock)
	where PRCo = @prco and Employee = @employee	and datepart(year,Mth) = datepart(year,@paidmth)
	order by EDLType, EDLCode
	*/
	
	select distinct EDLType, EDLCode
	from dbo.bPRDT d (nolock)
	join dbo.bPRSQ s (nolock) on s.PRCo = d.PRCo and s.PRGroup = d.PRGroup and s.PREndDate = d.PREndDate
		and s.Employee = d.Employee
	where d.PRCo = @prco and d.PRGroup = @prgroup and d.Employee = @employee
	and ((d.PREndDate = @prenddate and d.PaySeq <= @pseq) -- #25504 - exclude codes in later pay seq#s
		or (s.PaidMth between @beginmth and @endmth)) -- #25505 - include all codes paid in this year
	union
	select distinct EDLType, EDLCode
	from dbo.bPREA (nolock)
	where PRCo = @prco and Employee = @employee	and Mth between @beginmth and @endmth
	order by EDLType, EDLCode
	
	open bcEDL
	select @openEDL = 1     -- set open cursor flag
     
    EDL_loop:     -- process each earnings, deduction, and liability code
		fetch next from bcEDL into @edltype, @edlcode
      	if @@fetch_status <> 0 goto EDL_end
     
		-- skip Liab if not to be printed for this PR Group
		if @edltype = 'L' and not exists (select top 1 1 from dbo.bPRGB (nolock) where PRCo = @prco
			and PRGroup = @prgroup and LiabCode = @edlcode) goto EDL_loop

		-- right justify code for stub detail
		select @code = space(10-datalength(convert(varchar(10),@edlcode))) + convert(varchar(10),@edlcode)

		-- process dedns and liabs
		IF @edltype in ('D','L')
  		BEGIN
			-- get d/l description
			select @description = 'Invalid'
			select @description = Description
			from dbo.bPRDL (nolock)
			where PRCo = @prco and DLCode = @edlcode
     
            -- get current Pay Period and Seq amount - TK-16945 get payback amount for Arrears/Payback
 			SELECT @amt = 0
            SELECT @PaybackAmt = 0 -- initialize variable
       		SELECT @PaybackOverrideYN = 'N'
            SELECT @amt = (CASE WHEN UseOver='Y' THEN OverAmt ELSE Amount END),
				   @PaybackAmt = (CASE WHEN PaybackOverYN = 'Y' THEN PaybackOverAmt ELSE PaybackAmt END),
				   @PaybackOverrideYN = PaybackOverYN
			FROM dbo.bPRDT (nolock)
  	  	 	WHERE PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
				and Employee = @employee and PaySeq = @pseq and EDLType = @edltype and EDLCode = @edlcode
 
            -- update check stub detail, Amt2 = current amt, Amt3 = year-to-date amt - TK16945 update PaybackAmt for Arrears/Payback
  			UPDATE dbo.bPRSX
  			SET Amt2 = Amt2 + @amt
  			WHERE PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
				and PaySeq = @pseq and Type = @edltype and Code = @code and Rate = 0
            IF @@rowcount = 0
            BEGIN
				INSERT dbo.bPRSX 
					(
						PRCo, PRGroup, PREndDate, Employee, PaySeq, Type, Code, Rate,Description, Amt1, Amt2, Amt3
					)
  			    VALUES 
  					(
  						@prco, @prgroup, @prenddate, @employee, @pseq, @edltype, @code, 0, @description, 0, @amt, 0
  					)
            END
            
            --  Update/Create bPRSX record for PaybackAmt TK-17298
		    IF (@PaybackAmt <> 0) OR (@PaybackOverrideYN = 'Y') --TK-18004 create PRSX payback if override = Y
			BEGIN
				UPDATE dbo.bPRSX
				SET Amt2 = Amt2 + @PaybackAmt
				WHERE PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
				and PaySeq = @pseq and Type = @edltype and Code = @code and Rate = .99999
				IF @@ROWCOUNT = 0
				BEGIN
					INSERT dbo.bPRSX 
						(
							PRCo, PRGroup, PREndDate, Employee, PaySeq, Type, Code, Rate, Description, Amt1, Amt2, Amt3
						)
					VALUES
						(
							@prco, @prgroup, @prenddate, @employee, @pseq, @edltype, @code, .99999, 'Payback - ' + LEFT(@description,20), 0, @PaybackAmt, 0
						)
				END
			END
				
  	  	 END -- End Dedn/Liab
     
		-- process earnings
		if @edltype = 'E'
			begin
			-- get earnings description
			select @description = 'Invalid'
			select @description = Description, @method = Method, /*issue 18016*/
					@routine = Routine --#129888 for Australia allowances need routine to determine if hours s/b written to bPRSX
			from dbo.bPREC with (nolock)
	 		where PRCo = @prco and EarnCode = @edlcode

			-- initialize cursor to get current earnings from PR Timecards
			declare bcTimecard cursor for
			select Rate, convert(numeric(10,2),sum(Hours)), convert(numeric(12,2),sum(Amt))
			from dbo.bPRTH with (nolock)
			where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
				and Employee = @employee and PaySeq = @pseq and EarnCode = @edlcode
			group by Rate
     
      		open bcTimecard
            select @openTimecard = 1      -- set open cursor flag
     
			Timecard_loop:        -- process each set of Timecards grouped by Rate
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
 	    			and Employee = @employee and PaySeq = @pseq and Type = 'E' and Code = @code and Rate = @uprate
 	            if @@rowcount = 0
 	                insert dbo.bPRSX (PRCo, PRGroup, PREndDate, Employee, PaySeq, Type, Code, Rate,
 	                    Description, Amt1, Amt2, Amt3)
 	                values (@prco, @prgroup, @prenddate, @employee, @pseq, 'E', @code, @uprate,
 	                    @description, @uphrs, @amt, 0)
       
				goto Timecard_loop  -- next group of Timecards
     
     		Timecard_end:
      			close bcTimecard
      		    deallocate bcTimecard
      		    select @openTimecard = 0
     
 			-- initialize cursor to get add-on earnings by rate
            DECLARE bcAddon CURSOR FOR
  			SELECT Rate, convert(numeric(12,2),sum(Amt))
            FROM dbo.bPRTA (nolock)
  			WHERE PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
				and Employee = @employee and PaySeq = @pseq and EarnCode = @edlcode
  			GROUP BY Rate
 
  		    OPEN bcAddon
            SELECT @openAddon = 1      -- set open cursor flag
     
      		Addon_loop:    -- process each Addon Earnings Code by Rate
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

 				-- update or add earnings to stub detail - set rate and ytd amounts to 0.00
 	            UPDATE dbo.bPRSX
 	    		SET Amt1 = Amt1 + @uphrs, Amt2 = Amt2 + @amt
 	    		WHERE PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
 	    			and Employee = @employee and PaySeq = @pseq and Type = 'E' and Code = @code and Rate = @rate
 	            IF @@ROWCOUNT = 0
 	            INSERT dbo.bPRSX 
 								(
 									PRCo, PRGroup, PREndDate, Employee, PaySeq, Type, Code, Rate,
 	                				Description, Amt1, Amt2, Amt3
 	                			)
 	            VALUES 
 						(
 							@prco, @prgroup, @prenddate, @employee, @pseq, 'E', @code, @rate,
 							@description, @uphrs, @amt, 0
 						)
     
                GOTO Addon_loop  -- next group of Addons
     
     			Addon_end:
					CLOSE bcAddon
      		        DEALLOCATE bcAddon
      		        SELECT @openAddon = 0
     
			end	-- end of Earnings
     
     
		--------- Find and update stub detail with YTD amounts - all types -------
     
 		-- get YTD amounts from Employee Accums to pull prior amounts and adjustments
/*137971 		
 		select @a1 = isnull(sum(Amount),0)
        from dbo.bPREA (nolock)
        where PRCo = @prco and Employee = @employee	and datepart(year,Mth) = datepart(year,@paidmth)
			and EDLType = @edltype and EDLCode = @edlcode
*/

 		select @a1 = isnull(sum(Amount),0)
        from dbo.bPREA (nolock)
        where PRCo = @prco and Employee = @employee	and Mth between @beginmth and @endmth
			and EDLType = @edltype and EDLCode = @edlcode
			
--end 137971
			        
        -- get current amounts from current and earlier Pay Periods where Final Accum update has not been run
/*137971 	
        select @a2 = isnull(sum( case d.UseOver when 'Y' then d.OverAmt else d.Amount end),0)
        from dbo.bPRDT d (nolock)
		join dbo.bPRSQ s (nolock) on s.PRCo = d.PRCo and s.PRGroup = d.PRGroup and s.PREndDate = d.PREndDate
         	and s.Employee = d.Employee and s.PaySeq = d.PaySeq
        join dbo.bPRPC c (nolock) on c.PRCo = d.PRCo and c.PRGroup = d.PRGroup and c.PREndDate = d.PREndDate
        where d.PRCo = @prco and d.Employee = @employee	and d.EDLType = @edltype and d.EDLCode = @edlcode
        	and ((d.PREndDate < @prenddate) or (d.PREndDate = @prenddate and d.PaySeq <= @pseq))
        	and ((s.PaidMth is null and c.MultiMth='N' and datepart(year,c.BeginMth) = datepart(year,@paidmth)) --26698
			or (s.PaidMth is null and c.MultiMth='Y' and datepart(year,c.EndMth) = datepart(year,@paidmth)) --26698
            or (datepart(year,s.PaidMth) = datepart(year,@paidmth)))
        	and c.GLInterface = 'N'
*/
		-- TK-16945 include paybackamt in ytd sum when amount is from bPRDT
        SELECT @a2 = (ISNULL(SUM( CASE d.UseOver WHEN 'Y' THEN d.OverAmt ELSE d.Amount END),0)) 
					+ (ISNULL(SUM(CASE WHEN d.PaybackOverYN='Y' THEN d.PaybackOverAmt ELSE d.PaybackAmt END),0))
        FROM dbo.bPRDT d (nolock)
		JOIN dbo.bPRSQ s (nolock) on s.PRCo = d.PRCo and s.PRGroup = d.PRGroup and s.PREndDate = d.PREndDate
         	and s.Employee = d.Employee and s.PaySeq = d.PaySeq
        JOIN dbo.bPRPC c (nolock) on c.PRCo = d.PRCo and c.PRGroup = d.PRGroup and c.PREndDate = d.PREndDate
        WHERE d.PRCo = @prco and d.Employee = @employee	and d.EDLType = @edltype and d.EDLCode = @edlcode
        	and ((d.PREndDate < @prenddate) or (d.PREndDate = @prenddate and d.PaySeq <= @pseq))
        	and ((s.PaidMth is null and c.MultiMth='N' and c.BeginMth between @beginmth and @endmth) --26698
			or (s.PaidMth is null and c.MultiMth='Y' and c.BeginMth between @beginmth and @endmth) --26698
            or (s.PaidMth between @beginmth and @endmth))
        	and c.GLInterface = 'N'
--end 137971
        
     	-- get old amounts from current and earlier Pay Periods where Final Accum update has not been run
/*  137971   	
        select @a3 = isnull(sum(OldAmt),0)
        from dbo.bPRDT d (nolock)
        join dbo.bPRPC c (nolock) on c.PRCo = d.PRCo and c.PRGroup = d.PRGroup and c.PREndDate = d.PREndDate
        where d.PRCo = @prco and d.Employee = @employee and d.EDLType = @edltype and d.EDLCode = @edlcode
			and ((d.PREndDate < @prenddate) or (d.PREndDate = @prenddate and d.PaySeq <= @pseq))
            and datepart(year,d.OldMth) = datepart(year,@paidmth)
            and c.GLInterface = 'N'
*/      
		-- TK-16945 include PaybackAmt in ytd sum when oldamt is from PRDT
       	SELECT @a3 = (ISNULL(SUM(OldAmt),0)) + (ISNULL(SUM(CASE WHEN PaybackOverYN='Y' THEN PaybackOverAmt ELSE PaybackAmt END),0))
        FROM dbo.bPRDT d (nolock)
        JOIN dbo.bPRPC c (nolock) on c.PRCo = d.PRCo and c.PRGroup = d.PRGroup and c.PREndDate = d.PREndDate
        WHERE d.PRCo = @prco and d.Employee = @employee and d.EDLType = @edltype and d.EDLCode = @edlcode
			and ((d.PREndDate < @prenddate) or (d.PREndDate = @prenddate and d.PaySeq <= @pseq))
            and d.OldMth between @beginmth and @endmth
            and c.GLInterface = 'N'
--end 137971
                    
		-- get old amount from later Pay Periods - need to back out of accums
/*  137971   			
        select @a4 = isnull(sum(OldAmt),0)
        from dbo.bPRDT (nolock)
        where PRCo = @prco and Employee = @employee and EDLType = @edltype and EDLCode = @edlcode
 			and ((PREndDate > @prenddate) or (PREndDate = @prenddate and PaySeq > @pseq))
        	and datepart(year,OldMth) = datepart(year,@paidmth)
*/
		-- TK-16945 include PaybackAmt in ytd sum when oldamt is from PRDT
        SELECT @a4 = (ISNULL(SUM(OldAmt),0)) + (ISNULL(SUM(CASE WHEN PaybackOverYN='Y' THEN PaybackOverAmt ELSE PaybackAmt END),0))
        FROM dbo.bPRDT (nolock)
        WHERE PRCo = @prco and Employee = @employee and EDLType = @edltype and EDLCode = @edlcode
 			and ((PREndDate > @prenddate) or (PREndDate = @prenddate and PaySeq > @pseq))
        	and OldMth between @beginmth and @endmth
--end 137971        	    

        -- calculate ytd amt as accums + net from current and earlier Pay Pds - old from later Pay Pds
        select @amt = @a1 + (@a2 - @a3) - @a4
     	
 		-- get minimum rate for YTD update 
 	    select @rate = isnull(min(Rate),0)
 	    from dbo.bPRSX with (nolock)
 	    where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
 	    	and PaySeq = @pseq and Type = @edltype and Code = @code
 	
        -- update check stub detail with year-to-date amount
        update dbo.bPRSX
      	set Amt3 = Amt3 + @amt
  		where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
			and Employee = @employee and PaySeq = @pseq and Type = @edltype	and Code = @code and Rate = @rate
		if @@rowcount = 0
			insert dbo.bPRSX (PRCo, PRGroup, PREndDate, Employee, PaySeq, Type, Code, Rate,
				Description, Amt1, Amt2, Amt3)
  		    values (@prco, @prgroup, @prenddate, @employee, @pseq, @edltype, @code,
  			    @rate, @description, 0, 0, @amt)
     
     	goto EDL_loop	-- get next Earnings, Deduction, or Liability code
     
     	EDL_end:
			close bcEDL
            deallocate bcEDL
            select @openEDL = 0
    
    -- #25504 remove zero entries from stub detail 
    DELETE dbo.bPRSX
    WHERE	PRCo = @prco and 
			PRGroup = @prgroup and 
			PREndDate = @prenddate and 
			Employee = @employee and 
			PaySeq = @pseq and 
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
			@yearbeginmth = @beginmth,
			@payseq = @pseq,
			@msg = @msg OUTPUT

	IF @rcode <> 0 GOTO vspexit     
     
	goto PaySeq_loop    -- next Employee/Pay Sequence
     
    PaySeq_end:	-- finished processing
		
vspexit:
	if @openPaySeq = 1
  		begin
  		close bcPaySeq
  		deallocate bcPaySeq
  		end
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

return @rcode
     



GO
GRANT EXECUTE ON  [dbo].[vspPRDirectDepositStubProcess] TO [public]
GO
