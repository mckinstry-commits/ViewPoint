SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspPREFTGetMaxCMRef]
   /***********************************************************
   * Created: GG 08/07/02 - #17017
   * Modified: 
   *
   * Usage:
   *	Called from PR EFT Payments program to retrieve last used 
   * 	CM Reference #
   *
   * Inputs:
   *   @cmco		CM Company
   *   @cmacct		CM Account
   *
   * Outputs:
   *   @cmref		CM Reference
   *   @msg     	Error message
   *
   * RETURN CODE
   *   @rcode		0 = success, 1 = error
   *  
   *****************************************************/
   	(@cmco bCompany = null, @cmacct bCMAcct = null, @cmref bCMRef  = null output,
        @msg varchar(255) = null output)
   
   as
   
   set nocount on
   
   declare @rcode int, @cmref1 bCMRef, @cmref2 bCMRef, @cmref3 bCMRef
   
   select @rcode = 0
   
   if @cmco is null or @cmacct is null
    	begin
    	select @msg = 'Missing CM Company or Account!', @rcode = 1
    	goto bspexit
    	end
   
   -- get highest value from PR Sequence Control
   select @cmref1 = isnull(max(CMRef),'')
   from bPRSQ
   where CMCo = @cmco and CMAcct = @cmacct and PayMethod = 'E'
          
   -- get highest value from PR Payment History
   select @cmref2 = isnull(max(CMRef),'')
   from bPRPH
   where CMCo = @cmco and CMAcct = @cmacct and PayMethod = 'E'
   
   -- get highest value from CM Detail
   select @cmref3 = isnull(max(CMRef),'')
   from bCMDT
   where CMCo = @cmco and CMAcct = @cmacct and CMTransType = 4 
   
   if @cmref1 > @cmref2 select @cmref2 = @cmref1
   if @cmref2 > @cmref3 select @cmref3 = @cmref2
   
   select @cmref = @cmref3 -- highest # in use
   
   bspexit:
   	--if @msg is not null select @msg = @msg + char(13) + char(10) + '[bspPREFTGetMaxCMRef]'
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPREFTGetMaxCMRef] TO [public]
GO
