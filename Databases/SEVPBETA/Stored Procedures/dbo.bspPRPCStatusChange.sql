SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRPCStatusChange    Script Date: 8/28/99 9:35:34 AM ******/
   CREATE   procedure [dbo].[bspPRPCStatusChange]
   /***********************************************************
    * CREATED BY: GG 07/03/98
    * MODIFIED By : kb 10/9/98
    *		    gh 03/15/2000 Changed CMDT Trans Type 4 (EFT) validation to check for a source of PR Update not PR Entry
    *            GG 5/1/00 - Set final interface flags for AP and EM Cost to 'Y' if no change in AP data, or EM Costs
    *            GG 6/1/00 - Check for unprocessed override liabs in bPRDT when trying to close
    *				GG 01/21/02 - #14406 - cannot reopen converted Pay Pds
    *			EN 10/8/02 - issue 18877 change double quotes to single
	*			EN 12/04/06 - issue 27864 changed HQBC TableName reference from 'PRTZGrid' to 'PRTB'
    *			MV 08/28/2012 - TK-17452 include Payback Amt in deduction amounts from PRDT
      *
      * Called by the PR Pay Period Control form to change a
      * Pay Period's Status from Open to Closed, or Closed to Open.
      *
      * Inputs:
      *	@prco		PR Company
      *	@prgroup	PR Group
      *	@prenddate	PR Ending Date
      *
      * Outputs:
      *	@msg		Message if unable to change Status
      *
      * Return Value:
      *   0         		Success
      *   1         		Failure
      *****************************************************/
     	(@prco bCompany = null, @prgroup bGroup = null, @prenddate bDate = null,
     	 @msg varchar(255) = null output)
     as
     set nocount on
   
     declare @rcode int, @status tinyint, @beginmth bMonth, @openEmplSeq tinyint, @employee bEmployee, @payseq tinyint,
     @cmco bCompany, @cmacct bCMAcct, @paymethod char(1), @cmref bCMRef, @cmrefseq tinyint, @eftseq smallint, @paidmth bMonth,
     @hours bHrs, @earns bDollar, @dedns bDollar, @cminterface bYN, @dthours bHrs, @dtearns bDollar, @dtdedns bDollar,
     @numrows int, @dstotal bDollar, @mth bMonth, @stmtdate bDate, @sourceco bCompany, @source bSource, @void bYN,
     @prglco bCompany, @lastmthsubclsd bMonth, @conv bYN
   
   select @rcode = 0
   
   -- get current Pay Period info
   select @status = Status, @beginmth = BeginMth, @conv = Conv
   from PRPC
   where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
   if @@rowcount = 0
   	begin
     	select @msg = 'Invalid Pay Period!', @rcode = 1
     	goto bspexit
     	end
   if @status = 0	-- Pay Period is open - check if OK to close
   	begin
     	select @msg = 'Cannot close this Pay Period.  '
     	-- check for unposted Timecard Batches
     	if exists(select * from bHQBC
     		 where Co = @prco and PRGroup = @prgroup and PREndDate = @prenddate	and Status < 5 and TableName='PRTB')
   		/*kb 10/7/98 - made a change on previous line so that it wouldn't keep you from closing your timecard batch when you
   		have batches open in PRJC, PRGL, PRCM, PREM as these shouldn't block out */
     		begin
     		select @msg = @msg + 'One or more unposted Timecard Batches exist!', @rcode = 1
     		goto bspexit
     		end
     	-- check for unprocessed Employee/Pay Seqs
     	if exists(select * from bPRSQ
     		where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Processed = 'N')
     		begin
     		select @msg = @msg + 'One or more Employees have not been processed!', @rcode = 1
     		goto bspexit
     		end
     	-- check for unpaid Employee/Pay Seqs
     	if exists(select * from bPRSQ
     		where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
     			and ((CMRef is null or PaidMth is null) and PayMethod <> 'X'))
     		begin
     		select @msg = @msg + 'One or more Employee/Payment Seqs have not been paid!', @rcode = 1
     		goto bspexit
     		end
     	-- use a cursor to check each Employee/Payment Sequence
     	declare bcEmplSeq cursor for
     	select Employee, PaySeq, CMCo, CMAcct, PayMethod, CMRef, CMRefSeq, EFTSeq, PaidMth,
     		Hours, Earnings, Dedns, CMInterface
     	from bPRSQ
     	where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
     	open bcEmplSeq
     	select @openEmplSeq = 1
     	next_EmplSeq:
     		fetch next from bcEmplSeq into @employee, @payseq, @cmco, @cmacct, @paymethod, @cmref,
     			@cmrefseq, @eftseq, @paidmth, @hours, @earns, @dedns, @cminterface
     		if @@fetch_status <> 0 goto end_EmplSeq
           -- check for unprocessed override liabs - indicates liab has no basis and has not been distributed
           if exists(select * from bPRDT where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
    			and Employee = @employee and PaySeq = @payseq and EDLType = 'L' and UseOver = 'Y' and OverProcess = 'N')
               begin
               select @msg = @msg + 'Employee ' + convert(varchar(8),@employee) + ' has unprocessed liabilities.  Check for overridden amounts with 0.00 basis.', @rcode = 1
               goto bspexit
               end
     		-- get totals from PR Employee Detail
     		select @dthours = isnull(sum(Hours),0), @dtearns = isnull(sum(Amount),0)
     		from bPRDT
     		where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
     			and Employee = @employee and PaySeq = @payseq and EDLType = 'E'
     		SELECT @dtdedns = ISNULL(SUM(CASE UseOver WHEN 'Y' THEN OverAmt ELSE Amount END),0)
     				+ ISNULL(SUM(CASE WHEN PaybackOverYN='Y' THEN PaybackOverAmt ELSE PaybackAmt END),0) -- TK-17452
     		FROM dbo.bPRDT
     		WHERE PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
     			and Employee = @employee and PaySeq = @payseq and EDLType = 'D'
             -- check that Paid Amts equal totals in bPRDT
     		if @hours <> @dthours or @earns <> @dtearns or @dedns <> @dtdedns
     			begin
     			select @msg = @msg + 'Total hours, earnings, deductions, and paid amounts don''t match on Employee ' + convert(varchar(8),@employee), @rcode = 1
                 goto bspexit
                 end
             -- 'No Pay' only valid if net pay equals 0.00
             if @paymethod = 'X' and (@earns - @dedns <> 0)
                 begin
                 select @msg = @msg + 'Employee ' + convert(varchar(8),@employee) + ' is a ''No Pay'', but has net earnings.', @rcode = 1
                 goto bspexit
   
                 end
             -- validate Checks
             if @paymethod = 'C'
                 begin
                 -- check for uniqueness within Pay Period
                 select @numrows = count(*) from bPRSQ
                 where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
                     and CMCo = @cmco and CMAcct = @cmacct and PayMethod = 'C' and CMRef = @cmref
                     and CMRefSeq = @cmrefseq
                 if @numrows > 1
   
                     begin
                     select @msg = @msg + 'Check #' + @cmref + ' on Employee ' + convert(varchar(8),@employee) + ' is not unique.', @rcode = 1
                     goto bspexit
                     end
                 -- if not interfaced, Check# should not exist in CM or Payment History
                 if @cminterface = 'N'
                     begin
                     -- check CM Detail - Trans Type 1 is check
                     if exists(select * from bCMDT where CMCo = @cmco and CMAcct = @cmacct and CMTransType = 1
                             and CMRef = @cmref and CMRefSeq = @cmrefseq)
                         begin
                         select @msg = @msg + 'Check #' + @cmref + ' already exists in CM Detail.', @rcode = 1
                         goto bspexit
                         end
                     -- check PR Payment History
                     if exists(select * from bPRPH where PRCo = @prco and CMCo = @cmco and CMAcct = @cmacct and
                         PayMethod = 'C' and CMRef = @cmref and CMRefSeq = @cmrefseq)
                         begin
                         select @msg = @msg + 'Check #' + @cmref + ' already exists in PR Payment History.', @rcode = 1
                         goto bspexit
                         end
                     end
                 end
             -- validate EFTs
             if @paymethod = 'E'
                 begin
                 -- check for uniqueness within Pay Period
                 select @numrows = count(*) from bPRSQ
                 where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
                     and CMCo = @cmco and CMAcct = @cmacct and PayMethod = 'E' and CMRef = @cmref
                     and CMRefSeq = @cmrefseq and EFTSeq = @eftseq
                 if @numrows > 1
                     begin
                     select @msg = @msg + 'EFT #' + @cmref + ' and Seq ' + convert(varchar(6),@eftseq) + ' on Employee '
                         + convert(varchar(8),@employee) + ' is not unique.', @rcode = 1
                     goto bspexit
                     end
                 -- check sum of Depost Seq entries
                 select @dstotal = isnull(sum(Amt),0)
                 from bPRDS
                 where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
                     and PaySeq = @payseq
                 if @dstotal <> (@earns - @dedns)
                     begin
                     select @msg = @msg + 'Direct deposit distributions for Employee ' + convert(varchar(8),@employee) + ' don''t match net pay.', @rcode = 1
                     goto bspexit
                     end
                 -- check CM Detail - Trans Type 4 = EFT
                 if @cminterface = 'N'
               begin
                     select @mth = Mth, @stmtdate = StmtDate, @sourceco = SourceCo, @source = Source, @void = Void
                     from bCMDT
                     where CMCo = @cmco and CMAcct = @cmacct and CMTransType = 4 and CMRef = @cmref and CMRefSeq = @cmrefseq
                     if @@rowcount <> 0
                         begin
                         if @mth <> @paidmth
                             begin
                             select @msg = @msg + 'EFT #' + @cmref + ' already posted to CM in Month ' + convert(varchar(8),@mth,1), @rcode = 1
                             goto bspexit
                             end
                         if @stmtdate is not null
                             begin
                             select @msg = @msg + 'EFT #' + @cmref + ' has already been cleared on CM Statement ' + convert(varchar(8),@stmtdate,1),@rcode = 1
                             goto bspexit
                             end
                         if @sourceco <> @prco or @source <> 'PR Update'
                             begin
                             select @msg = @msg + 'EFT #' + @cmref + ' has been posted to CM from another Company and/or Source.', @rcode = 1
                             goto bspexit
                             end
                         if @void = 'Y'
                             begin
                             select @msg = @msg + 'EFT #' + @cmref + ' has been voided in CM.', @rcode = 1
                             goto bspexit
                             end
                         end
                     -- check PR Payment History
                     if exists(select * from bPRPH where PRCo = @prco and CMCo = @cmco and CMAcct = @cmacct and
                         PayMethod = 'E' and CMRef = @cmref and CMRefSeq = @cmrefseq and EFTSeq = @eftseq)
                         begin
                         select @msg = @msg + 'EFT #' + @cmref + ' Seq # ' + convert(varchar(6),@eftseq) + ' already exists in PR Payment History.', @rcode = 1
                         goto bspexit
                         end
                     end
                 end
             goto next_EmplSeq
         end_EmplSeq:
             close bcEmplSeq
             deallocate bcEmplSeq
             select @openEmplSeq = 0
         	-- change Pay Period Status to 'Closed'
         	update bPRPC set Status = 1, DateClosed = getdate()
         	where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
           if @@rowcount <> 1
                 begin
                 select @msg = @msg + 'Unable to update Pay Period Control entry.', @rcode = 1
                 goto bspexit
                 end
           else
                 begin
                 select @msg = 'Pay Period successfully closed.'
                 end
   
           -- if current and old AP info is identical, no AP update will be needed so set interface flag
    	    if not exists(select * from bPRDT
    		         where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
    			        and (Vendor is not null or OldVendor is not null)
                       and (isnull(Vendor,-1) <> isnull(OldVendor,-1)
                       or (UseOver = 'Y' and OverAmt <> OldAPAmt) or (UseOver = 'N' and Amount <> OldAPAmt)))
           update bPRPC set APInterface = 'Y'  -- final AP interface is complete
               where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
   
           -- if no Mechanics Timecards, no EM Cost update will be needed so set interface flag
           if not exists(select * from bPRTH where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
                   and Equipment is not null and CostCode is not null)
           update bPRPC set EMInterface = 'Y'  -- final EM Cost interface is complete
               where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
         end
   
   if @status = 1  -- closed, check if able to reopen
   	begin
   	-- #14406 - check for Vision to Viewpoint conversion
   	if @conv = 'Y'
   		begin
   		select @msg = 'This Pay Period was converted from Vision and cannot be reopened.', @rcode = 1
   		goto bspexit
   		end
      -- make Pay Period beginning month is still open PR GL Company
         select @prglco = GLCo from bPRCO where PRCo = @prco
         select @lastmthsubclsd = LastMthSubClsd
         from bGLCO where GLCo = @prglco
         if @beginmth <= @lastmthsubclsd
             begin
             select @msg = 'Pay Period cannot be reopened because its 1st Month has been closed in GL.', @rcode = 1
             goto bspexit
             end
         -- change Pay Period Status to 'Open'
         update bPRPC set Status = 0, DateClosed = null, JCInterface = 'N', EMInterface = 'N',
             GLInterface = 'N', APInterface = 'N', LeaveProcess = 'N'
         where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
         if @@rowcount <> 1
             begin
             select @msg = 'Unable to update Pay Period Control entry.  Cannot reopen Pay Period.', @rcode = 1
             goto bspexit
             end
         else
             begin
             select @msg = 'Pay Period successfully reopened.'
             end
         end
     bspexit:
         if @openEmplSeq = 1
             begin
             close bcEmplSeq
             deallocate bcEmplSeq
             end
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRPCStatusChange] TO [public]
GO
