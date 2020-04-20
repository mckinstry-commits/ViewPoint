SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    procedure [dbo].[bspPRUpdatePostAccums]
/***********************************************************
* CREATED BY: GG 07/13/98
* MODIFIED By : GG 09/08/98
*              GG 07/12/99  No-Pay fixes
*              MH 07/22/99  Corrected potential insert/update of PRSQ when @oldmth or @paidmth is null
*              GG 01/28/00 - Fix 'old' amts update to bPRDT - set to 0.00 if Paid Mth is null
*              GG 01/29/01 - Paid Month fixes
*				GG 03/11/02 - #16538 - Reset bPREA.AuditYN flag following update
*				EN 10/9/02 - issue 18877 change double quotes to single
*				GG 10/17/06 - #120831 use local fast_forward cursors
*				mh 2/15/07 - #127121 - Do not use OverAmt if EDLType = 'E'
*				EN 6/18/09 #129888 code to pass SubjectAmt from PRDT to PREA for Australian allowances (addons)
*				EN 10/12/2009 #134431  code to pass SubjectAmt from PRDT into PREA Hours (not SubjAmt) column for AUS allowances
*				EN 3/30/2010 #137126 added TRY...CATCH to trap SQL errors, in particular error 16943 in order to provide a more useful error message
*				EN/MV 9/18/2012 B-10153/TK-17826 added code to include potential payback/payback update amounts when post to PREA
*
* USAGE:
* Called from bspPRUpdatePostGL to perform updates to
* Employee Accumulations whenever a GL interface is run.
* Will only update Employee/Pay Seqs that have been processed and
* without unposted Timecards.
* Saves updated amounts into 'old' values within bPRDT, to
* be backed out if record is updated again.  bPRDT entries
* with 'old' values cannot be deleted until the Pay Period
* is purged.
*
* INPUT PARAMETERS
*   @prco   		PR Company
*   @prgroup  		PR Group to validate
*   @prenddate		Pay Period Ending Date
*
* OUTPUT PARAMETERS
*   @errmsg      error message if error occurs
*
* RETURN VALUE
*   0         success
*   1         failure
*****************************************************/

	(@prco bCompany, @prgroup bGroup, @prenddate bDate, @errmsg varchar(255) output)
	as

	set nocount on
   
	BEGIN TRY --#137126

		DECLARE @rcode int,					@openEmplSeq tinyint,	@employee bEmployee, @payseq tinyint, 
				@paidmth bMonth,			@edltype char(1),		@edlcode bEDLCode,	@hrs bHrs,			@amt bDollar, 
				@subjamt bDollar,			@eligamt bDollar,		@useover bYN,		@overamt bDollar,	@oldhrs bHrs, 
				@oldamt bDollar,			@oldsubj bDollar,		@oldelig bDollar,	@oldmth bMonth,		@openEmplDetail tinyint,
				@upamt bDollar,				@accumflag bYN,			@paymethod char(1),	@nopaymth bMonth,	@paybackamt bDollar,	
				@paybackoveramt bDollar,	@paybackoveryn bYN

		--#129888 for Australia
		declare @routine varchar(10)

		select @rcode = 0
	   
		-- get default Paid Month from Pay Period Control - should not be needed after issue #12097
		select @nopaymth = case MultiMth when 'Y' then EndMth else BeginMth end
		from bPRPC
		where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
		if @@rowcount = 0
		begin
			select @errmsg = 'Missing Pay Period Control entry!', @rcode = 1
			goto bspexit
		end
	   
		-- cursor on PR Employee Sequence Control table  - #120831 use local, fast_forward cursor
		-- 'unpaid' Employees are included because 'old' amounts may need to be backed out
		declare bcEmplSeq cursor local fast_forward for
		select Employee, PaySeq, PayMethod, PaidMth
		from bPRSQ
		where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
		and Processed = 'Y' -- must be Processed
	   
		open bcEmplSeq
		select @openEmplSeq = 1
	   
		next_EmplSeq:
		fetch next from bcEmplSeq into @employee, @payseq, @paymethod, @paidmth
		if @@fetch_status <> 0 goto end_EmplSeq

		-- must not have any unposted timecards
		if exists(select 1 from bPRTB b
			join bHQBC h on b.Co = h.Co and b.Mth = h.Mth and b.BatchId = h.BatchId
			join bPRPC p on p.PRCo = h.Co and p.PRGroup = h.PRGroup and p.PREndDate = h.PREndDate
			where p.PRCo = @prco and p.PRGroup = @prgroup and p.PREndDate = @prenddate
			and b.Employee = @employee and b.PaySeq = @payseq)
			goto next_EmplSeq
	   
		   -- use default Paid month if 'No-Pay' and Paid Mth is missing - should not be needed after issue #12097
		   if @paymethod = 'X' and @paidmth is null select @paidmth = @nopaymth
	   
		-- use a cursor to process all Detail Seqs for Employee/Pay Seq  - #120831 use local, fast_forward cursor
		DECLARE bcEmplDetail CURSOR LOCAL FAST_FORWARD FOR
			SELECT EDLType,		EDLCode,		[Hours],		Amount, 
				   SubjectAmt,	EligibleAmt,	UseOver,		OverAmt, 
				   OldHours,	OldAmt,			OldSubject,		OldEligible, 
				   OldMth,		PaybackAmt,		PaybackOverAmt,	PaybackOverYN
			FROM dbo.bPRDT
			WHERE PRCo = @prco AND 
				  PRGroup = @prgroup AND 
				  PREndDate = @prenddate AND 
				  Employee = @employee AND 
				  PaySeq = @payseq
	   
   		open bcEmplDetail
   		select @openEmplDetail = 1
   		next_EmplDetail:

		FETCH NEXT FROM bcEmplDetail INTO @edltype, @edlcode,		@hrs,				@amt, 
										  @subjamt, @eligamt,		@useover,			@overamt, 
										  @oldhrs,	@oldamt,		@oldsubj,			@oldelig, 
										  @oldmth,	@paybackamt,	@paybackoveramt,	@paybackoveryn
	   
		if @@fetch_status <> 0 goto end_EmplDetail

		-- determine update amount allowing for potential amount/payback overrides ... B-10153/TK-17826	
		IF @edltype = 'E'
		BEGIN
			SELECT @upamt = @amt
		END
		ELSE
		BEGIN	  
			SELECT @upamt = (CASE WHEN @useover = 'Y' THEN @overamt ELSE @amt END) +
							(CASE WHEN @paybackoveryn = 'Y' THEN @paybackoveramt ELSE @paybackamt END)
		END
	   
		-- set flag to accumulate subject and eligible amounts
		select @accumflag = 'N'
		if @edltype in ('D','L')
		begin
			select @accumflag = AccumSubjAmts
			from bPRDL	where PRCo = @prco and DLCode = @edlcode
		end

		--#129888 for Australian allowances store SubjectAmt needs to be passed to accums
		if @edltype = 'E'
			begin
			select @routine = Routine
			from bPREC where PRCo=@prco and EarnCode = @edlcode
			if @routine = 'Allowance' or @routine = 'AllowRDO'
				begin
				select @hrs = @subjamt, @oldhrs = @oldsubj --#134431 for AUS allowances, move PRDT SubjAmt to PREA Hours
				select @subjamt = 0, @oldsubj = 0 --#134431 for AUS allowances, PREA SubjAmt should be zero
				select @accumflag = 'Y'
				end
			end

		if @accumflag = 'N' select @subjamt = 0, @eligamt = 0

		begin transaction

		-- back out 'old' accums
		if @oldmth is not null
		begin
			update bPREA set Hours = Hours - @oldhrs, Amount = Amount - @oldamt, SubjectAmt = SubjectAmt - @oldsubj,
			EligibleAmt = EligibleAmt - @oldelig, AuditYN = 'N'
			where PRCo = @prco and Employee = @employee and Mth = @oldmth and EDLType = @edltype and EDLCode = @edlcode
			if @@rowcount = 0
			begin
				insert bPREA (PRCo, Employee, Mth, EDLType, EDLCode, Hours, Amount, SubjectAmt, EligibleAmt, AuditYN)
				values (@prco, @employee, @oldmth, @edltype, @edlcode, @oldhrs, @oldamt, @oldsubj, @oldelig, 'N')
			end
			-- reset audit flag
			update bPREA set AuditYN = 'Y'
			where PRCo = @prco and Employee = @employee and Mth = @oldmth and EDLType = @edltype and EDLCode = @edlcode
			if @@rowcount = 0
			begin
				select @errmsg = 'Unable to backout old Employee Accumulations!', @rcode = 1
				goto Accum_error
			end
		end
	   
	   -- add in 'new' accums
		if @paidmth is not null
		begin
			update bPREA
			set Hours = Hours + @hrs, Amount = Amount + @upamt, SubjectAmt = SubjectAmt + @subjamt,
			EligibleAmt = EligibleAmt + @eligamt, AuditYN = 'N'
			where PRCo = @prco and Employee = @employee and Mth = @paidmth and EDLType = @edltype and EDLCode = @edlcode
			if @@rowcount = 0
			begin
				insert bPREA (PRCo, Employee, Mth, EDLType, EDLCode, Hours, Amount, SubjectAmt, EligibleAmt, AuditYN)
				values (@prco, @employee, @paidmth, @edltype, @edlcode, @hrs, @upamt, @subjamt, @eligamt, 'N')
			end
			-- reset audit flag
			update bPREA set AuditYN = 'Y'
			where PRCo = @prco and Employee = @employee and Mth = @paidmth and EDLType = @edltype and EDLCode = @edlcode
			if @@rowcount = 0
			begin
				select @errmsg = 'Unable to add new Employee Accumulations!', @rcode = 1
				goto Accum_error
			end
		end
	   
		-- no 'new' values were updated to Accums so set 'old' values to 0.00 -- GG 01/28/00
		if @paidmth is null select @hrs = 0, @upamt = 0, @subjamt = 0, @eligamt = 0

		-- move 'old' values to 'new' in Pay Sequence Totals
		update bPRDT
		set OldHours = @hrs, OldAmt = @upamt, OldSubject = @subjamt, OldEligible = @eligamt, OldMth = @paidmth
		where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
		and PaySeq = @payseq and EDLType = @edltype and EDLCode = @edlcode
		if @@rowcount = 0
		begin
			select @errmsg = 'Unable to update Payment Sequence Totals with old values!', @rcode = 1
			goto Accum_error
		end

		commit transaction
	   
		goto next_EmplDetail

		Accum_error:
		rollback transaction
		goto bspexit

		end_EmplDetail:
		close bcEmplDetail
		deallocate bcEmplDetail
		select @openEmplDetail = 0
		goto next_EmplSeq
	   
		end_EmplSeq:
		close bcEmplSeq
		deallocate bcEmplSeq
		select @openEmplSeq = 0

	END TRY
	BEGIN CATCH
		select @errmsg='', @rcode=1
		if ERROR_NUMBER() = 16943 select @errmsg = 'SQL ERROR #16943 trapped in bspPRUpdatePostAccums'
	END CATCH
   
	bspexit:
	if @openEmplSeq = 1
	begin
		close bcEmplSeq
		deallocate bcEmplSeq
	end

	if @openEmplDetail = 1
	begin
		close bcEmplDetail
		deallocate bcEmplDetail
	end
   
       --select @errmsg = @errmsg + char(13) + char(10) + '[bspPRUpdatePostAccums]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRUpdatePostAccums] TO [public]
GO
