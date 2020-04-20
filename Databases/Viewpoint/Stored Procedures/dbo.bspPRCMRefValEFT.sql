SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRCMRefValEFT    Script Date: 8/28/99 9:33:13 AM ******/
   CREATE  proc [dbo].[bspPRCMRefValEFT]
   /***********************************************************
   * CREATED BY: EN 5/5/98
   * MODIFIED By : EN 5/5/98
   *				GG 07/25/02 - #17998 - removed reload param and logic, performed in bspPREFTClear 
   *
   * USAGE:
   *   Validates EFT CM Reference for EFT Download Program
   *
   * INPUT PARAMETERS
   *   @cmco      CM Co
   *   @cmacct    CM Account
   *   @cmref     The reference
   *
   * OUTPUT PARAMETERS
   *   @msg     Error message if invalid
   *
   * RETURN VALUE
   *   0 Success
   *   1 fail
   *****************************************************/
   
   	@cmco bCompany = null, @cmacct bCMAcct = null, @cmref bCMRef = null,
   	@msg varchar(255) output
   
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   if @cmco is null
   	begin
   	select @msg = 'Missing CM Company!', @rcode = 1
   	goto bspexit
   	end
   if @cmacct is null
   	begin
   	select @msg = 'Missing CM Account!', @rcode = 1
   	goto bspexit
   	end
   if @cmref is null
   	begin
   	select @msg = 'Missing CM Reference!', @rcode = 1
   	goto bspexit
   	end
   
   -- check Employee Sequence Control
   if exists (select 1 from bPRSQ where PayMethod = 'E' and CMCo = @cmco and CMAcct = @cmacct
    	          and CMRef = @cmref)
   	begin
    	select @msg = 'Payroll entries already exist for this CM Reference!', @rcode = 1
    	goto bspexit
    	end
   -- check unposted Void Payments, will exist here if previously posted to CM, cleared, but the
   -- Ledger update has not yet been run.
   if exists (select 1 from bPRVP where PayMethod = 'E' and CMCo = @cmco and CMAcct = @cmacct
    	          and CMRef = @cmref)
   	begin
    	select @msg = 'CM Reference was previously used and cleared, but not available for reuse until Ledger update is run.', @rcode=1
    	goto bspexit
    	   end
   -- check PR Payment History
   if exists (select 1 from bPRPH where PayMethod = 'E' and CMCo = @cmco and CMAcct = @cmacct
    	          and CMRef = @cmref)
   	begin
    	select @msg = 'Payment History entries exist for this CM Reference!', @rcode = 1
    	goto bspexit
    	end
   -- check CM Detail
   if exists (select 1 from bCMDT where CMTransType = 4 and CMCo = @cmco and CMAcct = @cmacct
    	          and CMRef = @cmref)	-- transtype 4 is EFT
   	begin
    	select @msg = 'Entries in CM Detail already exist for this CM Reference!', @rcode = 1
    	goto bspexit
    	end
   
   
   bspexit:
      return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRCMRefValEFT] TO [public]
GO
