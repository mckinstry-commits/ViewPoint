SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRBeginCheckDflt    Script Date: 8/28/99 9:33:56 AM ******/
   
   CREATE    proc [dbo].[bspPRBeginCheckDflt]
   /***********************************************************
   * CREATED: EN 3/22/01
   * MODIFIED: GG 09/18/01 - #13023 - fix check # output
   *			kb 8/12/02 - issue #18263 - needs to check CMDT too when getting default check #
   *			GG 12/10/02 - #19608 - remove bCMDT lookup, caused problems with shared CM Accounts
   *			MV 02/18/03 - #20373 - if max check # reached, don't add 1, return max #
   * USAGE:
   *   Called from PR Check Print form to provide a beginning
   *   check number default.  
   *
   * INPUT PARAMETERS
   *   @cmco        CM Company
   *   @cmacct      CM Account
   *
   * OUTPUT PARAMETERS
   *   @begcheck    Beginning check number to be used
   *   @msg         Error message
   *
   * RETURN VALUE
   *   0         success
   *   1         failure
   *****************************************************/
   
         (@cmco bCompany, @cmacct bCMAcct, @begcheck bigint output, @msg varchar(255) output)
   as
   
   set nocount on
   
   declare @rcode int, @check1 bigint, @check2 bigint, @check3 bigint
   
   select @check1 = 0, @check2 = 0, @check3 = 0, @rcode = 0, @msg = 'Error finding check numbers.'
   
   -- PR Sequence Control
   select @check1 = isnull(max(convert(numeric,CMRef)),0)
   from bPRSQ
   where CMCo = @cmco and CMAcct = @cmacct and PayMethod = 'C'
       and isNumeric(CMRef) = 1 
   
   -- PR Void Payments
   select @check2 = isnull(max(convert(numeric,CMRef)),0)
   from bPRVP
   where CMCo = @cmco and CMAcct = @cmacct and PayMethod = 'C' and Reuse = 'N'
       and isNumeric(CMRef) = 1 
   
   -- PR Payment History
   select @check3 = isnull(max(convert(numeric,CMRef)),0)
   from bPRPH
   where CMCo = @cmco and CMAcct = @cmacct and PayMethod = 'C' and isNumeric(CMRef) = 1 
   
   
   select @begcheck = @check1
   if @check2 > @begcheck select @begcheck = @check2
   if @check3 > @begcheck select @begcheck = @check3 
   
   if @begcheck < 9999999999
   begin
   select @begcheck = @begcheck + 1
   end
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRBeginCheckDflt] TO [public]
GO
