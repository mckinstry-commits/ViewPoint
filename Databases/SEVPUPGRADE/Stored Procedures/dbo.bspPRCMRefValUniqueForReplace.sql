SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRCMRefValUniqueForReplace    Script Date: 8/28/99 9:32:30 AM ******/
    
    
     CREATE     proc [dbo].[bspPRCMRefValUniqueForReplace]
     /***********************************************************
      * CREATED BY: EN 2/4/04  Created for issue 20974
      * Modified:
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
    
    if @cmref is null or @cmrefseq is null
   	begin
   	select @msg = ''
   	goto bspexit -- if CM Ref or CM Ref Seq is unknown, skip validation
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
    
    -- CM Reference and Ref Seq must be unique within CM Co# and CM Acct
    
    -- check Employee Pay Sequence Control
    select @xprco = PRCo, @xprgroup = PRGroup, @xprenddate = PREndDate, @xemployee = Employee, @xpayseq = PaySeq
    from dbo.bPRSQ with (nolock)
    where CMCo = @cmco and CMAcct = @cmacct and CMRef = @cmref and CMRefSeq = @cmrefseq and PayMethod = 'C'
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
    if @@rowcount <> 0
    	begin
         select @msg = 'This CM Reference and Seq already exists in CM Detail.' + char(13) + char(10)
    		+ 'Posted from Source Co#:' + convert(varchar(3),@sourceco)
    	   	+ ' Source: ' + isnull(@source,'') + ' Payee: ' + isnull(@payee,'') + ' Date: ' + convert(varchar(8),@xdate,1)
    	select @rcode = 1
         goto bspexit
         end
    
    -- if CM Reference Sequence <> 0, make sure all others posted to same Employee
    if @cmrefseq > 0
    	begin
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
        end
    
    bspexit:
    	if @msg is not null select @msg = isnull(@msg,'') --+ char(13) + char(10) + '[bspPRCMRefValUniqueForReplace]'
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRCMRefValUniqueForReplace] TO [public]
GO
