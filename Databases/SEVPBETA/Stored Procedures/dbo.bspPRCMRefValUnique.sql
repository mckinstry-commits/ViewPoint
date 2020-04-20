SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRCMRefValUnique    Script Date: 8/28/99 9:32:30 AM ******/
   
   
    CREATE      proc [dbo].[bspPRCMRefValUnique]
    /***********************************************************
     * CREATED BY: EN 5/2/00
     * Modified:   GG 06/20/00 - fixed to remove conversion errors
     *			GG 02/01/01 - rewritten to correct numerous errors
     *         GG 02/06/01 - added input params for PRGroup, PREndDate, and PaySeq
     *			GG 06/22/01 - reordered input params, improved error messages (#13835)
     *			EN 12/03/03 - issue 23061  added isnull check, with (nolock), and dbo
     *			EN 2/9/04 - issue 20974  clarified error message for when check ref is assigned to another employee
     *							and also fixed year format in error messages to display as mm/dd/yy rather than mm/dd/first 2 digits of 4 digit year
     *			EN 11/23/04 - issue 24656 skip validation if CMRef is null
     *			EN 1/14/05 - issue 26490 1) Removed the condition to only check if CM Ref in use for another empl because it allowed users to 
     *										enter Ref Seq 1 for one employee and Ref Seq 0 for another.  All Ref Seq's for a check need to be to
     *										the same employee.
     *									 2)	Added code to make sure the same CM Ref/Ref Seq combination is never reused after being marked as
     *										non-reusable.
     *									 3) Reorganized order that validation checks are made to put them in order of most to least significant.
     *										Sometimes several validation tests would fail and I want the most informative message to display.
     *										The order is as follows ... CM Ref/Seq already assigned to another employee, check is marked as void and
     *										non-reusable, CM Ref/Seq already used.
	 *
	 *			mh 11/1/06 - PREmployeeSequence recode Issue 27890- Moved form validation of CMRef into sp.
     *
     * USAGE:
     *     Called from PR Employee Sequence Control program to validate CM Reference
     *     and Reference Sequence # for manual checks.
     *
     * INPUT PARAMETERS
     *   @prco		   PR Company
     *   @prgroup      PR Group
     *   @prenddate    PR Ending Date
     *   @employee	    Employee #
     *   @payseq       Payment Sequence
     *   @cmco		   CM Company
     *   @cmacct		CM Account
     *   @cmref		CM Reference
     *   @cmrefseq	    Reference Sequence #
     *
     * OUTPUT PARAMETERS
     *   @msg     Error message if invalid
     *
     * RETURN VALUE
     *   0 Success
     *   1 fail
     *****************************************************/
   	(@prco bCompany = null, @prgroup bGroup = null, @prenddate bDate = null, @employee bEmployee = null,
        @payseq tinyint = null, @cmco bCompany = null, @cmacct bCMAcct = null, @cmref bCMRef = null,
        @cmrefseq tinyint = null, @msg varchar(255) = null output)
   
   as
   
   set nocount on
   
   declare @rcode int, @xprco bCompany, @xprgroup bGroup, @xprenddate bDate, @xemployee bEmployee, @xpayseq tinyint,
   	@sourceco bCompany, @source bSource, @payee varchar(20), @xdate bDate
   
   select @rcode = 0
   
	--6.x recode.  Validate CMRef to make sure it is in proper format before we check anything else.
	if ((select charindex('.', @cmref)) > 0 ) or ((select substring(@cmref, 1, 1)) = '0')
	begin
		select @msg = 'CM Reference must be a numeric whole number greater than zero, no larger than 10 digits, with no leading zeros.', @rcode = 1
		goto bspexit
	end


   if @prco is null or @prgroup is null or @prenddate is null
   	begin
    	select @msg = 'Missing PR Company, Group, or Ending Date!', @rcode = 1
    	goto bspexit
    	end
   if @employee is null or @payseq is null
    	begin
    	select @msg = 'Missing Employee or Payment Sequence #!', @rcode = 1
    	goto bspexit
    	end
   if @cmco is null or @cmacct is null
    	begin
    	select @msg = 'Missing CM Company or Account!', @rcode = 1
    	goto bspexit
    	end
   if @cmref is null
    	begin
    	goto bspexit
    	end
   
   select @cmrefseq = isnull(@cmrefseq,0)  -- assume 0 if no Reference Seq# has been passed
   
   -- if CM Reference Sequence <> 0, make sure all others posted to same Employee
   --if @cmrefseq > 0 <--issue 26490 commented out to prevent posting Ref Seq 1 to one employee then posting Ref Seq 0 for the same CM Ref to another employee
   --	begin
   	-- check Employee Pay Sequence Control
   	select @xprco = PRCo, @xprgroup = PRGroup, @xprenddate = PREndDate, @xemployee = Employee, @xpayseq = PaySeq
   	from dbo.bPRSQ with (nolock)
   	where CMCo = @cmco and CMAcct = @cmacct and CMRef = @cmref and CMRefSeq <> @cmrefseq and PayMethod = 'C'
   		and (Employee <> @employee or PRCo <> @prco)
   	if @@rowcount <> 0
   		begin
        	select @msg = 'CM Reference already in use in Employee Sequence Control for another employee.' + char(13) + char(10)
   			+ 'PR Co#: ' + convert(varchar(3),@xprco)	+ ' PR Group:' + convert(varchar(3),@xprgroup)
   			+ ' PR End Date: ' + convert(varchar(8),@xprenddate,1)
   			+ ' Employee: ' + convert(varchar(6),@xemployee) + ' Pay Seq:' + convert(varchar(2),@xpayseq)
   		select @rcode = 1
        	goto bspexit
        	end
   	-- check PR Payment History
   	select @xprco = PRCo, @xprgroup = PRGroup, @xprenddate = PREndDate, @xemployee = Employee, @xpayseq = PaySeq
   	from dbo.bPRPH with (nolock)
   	where CMCo = @cmco and CMAcct = @cmacct and CMRef = @cmref and CMRefSeq <> @cmrefseq and PayMethod = 'C'
   		and (Employee <> @employee or PRCo <> @prco)
   	if @@rowcount <> 0
   		begin
        	select @msg = 'CM Reference already exists in Payment History for another employee.' + char(13) + char(10)
   			+ 'PR Co#: ' + convert(varchar(3),@xprco)	+ ' PR Group:' + convert(varchar(3),@xprgroup)
   			+ ' PR End Date: ' + convert(varchar(8),@xprenddate,1)
   	 		+ ' Employee: ' + convert(varchar(6),@xemployee) + ' Pay Seq:' + convert(varchar(2),@xpayseq)
   		select @rcode = 1
        	goto bspexit
        	end
   	-- check PR Void Payments (unprocessed voids)
   	select @xprco = PRCo, @xprgroup = PRGroup, @xprenddate = PREndDate, @xemployee = Employee, @xpayseq = PaySeq
   	from dbo.bPRVP with (nolock)
   	where CMCo = @cmco and CMAcct = @cmacct and CMRef = @cmref and CMRefSeq <> @cmrefseq and PayMethod = 'C'
   		and (Employee <> @employee or PRCo <> @prco)
   	if @@rowcount <> 0
   		begin
        	select @msg = 'CM Reference exists in PR Void Payments for another employee.' + char(13) + char(10)
   			+ 'PR Co#: ' + convert(varchar(3),@xprco) + ' PR Group:' + convert(varchar(3),@xprgroup) 
   			+ ' PR End Date: ' + convert(varchar(8),@xprenddate,1)
   	 		+ ' Employee: ' + convert(varchar(6),@xemployee) + ' Pay Seq:' + convert(varchar(2),@xpayseq)
   		select @rcode = 1
        	goto bspexit
        	end
   	-- check CM Detail
   	select @sourceco = SourceCo, @source = Source, @payee = Payee, @xdate = ActDate
   	from dbo.bCMDT with (nolock)
   	where CMCo = @cmco and CMAcct = @cmacct and CMRef = @cmref and CMRefSeq <> @cmrefseq and CMTransType = 1	-- checks
   		and (SourceCo <> @prco or Payee <> convert(varchar(20),@employee))
   	if @@rowcount <> 0
   		begin
        	select @msg = 'CM Reference already exists in CM Detail for another employee.' + char(13) + char(10)
   		+ 'Posted from Source Co#:' + convert(varchar(3),@sourceco)
   	   	+ ' Source: ' + isnull(@source,'') + ' Payee: ' + isnull(@payee,'') + ' Date: ' + convert(varchar(8),@xdate,1)
   		select @rcode = 1
        	goto bspexit
        	end
   --    end
   
   -- issue 26490 check PR Payment History for void, non-reusable
   select @xprco = PRCo, @xprgroup = PRGroup, @xprenddate = PREndDate, @xemployee = Employee, @xpayseq = PaySeq
   from dbo.bPRPH with (nolock)
   where CMCo = @cmco and CMAcct = @cmacct and CMRef = @cmref and CMRefSeq = @cmrefseq and PayMethod = 'C'
   	and Void='Y'
   if @@rowcount <> 0
   	begin
        select @msg = 'CM Reference and Seq exist in Payment History as Void and non-reusable.' + char(13) + char(10)
   		+ 'PR Co#: ' + convert(varchar(3),@xprco) + ' PR Group:' + convert(varchar(3),@xprgroup)
   		+ ' PR End Date: ' + convert(varchar(8),@xprenddate,1)
   	 	+ ' Employee: ' + convert(varchar(6),@xemployee) + ' Pay Seq:' + convert(varchar(2),@xpayseq)
   	select @rcode = 1
        goto bspexit
        end
   -- issue 26490  check PR Void Payments where Reuse='N'
   select @xprco = PRCo, @xprgroup = PRGroup, @xprenddate = PREndDate, @xemployee = Employee, @xpayseq = PaySeq
   from dbo.bPRVP with (nolock)
   where CMCo = @cmco and CMAcct = @cmacct and CMRef = @cmref and CMRefSeq = @cmrefseq and PayMethod = 'C'
       and Reuse = 'N'
   if @@rowcount <> 0
   	begin
        select @msg = 'CM Reference and Seq exist in PR Void Payment marked as non-reusable.' + char(13) + char(10)
   		+ 'PR Co#: ' + convert(varchar(3),@xprco) + ' PR Group:' + convert(varchar(3),@xprgroup)
   		+ ' PR End Date: ' + convert(varchar(8),@xprenddate,1)
   	 	+ ' Employee: ' + convert(varchar(6),@xemployee) + ' Pay Seq:' + convert(varchar(2),@xpayseq)
   	select @rcode = 1
        goto bspexit
        end
   
   -- CM Reference and Ref Seq must be unique within CM Co# and CM Acct
   
   -- check Employee Pay Sequence Control
   select @xprco = PRCo, @xprgroup = PRGroup, @xprenddate = PREndDate, @xemployee = Employee, @xpayseq = PaySeq
   from dbo.bPRSQ with (nolock)
   where CMCo = @cmco and CMAcct = @cmacct and CMRef = @cmref and CMRefSeq = @cmrefseq and PayMethod = 'C'
       and (PRCo <> @prco or PRGroup <> @prgroup or PREndDate <> @prenddate or Employee <> @employee or PaySeq <> @payseq)
   if @@rowcount <> 0
   	begin
        select @msg = 'CM Reference and Seq already in use in Employee Sequence Control.' + char(13) + char(10)
   		+ 'PR Co#: ' + convert(varchar(3),@xprco) + ' PR Group:' + convert(varchar(3),@xprgroup)
   		+ ' PR End Date: ' + convert(varchar(8),@xprenddate,1) 
   		+ ' Employee: ' + convert(varchar(6),@xemployee) + ' Pay Seq:' + convert(varchar(2),@xpayseq)
   	select @rcode = 1
        goto bspexit
        end
   -- check PR Payment History
   select @xprco = PRCo, @xprgroup = PRGroup, @xprenddate = PREndDate, @xemployee = Employee, @xpayseq = PaySeq
   from dbo.bPRPH with (nolock)
   where CMCo = @cmco and CMAcct = @cmacct and CMRef = @cmref and CMRefSeq = @cmrefseq and PayMethod = 'C'
       and (PRCo <> @prco or PRGroup <> @prgroup or PREndDate <> @prenddate or Employee <> @employee or PaySeq <> @payseq)
   if @@rowcount <> 0
   	begin
        select @msg = 'CM Reference and Seq already exists in Payment History.' + char(13) + char(10)
   		+ 'PR Co#: ' + convert(varchar(3),@xprco) + ' PR Group:' + convert(varchar(3),@xprgroup)
   		+ ' PR End Date: ' + convert(varchar(8),@xprenddate,1)
   	 	+ ' Employee: ' + convert(varchar(6),@xemployee) + ' Pay Seq:' + convert(varchar(2),@xpayseq)
   	select @rcode = 1
        goto bspexit
        end
   -- check PR Void Payments (unprocessed voids)
   select @xprco = PRCo, @xprgroup = PRGroup, @xprenddate = PREndDate, @xemployee = Employee, @xpayseq = PaySeq
   from dbo.bPRVP with (nolock)
   where CMCo = @cmco and CMAcct = @cmacct and CMRef = @cmref and CMRefSeq = @cmrefseq and PayMethod = 'C'
       and (PRCo <> @prco or PRGroup <> @prgroup or PREndDate <> @prenddate or Employee <> @employee or PaySeq <> @payseq)
   if @@rowcount <> 0
   	begin
        select @msg = 'CM Reference and Seq exists in PR Void Payments.' + char(13) + char(10)
   		+ 'PR Co#: ' + convert(varchar(3),@xprco) + ' PR Group:' + convert(varchar(3),@xprgroup)
   		+ ' PR End Date: ' + convert(varchar(8),@xprenddate,1)
   	 	+ ' Employee: ' + convert(varchar(6),@xemployee) + ' Pay Seq:' + convert(varchar(2),@xpayseq)
   	select @rcode = 1
        goto bspexit
        end
   -- check CM Detail
   select @sourceco = SourceCo, @source = Source, @payee = Payee, @xdate = ActDate
   from dbo.bCMDT with (nolock)
   where CMCo = @cmco and CMAcct = @cmacct and CMRef = @cmref and CMRefSeq = @cmrefseq and CMTransType = 1	-- checks
       and (SourceCo <> @prco or Payee <> convert(varchar(20),@employee))
   if @@rowcount <> 0
   	begin
        select @msg = 'This CM Reference and Seq already exists in CM Detail.' + char(13) + char(10)
   		+ 'Posted from Source Co#:' + convert(varchar(3),@sourceco)
   	   	+ ' Source: ' + isnull(@source,'') + ' Payee: ' + isnull(@payee,'') + ' Date: ' + convert(varchar(8),@xdate,1)
   	select @rcode = 1
        goto bspexit
        end
   
   bspexit:
   	if @msg is not null select @msg = isnull(@msg,'') --+ char(13) + char(10) + '[bspPRCMRefValUnique]'
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRCMRefValUnique] TO [public]
GO
