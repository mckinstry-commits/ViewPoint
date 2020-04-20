SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCHCContractVal  */  
   CREATE    procedure [dbo].[bspJCHCContractVal]
   /************************************************************
    * CREATED:     DC 05/29/03  Issue #18386
    * MODIFIED:    TV - 23061 added isnulls
    *
    * USAGE:
    * Check the Job Cost History table to see if the Contract Number exists.
    *
    * INPUT PARAMETERS
    *   @jcco      JCCo
    *   @contract	Contract #
    *
    * OUTPUT PARAMETERS
    *   @errmsg     if something went wrong
    * RETURN VALUE
    *   0   success
    *   1   fail
    ************************************************************/
   	@jcco bCompany, @contract bContract, @errmsg varchar(255) output
   
   as
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   /* verify Tax Year Ending Month */
   IF @contract is null
   	BEGIN
   	select @errmsg = 'Contract Number cannot be null.', @rcode = 1
   	goto bspexit
   	END
   
   IF exists(select top 1 1 from bJCHC where Contract = @contract and JCCo = @jcco)
   	BEGIN
   	select @errmsg = 'Contract Number ' + isnull(@contract,'') + ' was purged previously', @rcode = 1
   	goto bspexit
   	END
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCHCContractVal] TO [public]
GO
