SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE       procedure [dbo].[bspPRCheckProcess]
 /***********************************************************
 * CREATED BY: EN 3/24/98
 * MODIFIED By: GG 03/19/99
 *              GG 11/08/99 - Fixed to handle 0.00 earnings
 *              GG 01/07/99 -  fixed to use current CM Acct from PR Group
 *              EN 01/17/00 - Fixed to allow CM Acct override passed from PRCheckPrint form
 *              EN 2/3/00 - If printing in job/check print order and printing all, include
 *                          checks for employees with no job/check print order flag in bPREH
 *              GG 08/08/00 - cleanup for performance, removed long running transaction
 *              EN 9/7/00 - Fixed error which happened when routine to find YTD adjustment amount
 *                          was coming up with a null and trying to write that to PRSX.  (issue #9969)
 *              GH 12/29/00 - Changed YTD to pull by PaidMth not PREndDate
 *              EN 1/3/01 - issue #11719 - fix to avoid duplicate check #'s
 *              GG 01/29/01 - removed bPRSQ.InUse
 *              GG 04/05/01 - changed where clause used when printing in Job/Employee or Check Sort/Employee order (#12917)
 *              GG 06/13/01 - fixed where clause when printing in Job/Employee order #12917
 *				EN 12/12/01 - #13644 - show ytd next to the lower of 2 rates for the same earnings code
 *				EN 2/25/02 - issue 15826 - changed bcEDL cursor to pull from bPRDT based on PREndDate rather than EndDate year
 *				EN 9/03/02 - issue 16395 - when sort by job, order non-job checks in check sort sequence
 *				EN 10/7/02 - issue 18877 change double quotes to single
 *				EN 12/31/02 - issue 18016 - do not include hrs/rate on earnings codes set up with method 'A'
 *				EN 12/31/02 - issue 19343  do not display extra earnings rows due to equipment attachment postings
 *				MV 03/05/03 - #20373 - rej 2 fix - beginchknum and endchknum need to be bigint
 *				EN 3/13/03 - issue 18016  rej 1 fix - only pass 0 hrs/rate to bPRSX not bPRSQ
 *				MV 05/29/03 - #20172 - rej 1 fix - make @chknum bigint, change 2147483647 to 9999999999
 *				EN 12/03/03 - issue 23061  added isnull check, with (nolock), and dbo
 *				EN 3/2/04 - issue 21124  add option to sort by Crew
 *				GG 3/5/04 - #23237 corrected YTD amounts 
 *				GG 5/13/04 - #23237 rejection fix - remove PR Group from 'where clause' in YTD query 
 *				GG 8/9/04 - #25504 - corrected YTD amount - removed changes for #23237, modified changes for #15826
 *				EN 10/22/04 - 25785  changed to declare @uprate as bUnitCost (was bRate) to resolve Arithmetic Overflow error when rate is over 2 digits to the left of the decimal point
 *				EN 1/18/05 - 26698  rather than use LimitMth to determine year for split month spanning 2 years, 
 *									changed to use BeginMth if MultiMth='N' or EndMth if MultiMth='Y'
 *				EN 2/9/05 - 22569  exclude SSN from PRSP insert if PRCO_ExcludeSSN flag = 'Y'
 *				GG 06/08/07 - #124797 - added override ChkSort in bPRSQ
 *				EN 3/30/2009 #129888  for Australian allowances include hours with allowances
 *				mh 02/19/2010 #137971 - modified to allow date compares to use other then calendar year.
 *				HH 03/16/2012 TK-13162 - no modification in here, just this note: 
										 the YTD amount calculation logic is replicated in dbo.vf_rptPRGetYTDAmount, 
										 once there is a change in this stored proc, it also has to be applied to that function
 *				MV 08/08/2012 TK-16945 - update Amt2 in bPRSX with bPRDT.PaybackAmt for deductions.  Update Amt3 with PaybackAmt where amount comes from bPRDT
 *				MV 08/20/2012 TK-17298 - PaybackAmt rework - insert new bPRSX rec when deduction code has a PaybackAmt.
 *				MV 09/20/2012 D-05949/TK18004 - create bPRSX for payback when PaybackOverrideYN flag = Y
 *				MV 10/25/2012 TK-18862 - Initialize @PaybackOverrideYN flag to 'N'
 *				EN 1/17/2013 D-06530/#142769/TK-20813 replaced code to locate YTD leave usage amount with call to 
 *							 stored proc vspPRGetLeaveAccumsForPayStubs ... this resolves issue and normalizes code
 *							 that was repeated in 3 places
 *
 * USAGE:
 * Process check information in preparation for printing checks.
 * Check stub values are written to bPRSP (header) and bPRSX (detail)
 * Payment information is updated to bPRSQ.
 * An error is returned if anything goes wrong, or if an eligible employee/
 * check sequence is skipped.
 *
 * INPUT PARAMETERS
 *   @PRCo		    PR Co#
 *   @PRGroup		PR Group being paid
 *   @PREndDate		Pay Period ending date
 *   @PaidDate  	Date of payment
 *   @PaidMth   	Month of payment
 *   @PaySeq		Payment sequence # (optional)
 *   @SortOpt   	Check sort order (N=Name, E=Employee#, J=Job, C=Employee Check Sort)
 *   @BeginSort 	Beginning SortName
 *   @EndSort		Ending SortName
 *   @BeginEmpl 	Beginning Employee number
 *   @EndEmpl		Ending Employee number
 *   @BeginJCCo		Beginning JC company number
 *   @EndJCCo		Ending JC company number
 *   @BeginJob		Beginning Job number
 *   @EndJob		Ending Job number
 *   @BeginChkOrd	Beginning Check Print Order
 *   @EndChkOrd		Ending Check Print Order
 *	  @BeginCrew	Beginning Crew
 *   @EndCrew		Ending Crew
 *   @BeginChkNum	Beginning check number
 *   @EndChkNum		Ending check number
 *   @OverCMAcct    CM Account override
 *
 * OUTPUT PARAMETERS
 *   @LastChkNum	Last check number actually assigned
 *   @NeedMoreChks	'Y' if need to select more checks to finish printing
 *   @msg      		error message if error occurs
 *
 * RETURN VALUE
 *   0   success
 *   1   fail
 *   5	 could not print all checks (@msg returned)
 *******************************************************************/
      (@PRCo bCompany, @PRGroup bGroup, @PREndDate bDate, @PaidDate bDate, @PaidMth bMonth,
      @PaySeq tinyint, @SortOpt bYN, @BeginSort bSortName, @EndSort bSortName, @BeginEmpl bEmployee,
      @EndEmpl bEmployee, @BeginJCCo bCompany, @EndJCCo bCompany, @BeginJob bJob, @EndJob bJob,
      @BeginChkOrd varchar(10), @EndChkOrd varchar(10), @BeginCrew varchar(10), @EndCrew varchar(10),
 	 @BeginChkNum bigint, @EndChkNum bigint, @OverCMAcct bCMAcct, @LastChkNum bigint output, 
 	 @NeedMoreChks varchar(1) output, @msg varchar(90) output)
  as
     
     set nocount on
     
     declare @rcode tinyint, @employee bEmployee, @pseq tinyint, @cmco bCompany, @cmacct bCMAcct,
     @paymethod varchar(1), @lastname varchar(30), @firstname varchar(30), @midname varchar(15),
     @sortname bSortName, @address varchar(60), @city varchar(30), @state varchar(2),
     @zip varchar(12), @ssn varchar(11), @jcco bCompany, @job bJob, @chksort varchar(10),
     @cmrf bCMRef, @lowref bCMRef, @cmrefseq tinyint, @chknum bigint, @checknumstring bCMRef,
     @edltype varchar(1), @edlcode bEDLCode, @rc tinyint, @rate bUnitCost, @hrs bHrs, @amt bDollar,
     @ttlhrs bHrs, @ttlearned bDollar, @ttldedns bDollar, @crew varchar(10), @uprate bUnitCost, @uphrs bHrs,
     @a1 bDollar, @a2 bDollar, @a3 bDollar, @a4 bDollar,@PaybackAmt bDollar, @PaybackOverrideYN bYN,@DefaultCountry Char(2)
     
     
     declare @openPaySeq tinyint, @openEDL tinyint, @openTimecard tinyint, @openAddon tinyint,
      @earnamt bDollar, @dednamt bDollar, @processed bYN, @fedcode bEDLCode, @code varchar(10),
      @description varchar(30), @filestatus varchar(1), @exempts tinyint, @useover bYN,
      @overamt bDollar,
      @beginmth bMonth, @endmth bMonth, @status tinyint, @method char(1) /*issue 18016*/
     
	 --#129888 Australian allowances
	 declare @routine varchar(10)

--137971
	declare @yearendmth tinyint, @accumbeginmth bMonth, @accumendmth bMonth

	select @yearendmth = case h.DefaultCountry when 'AU' then 6 else 12 end
	from bHQCO h with (nolock) 
	where h.HQCo = @PRCo

	exec vspPRGetMthsForAnnualCalcs @yearendmth, @PaidMth, @accumbeginmth output, @accumendmth output, @msg output
-- end  137971

     select @rcode = 0, @NeedMoreChks = 'N', @DefaultCountry = dbo.vfGetHQCODefaultCountry(@PRCo) --TK20207 
     
      -- validate input parameters
      if @PRCo is null
      	begin
          select @msg = 'Missing PR Company number!', @rcode = 1
          goto bspexit
         	end
      if @PRGroup is null
      	begin
      	select @msg = 'Missing PR Group!', @rcode = 1
      	goto bspexit
      	end
      if @PREndDate is null
      	begin
      	select @msg = 'Missing Pay Period Ending Date!', @rcode = 1
      	goto bspexit
      	end
      if @PaidDate is null
      	begin
      	select @msg = 'Missing Paid Date!', @rcode = 1
      	goto bspexit
      	end
      if @PaidMth is null
      	begin
      	select @msg = 'Missing Paid Month!', @rcode = 1
      	goto bspexit
      	end
      if @SortOpt is null
          begin
      	select @msg = 'Missing Check sort option!', @rcode = 1
      	goto bspexit
      	end
     
      -- validate Pay Period
      select @beginmth = BeginMth, @endmth = EndMth, @status = Status
      from bPRPC
      where PRCo = @PRCo and PRGroup = @PRGroup and PREndDate = @PREndDate
      if @@rowcount = 0
      	begin
      	select @msg = 'Pay Period does not exist!', @rcode = 1
      	goto bspexit
      	end
      if @status <> 0
          begin
          select @msg = 'Pay Period must be open!', @rcode = 1
          goto bspexit
          end
      -- make sure Paid Mth equals Pay Period beginning or ending month
      if @PaidMth <> @beginmth and @PaidMth <> isnull(@endmth,@beginmth)
      	begin
      	select @msg =  'Paid Month must be ' + substring(convert(varchar(8),@beginmth,3),4,5)
      	if @endmth is not null select @msg = isnull(@msg,'') + ' or ' + substring(convert(varchar(8),@endmth,3),4,5)
      	select @rcode = 1
      	goto bspexit
      	end
      -- validate Check Sort option
    
      if @SortOpt<>'N' and @SortOpt<>'E' and @SortOpt<>'J' and @SortOpt<>'C' and @SortOpt<>'W'
      	begin
      	select @msg = 'Invalid sort order.  Must be N, E, J, C, or W!', @rcode = 1
      	goto bspexit
      	end
      -- validate Check # range
      if @BeginChkNum is null
      	begin
      	select @msg = 'Missing beginning check number!', @rcode = 1
      	goto bspexit
      	end
      if @EndChkNum is null
      	begin
      	select @msg = 'Missing ending check number!', @rcode = 1
    
      	goto bspexit
      	end
      if @BeginChkNum > @EndChkNum
          begin
          select @msg = 'Ending Check # must be greater than Beginning Check #!', @rcode = 1
          goto bspexit
          end
     
      -- get default CM Co# and CM Account for the PR Group
      select @cmco = CMCo, @cmacct = CMAcct
      from dbo.bPRGR with (nolock)
      where PRCo = @PRCo and PRGroup = @PRGroup
      if @@rowcount = 0
          begin
      	select @msg = 'Invalid PR Group!', @rcode = 1
      	goto bspexit
      	end
     
      if @OverCMAcct is not null select @cmacct = @OverCMAcct -- use override CM Acct
     
      -- validate CM Account
      if not exists(select * from dbo.bCMAC with (nolock) where CMCo = @cmco and CMAcct = @cmacct)
          begin
          select @msg = 'Invalid CM Account:' + convert(varchar(6),@cmacct), @rcode = 1
          goto bspexit
          end
     
      /* look for existing check numbers in range provided */
      -- get lowest check # for the Pay Period within range
      select @lowref = min(CMRef)
      from dbo.bPRSQ with (nolock)
      where /*PRCo = @PRCo and PRGroup = @PRGroup and PREndDate = @PREndDate -- removed in order to resolve issue #11719
          and*/ CMCo = @cmco and CMAcct = @cmacct and PayMethod = 'C'
          and CASE WHEN isNumeric(CMRef) = 1 THEN convert(float,CMRef) ELSE 0 END >= @BeginChkNum
      	and CASE WHEN isNumeric(CMRef) = 1 THEN convert(float,CMRef) ELSE 9999999999 END <= @EndChkNum
     
      if @lowref is null select @lowref = '9999999999'    -- nothing found within range
     
      -- get lowest check # from unprocessed Voids
      select @cmrf = min(CMRef)
     from dbo.bPRVP with (nolock)
      where PRCo = @PRCo and CMCo = @cmco and CMAcct = @cmacct and PayMethod = 'C' and Reuse = 'N'
          and CASE WHEN isNumeric(CMRef) = 1 THEN convert(float,CMRef) ELSE 0 END >= @BeginChkNum
      	and CASE WHEN isNumeric(CMRef) = 1 THEN convert(float,CMRef) ELSE 9999999999 END <= @EndChkNum
     
      if @cmrf is null select @cmrf = '9999999999'    -- nothing found within range
     
      if convert(float,@cmrf) < convert(float,@lowref) select @lowref = @cmrf -- use lower of the two
     
      -- get lowest check # from PR Payment History
      select @cmrf = min(CMRef)
      from dbo.bPRPH with (nolock)
      where PRCo = @PRCo and CMCo = @cmco and CMAcct = @cmacct and PayMethod = 'C'
          and CASE WHEN isNumeric(CMRef) = 1 THEN convert(float,CMRef) ELSE 0 END >= @BeginChkNum
      	and CASE WHEN isNumeric(CMRef) = 1 THEN convert(float,CMRef) ELSE 9999999999 END <= @EndChkNum
     
      if @cmrf is null select @cmrf = '9999999999'    -- nothing found within range
     
      if convert(float,@cmrf) < convert(float,@lowref) select @lowref = @cmrf -- use lowest
     
      -- get lowest check # from CM Detail
      select @cmrf=min(CMRef)
      from dbo.bCMDT with (nolock)
      where CMCo = @cmco and CMAcct = @cmacct and CMTransType = 1
          and CASE WHEN isNumeric(CMRef) = 1 THEN convert(float,CMRef) ELSE 0 END >= @BeginChkNum
       	and CASE WHEN isNumeric(CMRef)=1 THEN convert(float,CMRef) ELSE 9999999999 END <= @EndChkNum
     
      if @cmrf is null select @cmrf = '9999999999'    -- nothing found within range
     
      if convert(float,@cmrf) < convert(float,@lowref) select @lowref = @cmrf -- use lowest
     
      -- see if any checks found within range
      if convert(float,@lowref) < 9999999999
          begin
      	select @msg = 'Check numbers in use within this range starting at check number ' + ltrim(@lowref) + '.', @rcode = 1
      	goto bspexit
      	end
     
      -- get Federal Tax deduction - used for filing status and # of exemptions
      select @fedcode = TaxDedn
      from dbo.bPRFI with (nolock)
      where PRCo = @PRCo
     
      -- set current check #
      select @chknum = @BeginChkNum - 1
     
      -- initialize cursor on Payment Sequence based on Sort Option - include all unpaid employees to be paid by check
      if @SortOpt = 'N' -- Employee Sort Name
      	declare bcPaySeq cursor for
      	select e.SortName, s.Employee, s.PaySeq, s.PayMethod, s.Processed,
      	e.LastName, e.FirstName, e.MidName, e.Address, e.City, e.State, e.Zip,
      	(case when c.ExcludeSSN='N' then e.SSN else '' end), e.JCCo, e.Job, isnull(s.ChkSort,e.ChkSort), e.Crew
      	from dbo.bPRSQ s with (nolock)
      	join dbo.bPREH e with (nolock) on e.PRCo=s.PRCo and e.Employee=s.Employee
    	join dbo.bPRCO c with (nolock) on c.PRCo=s.PRCo
      	where s.PRCo = @PRCo and s.PRGroup = @PRGroup and s.PREndDate = @PREndDate and s.PaySeq = isnull(@PaySeq,s.PaySeq)
              and s.CMRef is null and s.PayMethod = 'C' and s.ChkType = 'C'
      	    and e.SortName >= isnull(@BeginSort,'') and e.SortName <= isnull(@EndSort,'~~~~~~~~~~~~~~~')
      	order by e.SortName, s.Employee, s.PaySeq
     
      if @SortOpt = 'E' -- Employee #
      	declare bcPaySeq cursor for
      	select e.SortName, s.Employee, s.PaySeq, s.PayMethod, s.Processed,
      	e.LastName, e.FirstName, e.MidName, e.Address, e.City, e.State, e.Zip,
      	(case when c.ExcludeSSN='N' then e.SSN else '' end), e.JCCo, e.Job, isnull(s.ChkSort,e.ChkSort), e.Crew
      	from dbo.bPRSQ s with (nolock)
      	join dbo.bPREH e with (nolock) on e.PRCo=s.PRCo and e.Employee=s.Employee
    	join dbo.bPRCO c with (nolock) on c.PRCo=s.PRCo
      	where s.PRCo = @PRCo and s.PRGroup = @PRGroup and s.PREndDate = @PREndDate and s.PaySeq = isnull(@PaySeq,s.PaySeq)
              and s.CMRef is null and s.PayMethod = 'C' and s.ChkType = 'C'
      	    and s.Employee >= isnull(@BeginEmpl,0) and s.Employee <= isnull(@EndEmpl,999999)
      	order by s.Employee, s.PaySeq
     
      if @SortOpt='J' -- Job and Employee # - not all restrictions exist in where clause
      	declare bcPaySeq cursor for
      	select e.SortName, s.Employee, s.PaySeq, s.PayMethod, s.Processed,
      	   	e.LastName, e.FirstName, e.MidName, e.Address, e.City, e.State, e.Zip, 
    		(case when c.ExcludeSSN='N' then e.SSN else '' end), e.JCCo, e.Job, isnull(s.ChkSort,e.ChkSort), e.Crew
      	from dbo.bPRSQ s with (nolock)
      	join dbo.bPREH e with (nolock) on e.PRCo=s.PRCo and e.Employee=s.Employee
    	join dbo.bPRCO c with (nolock) on c.PRCo=s.PRCo
      	where s.PRCo = @PRCo and s.PRGroup = @PRGroup and s.PREndDate = @PREndDate and s.PaySeq = isnull(@PaySeq,s.PaySeq)
              and s.CMRef is null and s.PayMethod = 'C' and s.ChkType = 'C'
      	    and isnull(e.JCCo,0) >= isnull(@BeginJCCo,0) and isnull(e.JCCo,0) <= isnull(@EndJCCo,255)
      	order by e.JCCo, e.Job, isnull(s.ChkSort,e.ChkSort), /*issue 16393*/ s.Employee, s.PaySeq
     
     
      if @SortOpt = 'C' -- Employee Check Sort for a range
      	declare bcPaySeq cursor  for
      	select e.SortName, s.Employee, s.PaySeq, s.PayMethod, s.Processed,
      	e.LastName, e.FirstName, e.MidName, e.Address, e.City, e.State, e.Zip,
      	(case when c.ExcludeSSN='N' then e.SSN else '' end), e.JCCo, e.Job, isnull(s.ChkSort,e.ChkSort), e.Crew
      	from dbo.bPRSQ s with (nolock)
      	join dbo.bPREH e with (nolock) on e.PRCo=s.PRCo and e.Employee=s.Employee
    	join dbo.bPRCO c with (nolock) on c.PRCo=s.PRCo
      	where s.PRCo = @PRCo and s.PRGroup = @PRGroup and s.PREndDate = @PREndDate and s.PaySeq = isnull(@PaySeq,s.PaySeq)
              and s.CMRef is null and s.PayMethod = 'C' and s.ChkType = 'C'
      	    and coalesce(s.ChkSort,e.ChkSort,'') >= isnull(@BeginChkOrd,'') and coalesce(s.ChkSort,e.ChkSort,'') <= isnull(@EndChkOrd,'~~~~~~~~~~')
      	order by isnull(s.ChkSort,e.ChkSort), s.Employee, s.PaySeq
     
      if @SortOpt = 'W' -- issue 21124 Crew for a range
      	declare bcPaySeq cursor  for
      	select e.SortName, s.Employee, s.PaySeq, s.PayMethod, s.Processed,
      	e.LastName, e.FirstName, e.MidName, e.Address, e.City, e.State, e.Zip,
      	(case when c.ExcludeSSN='N' then e.SSN else '' end), e.JCCo, e.Job, isnull(s.ChkSort,e.ChkSort), e.Crew
      	from dbo.bPRSQ s with (nolock)
      	join dbo.bPREH e with (nolock) on e.PRCo=s.PRCo and e.Employee=s.Employee
    	join dbo.bPRCO c with (nolock) on c.PRCo=s.PRCo
      	where s.PRCo = @PRCo and s.PRGroup = @PRGroup and s.PREndDate = @PREndDate and s.PaySeq = isnull(@PaySeq,s.PaySeq)
              and s.CMRef is null and s.PayMethod = 'C' and s.ChkType = 'C'
      	    and isnull(e.Crew,'') >= isnull(@BeginCrew,'') and isnull(e.Crew,'') <= isnull(@EndCrew,'~~~~~~~~~~')
      	order by e.Crew, isnull(s.ChkSort,e.ChkSort), s.Employee, s.PaySeq
     
      open bcPaySeq
      select @openPaySeq = 1      -- set open cursor flag
     
      -- process each row in cursor
      PaySeq_loop:
      	fetch next from bcPaySeq into @sortname, @employee, @pseq, @paymethod, @processed,
      	   @lastname, @firstname, @midname, @address, @city, @state, @zip, @ssn, @jcco, @job, @chksort, @crew
     
          if @@fetch_status <> 0 goto PaySeq_end
     
          if @SortOpt = 'J'   -- apply Job/Employee sort restrictions - include all Employees within Job range
              begin
              if isnull(@jcco,0) = isnull(@BeginJCCo,0) and isnull(@job,'') < isnull(@BeginJob,'') goto PaySeq_loop
              if isnull(@jcco,0) = isnull(@BeginJCCo,0) and isnull(@job,'') = isnull(@BeginJob,'')
                  and @employee < isnull(@BeginEmpl,0) goto PaySeq_loop
              if isnull(@jcco,0) = isnull(@EndJCCo,255) and isnull(@job,'') > isnull(@EndJob,'~~~~~~~~~~') goto PaySeq_loop
              if isnull(@jcco,0) = isnull(@EndJCCo,255) and isnull(@job,'') = isnull(@EndJob,'~~~~~~~~~~')
                  and @employee > isnull(@EndEmpl,999999) goto PaySeq_loop
     
              end
     
          if @SortOpt = 'C'   -- apply Check Order/Employee # restrictions - include all Employees within Check Order range
              begin
              if isnull(@chksort,'') = isnull(@BeginChkOrd,'') and @employee < isnull(@BeginEmpl,0) goto PaySeq_loop
              if isnull(@chksort,'') = isnull(@EndChkOrd,'~~~~~~~~~~') and @employee > isnull(@EndEmpl,999999) goto PaySeq_loop
              end
     
          if @SortOpt = 'W'   -- issue 21124 apply Crew/Employee # restrictions - include all Employees within Check Order range
              begin
              if isnull(@crew,'') = isnull(@BeginCrew,'') and @employee < isnull(@BeginEmpl,0) goto PaySeq_loop
              if isnull(@crew,'') = isnull(@EndCrew,'~~~~~~~~~~') and @employee > isnull(@EndEmpl,999999) goto PaySeq_loop
              end
     
          -- make sure Employee has been processed, is not is use, or has timecards in a batch
          if @processed <> 'Y' or
          exists(select * from dbo.bPRTB b with (nolock)
                  join dbo.HQBC c with (nolock) on c.Co = b.Co and c.Mth = b.Mth and c.BatchId = b.BatchId
      	  		where b.Co = @PRCo and b.Employee = @employee and b.PaySeq = @pseq
      			and c.PRGroup = @PRGroup and c.PREndDate = @PREndDate)
              begin
      	    select @rcode = 5  -- some eligible Employee's have been skipped
      	    goto PaySeq_loop
      	    end
     
          -- make sure Employee/Pay Seq needs a check - get total earnings
          select @earnamt = isnull(sum(Amount),0)
          from dbo.bPRDT with (nolock)
          where PRCo = @PRCo and PRGroup = @PRGroup and PREndDate = @PREndDate
              and Employee = @employee and PaySeq = @pseq and EDLType = 'E'
          -- get total deductions
          select @dednamt = isnull(sum( case UseOver when 'Y' then OverAmt else Amount end),0)
          from dbo.bPRDT with (nolock)
          where PRCo = @PRCo and PRGroup = @PRGroup and PREndDate = @PREndDate
              and Employee = @employee and PaySeq = @pseq and EDLType = 'D'
     
          -- only assign check# if net pay is => 0.00 and total earnings and deductions are not 0.00
          -- skip if net pay is negative
          if @earnamt - @dednamt < 0 goto PaySeq_loop
          -- skip if earnings and dedns are both 0.00
          if @earnamt = 0 and @dednamt = 0 goto PaySeq_loop
     
          -- get next check number and make sure it's within the range
      	select @chknum = @chknum + 1
      	if @chknum > @EndChkNum
              begin
      		select @msg = isnull(@msg,'') + 'Please select additional check numbers to complete check print.'
              select @NeedMoreChks = 'Y', @LastChkNum = @chknum - 1   -- pass back flag and last printed check#
      		goto bspexit
      		end
     
          -- check # will be assigned, right justify check #
          select @checknumstring = space(10-datalength(convert(varchar(10),@chknum))) + convert(varchar(10),@chknum)
     
          -- initialize totals
      	select @ttlhrs = 0, @ttlearned = 0, @ttldedns = 0
     
          -- get Employee Federal filing status and exemptions
          select @filestatus = null, @exempts = null
          select @filestatus = FileStatus, @exempts = RegExempts
          from dbo.bPRED with (nolock)
          where PRCo = @PRCo and Employee = @employee and DLCode = @fedcode
     
           -- add check stub header
          insert dbo.bPRSP (PRCo, PRGroup, PREndDate, Employee, PaySeq, PayMethod, CMRef, PaidDate,
              LastName, FirstName, MidName, Address, City, State, Zip, SSN, FileStatus, Exempts,
              SortName, ChkSort, JCCo, Job, SortOrder, Crew)
      	values (@PRCo, @PRGroup, @PREndDate, @employee, @pseq, @paymethod, @checknumstring, @PaidDate,
              @lastname, @firstname, @midname, @address, @city, @state, @zip, @ssn, @filestatus, @exempts,
      		@sortname, @chksort, @jcco, @job, @SortOpt, @crew)
     
      	-- find all earnings, deductions, and liabilities to include on stub
     
          -- initialize a cursor on PR Detail Totals and Employee Accums for all E/D/Ls processed within the year
      	declare bcEDL cursor for

/*137971      	
          select distinct EDLType, EDLCode
      	from dbo.bPRDT d with (nolock)
    	join dbo.bPRSQ s with (nolock) on s.PRCo = d.PRCo and s.PRGroup = d.PRGroup and s.PREndDate = d.PREndDate
    		and s.Employee = d.Employee
       	where d.PRCo = @PRCo and d.PRGroup = @PRGroup and d.Employee = @employee
    		 and ((d.PREndDate = @PREndDate and d.PaySeq <= @pseq) -- #25504 - exclude codes in later pay seq#s
    		or (datepart(year,s.PaidMth)=datepart(year,@PaidMth))) -- #25505 - include all codes paid in this year
      	union
      	select distinct EDLType, EDLCode
      	from dbo.bPREA with (nolock)
      	where PRCo = @PRCo and Employee = @employee
              and datepart(year,Mth) = datepart(year,@PaidMth)
      	order by EDLType, EDLCode
*/     

          select distinct EDLType, EDLCode
      	from dbo.bPRDT d with (nolock)
    	join dbo.bPRSQ s with (nolock) on s.PRCo = d.PRCo and s.PRGroup = d.PRGroup and s.PREndDate = d.PREndDate
    		and s.Employee = d.Employee
       	where d.PRCo = @PRCo and d.PRGroup = @PRGroup and d.Employee = @employee
    		 and ((d.PREndDate = @PREndDate and d.PaySeq <= @pseq) -- #25504 - exclude codes in later pay seq#s
    		or s.PaidMth between @accumbeginmth and @accumendmth) -- #25505 - include all codes paid in this year
      	union
      	select distinct EDLType, EDLCode
      	from dbo.bPREA with (nolock)
      	where PRCo = @PRCo and Employee = @employee
              and Mth between @accumbeginmth and @accumendmth
      	order by EDLType, EDLCode
--end 137971
      	
      	open bcEDL
          select @openEDL = 1     -- set open cursor flag
     
      	EDL_loop:     -- process each earnings, deduction, and liability code
              fetch next from bcEDL into @edltype, @edlcode
     
      	    if @@fetch_status <> 0 goto EDL_end
     
              -- skip Liab if not to be printed for this PR Group
              if @edltype = 'L' and not exists (select top 1 1 from dbo.bPRGB with (nolock) where PRCo = @PRCo
                  and PRGroup = @PRGroup and LiabCode = @edlcode) goto EDL_loop
     
              -- right justify code for stub detail
              select @code = space(10-datalength(convert(varchar(10),@edlcode))) + convert(varchar(10),@edlcode)
     
              -- process dedns and liabs
              if @edltype in ('D','L')
      	  	  BEGIN
                  -- get d/l description
     			select @description = 'Invalid'
      		    select @description = Description
                 from dbo.bPRDL with (nolock)
                 where PRCo = @PRCo and DLCode = @edlcode
                 
     
                -- get current Pay Period and Seq amount - TK-17298 get payback amount for Arrears/Payback
     			SELECT @amt = 0
     			SELECT @PaybackAmt = 0
     			SELECT @PaybackOverrideYN = 'N'
                SELECT	@amt = (CASE WHEN UseOver='Y' THEN OverAmt ELSE Amount END),
						@PaybackAmt = (CASE WHEN PaybackOverYN='Y' THEN PaybackOverAmt ELSE PaybackAmt END),
						@PaybackOverrideYN = PaybackOverYN 
                FROM dbo.bPRDT WITH (nolock)
      	  	 	WHERE PRCo = @PRCo and PRGroup = @PRGroup and PREndDate = @PREndDate
                      and Employee = @employee and PaySeq = @pseq and EDLType = @edltype and EDLCode = @edlcode
     
                  -- update check stub detail, Amt2 = current amt, Amt3 = year-to-date amt 	
                UPDATE dbo.bPRSX
      			SET Amt2 = Amt2 + @amt
      			WHERE PRCo = @PRCo and PRGroup = @PRGroup and PREndDate = @PREndDate and Employee = @employee
                      and PaySeq = @pseq and Type = @edltype and Code = @code and Rate = 0
                IF @@ROWCOUNT = 0
                BEGIN
					INSERT dbo.bPRSX 
						(
							PRCo, PRGroup, PREndDate, Employee, PaySeq, Type, Code, Rate,Description, Amt1, Amt2, Amt3
						)
      			    VALUES
      					(
      						@PRCo, @PRGroup, @PREndDate, @employee, @pseq, @edltype, @code, 0,@description, 0, @amt, 0
      					)
                END
     
                -- accumulate total deductions - 17298 accum PaybackAmt in total deductions
     		    IF @edltype = 'D' SELECT @ttldedns = @ttldedns + @amt + @PaybackAmt 
     		    
     		    --  Update/Create bPRSX record for PaybackAmt TK-17298
     		    IF (@PaybackAmt <> 0) OR (@PaybackOverrideYN = 'Y') --TK-18004 create PRSX payback if override = Y
     		    BEGIN
     				UPDATE dbo.bPRSX
      				SET Amt2 = Amt2 + @PaybackAmt
      				WHERE PRCo = @PRCo and PRGroup = @PRGroup and PREndDate = @PREndDate and Employee = @employee
						  and PaySeq = @pseq and Type = @edltype and Code = @code and Rate = .99999
					IF @@ROWCOUNT = 0
					BEGIN
     					INSERT dbo.bPRSX 
							(
								PRCo, PRGroup, PREndDate, Employee, PaySeq, Type, Code, Rate,Description, Amt1, Amt2, Amt3
							)
      					VALUES
      						(
      							@PRCo, @PRGroup, @PREndDate, @employee, @pseq, @edltype, @code, .99999, 'Payback - ' + LEFT(@description,20), 0, @PaybackAmt, 0
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
      		 	where PRCo = @PRCo and EarnCode = @edlcode
     
     			-- initialize cursor to get current earnings from PR Timecards
                 declare bcTimecard cursor for
      			select Rate, convert(numeric(10,2),sum(Hours)), convert(numeric(12,2),sum(Amt))
                 from dbo.bPRTH with (nolock)
      			where PRCo = @PRCo and PRGroup = @PRGroup and PREndDate = @PREndDate
      				and Employee = @employee and PaySeq = @pseq and EarnCode = @edlcode
      			group by Rate
     
      		 	open bcTimecard
                 select @openTimecard = 1      -- set open cursor flag
     
      		    Timecard_loop:        -- process each set of Timecards grouped by Rate
                     fetch next from bcTimecard into @rate, @hrs, @amt
     
                     if @@fetch_status <> 0 goto Timecard_end
     
     				-- #19343 - skip if hours, rate and amount are 0
     				if @rate = 0 and @hrs = 0 and @amt = 0 goto Timecard_loop
     
     				-- if amount based earnings use 0.00 hrs and rate 
     				select @uphrs = @hrs, @uprate = @rate
     				if @method = 'A' select @uphrs = 0, @uprate = 0	
     
     	    		-- update or add earnings to PR Stub Detail
     	            update dbo.bPRSX
     	    		set Amt1 = Amt1 + @uphrs, Amt2 = Amt2 + @amt
     	    		where PRCo = @PRCo and PRGroup = @PRGroup and PREndDate = @PREndDate
     	    			and Employee = @employee and PaySeq = @pseq and Type = 'E' and Code = @code and Rate = @uprate
     	            if @@rowcount = 0
     	                insert dbo.bPRSX (PRCo, PRGroup, PREndDate, Employee, PaySeq, Type, Code, Rate,
     	                    Description, Amt1, Amt2, Amt3)
     	                values (@PRCo, @PRGroup, @PREndDate, @employee, @pseq, 'E', @code, @uprate,
     	                    @description, @uphrs, @amt, 0)
     
                      -- accumulate total hours and earnings
                      select @ttlhrs = @ttlhrs + @hrs, @ttlearned = @ttlearned + @amt
     
                      goto Timecard_loop  -- next group of Timecards
     
     			Timecard_end:
      		        close bcTimecard
      		        deallocate bcTimecard
      		        select @openTimecard = 0
     
     			-- initialize cursor to get add-on earnings by rate
                DECLARE bcAddon cursor for
      			SELECT Rate, convert(numeric(12,2),sum(Amt))
                FROM dbo.bPRTA with (nolock)
      			WHERE PRCo = @PRCo and PRGroup = @PRGroup and PREndDate = @PREndDate
                      and Employee = @employee and PaySeq = @pseq and EarnCode = @edlcode
      			GROUP BY Rate
     
      		    OPEN bcAddon
                SELECT @openAddon = 1      -- set open cursor flag
     
      		    Addon_loop:    -- process each Addon Earnings Code by Rate
                    FETCH NEXT FROM bcAddon INTO @rate, @amt
     
                    IF @@fetch_status <> 0 goto Addon_end
     
					--#129888 for Australian allowances determine hours and clear rate so that it does not display on check
					SELECT @uphrs = 0
					IF @routine = 'Allowance' or @routine = 'AllowRDO' 
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
     	    		WHERE PRCo = @PRCo and PRGroup = @PRGroup and PREndDate = @PREndDate
     	    			and Employee = @employee and PaySeq = @pseq and Type = 'E' and Code = @code and Rate = @rate
     	            IF @@ROWCOUNT = 0
     	            INSERT dbo.bPRSX 
     								(
     									PRCo, PRGroup, PREndDate, Employee, PaySeq, Type, Code, Rate,
     	                				Description, Amt1, Amt2, Amt3
     	                			)
     	            VALUES 
     						(
     							@PRCo, @PRGroup, @PREndDate, @employee, @pseq, 'E', @code, @rate,
     							@description, @uphrs, @amt, 0
     						)
     
     				-- accumulate total earnings
                    SELECT @ttlearned = @ttlearned + @amt
     
                    GOTO Addon_loop  -- next group of Addons
     
     			Addon_end:
                    CLOSE bcAddon
      		        DEALLOCATE bcAddon
      		        SELECT @openAddon = 0
     
     			end	-- end of Earnings
     
     
     		--------- Find and update stub detail with YTD amounts - all types -------
     
     		-- get YTD amounts from Employee Accums to pull prior amounts and adjustments
/* Issue 137971     		
     		select @a1 = isnull(sum(Amount),0)
            	from dbo.bPREA with (nolock)
             where PRCo = @PRCo and Employee = @employee	and datepart(year,Mth) = datepart(year,@PaidMth)
             	and EDLType = @edltype and EDLCode = @edlcode
*/
     		select @a1 = isnull(sum(Amount),0)
            	from dbo.bPREA with (nolock)
             where PRCo = @PRCo and Employee = @employee and Mth between @accumbeginmth and @accumendmth
             	and EDLType = @edltype and EDLCode = @edlcode
--end 137971             	
             	        
             -- get current amounts from current and earlier Pay Periods where Final Accum update has not been run
/* Issue 137971             
             select @a2 = isnull(sum( case d.UseOver when 'Y' then d.OverAmt else d.Amount end),0)
             from dbo.bPRDT d with (nolock)
            	join dbo.bPRSQ s with (nolock) on s.PRCo = d.PRCo and s.PRGroup = d.PRGroup and s.PREndDate = d.PREndDate
             	and s.Employee = d.Employee and s.PaySeq = d.PaySeq
            	join dbo.bPRPC c with (nolock) on c.PRCo = d.PRCo and c.PRGroup = d.PRGroup and c.PREndDate = d.PREndDate
            	where d.PRCo = @PRCo and d.Employee = @employee	and d.EDLType = @edltype and d.EDLCode = @edlcode
            		and ((d.PREndDate < @PREndDate) or (d.PREndDate = @PREndDate and d.PaySeq <= @pseq))
            		and ((s.PaidMth is null and c.MultiMth='N' and datepart(year,c.BeginMth) = datepart(year,@PaidMth)) --26698
    				or (s.PaidMth is null and c.MultiMth='Y' and datepart(year,c.EndMth) = datepart(year,@PaidMth)) --26698
                 	or (datepart(year,s.PaidMth) = datepart(year,@PaidMth)))
            		and c.GLInterface = 'N'
*/
			 -- TK-16945 include paybackamt in ytd sum when amount is from bPRDT
             SELECT @a2 = (ISNULL(SUM( CASE d.UseOver WHEN 'Y' THEN d.OverAmt ELSE d.Amount END),0)) 
							+ (ISNULL(SUM(CASE WHEN d.PaybackOverYN='Y' THEN d.PaybackOverAmt ELSE d.PaybackAmt END),0))
             FROM dbo.bPRDT d WITH (nolock)
            	join dbo.bPRSQ s with (nolock) on s.PRCo = d.PRCo and s.PRGroup = d.PRGroup and s.PREndDate = d.PREndDate
             	and s.Employee = d.Employee and s.PaySeq = d.PaySeq
            	join dbo.bPRPC c with (nolock) on c.PRCo = d.PRCo and c.PRGroup = d.PRGroup and c.PREndDate = d.PREndDate
            WHERE d.PRCo = @PRCo and d.Employee = @employee	and d.EDLType = @edltype and d.EDLCode = @edlcode
            		and ((d.PREndDate < @PREndDate) or (d.PREndDate = @PREndDate and d.PaySeq <= @pseq))
            		and ((s.PaidMth is null and c.MultiMth='N' and c.BeginMth between @accumbeginmth and @accumendmth) --26698
    				or (s.PaidMth is null and c.MultiMth='Y' and c.EndMth between @accumbeginmth and @accumendmth) --26698
                 	or (s.PaidMth between @accumbeginmth and @accumendmth))
            		and c.GLInterface = 'N'
            		
--end 137971
            		        
     		-- get old amounts from current and earlier Pay Periods where Final Accum update has not been run
/*137971     		
            	select @a3 = isnull(sum(OldAmt),0)
            	from dbo.bPRDT d with (nolock)
            	join dbo.bPRPC c with (nolock) on c.PRCo = d.PRCo and c.PRGroup = d.PRGroup and c.PREndDate = d.PREndDate
            	where d.PRCo = @PRCo and d.Employee = @employee and d.EDLType = @edltype and d.EDLCode = @edlcode
            		and ((d.PREndDate < @PREndDate) or (d.PREndDate = @PREndDate and d.PaySeq <= @pseq))
            		and datepart(year,d.OldMth) = datepart(year,@PaidMth)
            		and c.GLInterface = 'N'
*/
				-- TK-16945 include PaybackAmt in ytd sum when oldamt is from PRDT
            	SELECT @a3 = (ISNULL(SUM(OldAmt),0)) + (ISNULL(SUM(CASE WHEN PaybackOverYN='Y' THEN PaybackOverAmt ELSE PaybackAmt END),0))
            	from dbo.bPRDT d with (nolock)
            	join dbo.bPRPC c with (nolock) on c.PRCo = d.PRCo and c.PRGroup = d.PRGroup and c.PREndDate = d.PREndDate
            	where d.PRCo = @PRCo and d.Employee = @employee and d.EDLType = @edltype and d.EDLCode = @edlcode
            		and ((d.PREndDate < @PREndDate) or (d.PREndDate = @PREndDate and d.PaySeq <= @pseq))
            		and d.OldMth between @accumbeginmth and @accumendmth
            		and c.GLInterface = 'N'
            		            		
--137971            		            		
        
             -- get old amount from later Pay Periods - need to back out of accums
/*137971             
             select @a4 = isnull(sum(OldAmt),0)
             from dbo.bPRDT with (nolock)
             where PRCo = @PRCo and Employee = @employee and EDLType = @edltype and EDLCode = @edlcode
     			and ((PREndDate > @PREndDate) or (PREndDate = @PREndDate and PaySeq > @pseq))
            		and datepart(year,OldMth) = datepart(year,@PaidMth)
*/
			-- TK-16945 include PaybackAmt in ytd sum when oldamt is from PRDT
             SELECT @a4 = (ISNULL(SUM(OldAmt),0)) + (ISNULL(SUM(CASE WHEN PaybackOverYN='Y' THEN PaybackOverAmt ELSE PaybackAmt END),0))
             FROM dbo.bPRDT WITH (NOLOCK)
             WHERE PRCo = @PRCo and Employee = @employee and EDLType = @edltype and EDLCode = @edlcode
     			and ((PREndDate > @PREndDate) or (PREndDate = @PREndDate and PaySeq > @pseq))
            		and OldMth between @accumbeginmth and @accumendmth
--137971            		
        
             -- calculate ytd amt as accums + net from current and earlier Pay Pds - old from later Pay Pds
             select @amt = @a1 + (@a2 - @a3) - @a4
     	
     		-- get minimum rate for YTD update 
     	    select @rate = isnull(min(Rate),0)
     	    from dbo.bPRSX with (nolock)
     	    where PRCo = @PRCo and PRGroup = @PRGroup and PREndDate = @PREndDate and Employee = @employee
     	    	and PaySeq = @pseq and Type = @edltype and Code = @code
     	
             -- update check stub detail with year-to-date amount
             update dbo.bPRSX
          	set Amt3 = Amt3 + @amt
      		where PRCo = @PRCo and PRGroup = @PRGroup and PREndDate = @PREndDate
             	and Employee = @employee and PaySeq = @pseq and Type = @edltype	and Code = @code and Rate = @rate
             if @@rowcount = 0
                 insert dbo.bPRSX (PRCo, PRGroup, PREndDate, Employee, PaySeq, Type, Code, Rate,
                 	Description, Amt1, Amt2, Amt3)
      		    values (@PRCo, @PRGroup, @PREndDate, @employee, @pseq, @edltype, @code,
      			    @rate, @description, 0, 0, @amt)
     
     		goto EDL_loop	-- get next Earnings, Deduction, or Liability code
     
     	EDL_end:
             close bcEDL
             deallocate bcEDL
             select @openEDL = 0
    
    		-- #25504 remove zero entries from stub detail - TK-18004 do not delete if rec is payback
    		DELETE dbo.bPRSX
    		WHERE	PRCo = @PRCo and
    				PRGroup = @PRGroup and 
    				PREndDate = @PREndDate and 
    				Employee = @employee and 
    				PaySeq = @pseq and 
    				Amt2 = 0 and 
    				Amt3 = 0 AND
    				Rate <> .99999 
    
     
      /* finished with earnings, deductions, and liabilities */
     
		-- add leave accums to check stub info
		EXEC	@rcode = [dbo].[vspPRGetLeaveAccumsForPayStubs]
				@prco = @PRCo,
				@prgroup = @PRGroup,
				@employee = @employee,
				@periodenddate = @PREndDate,
				@yearbeginmth = @accumbeginmth,
				@payseq = @pseq,
				@msg = @msg OUTPUT

		IF @rcode <> 0 GOTO bspexit     
     
          -- update payment information in PR Sequence Control
      	update dbo.bPRSQ
      	set CMAcct = @cmacct, CMRef = @checknumstring, CMRefSeq = 0, ChkType = 'C', PaidDate = @PaidDate,
              PaidMth = @PaidMth, Hours = @ttlhrs, Earnings = @ttlearned, Dedns = @ttldedns
      	where PRCo = @PRCo and PRGroup = @PRGroup and PREndDate = @PREndDate
              and Employee = @employee and PaySeq = @pseq
          if @@rowcount <> 1
              begin
      	    select @msg = 'Unable to update Check information in PR Sequence control!', @rcode = 1
      	    goto bspexit
      	    end
     
          goto PaySeq_loop    -- next Employee/Pay Sequence
     
      PaySeq_end:
          select @LastChkNum = @chknum    -- return last used check #
          if @LastChkNum = @BeginChkNum - 1 select @LastChkNum = 0    -- if no check #s assigned, return 0 as last check #
     
      bspexit:
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
GRANT EXECUTE ON  [dbo].[bspPRCheckProcess] TO [public]
GO
