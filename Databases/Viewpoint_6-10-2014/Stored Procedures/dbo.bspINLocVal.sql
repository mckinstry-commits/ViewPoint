SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    procedure [dbo].[bspINLocVal]
      /*************************************
     * CREATED BY: ??
     * Modified By: GR 10/26/99
     *              GR 2/21/00
     *              GR 3/1/00 clean up and added an output param job
     *				MV 10/9/07 - #125628 changed bINLM to INLM for security
     *
     * validates IN Locations
     *
     * Pass:
     *   INCo - Inventory Company
     *   Loc - Location to be Validated
     *
     *
     * Success returns:
     *   Description of Location
     *
     * Error returns:
     *	1 and error message
     **************************************/
     	(@INCo bCompany = null, @Loc bLoc = null, @activeopt bYN = 'N',
         @jcco bCompany output, @job bJob output, @msg varchar(100) output)
     as
     	set nocount on
     	declare @rcode int, @active bYN, @matlgroup bGroup, @category varchar(10)
        	select @rcode = 0
    
     if @INCo is null
     	begin
     	select @msg = 'Missing IN Company', @rcode = 1
     	goto bspexit
     	end
    
     if @Loc is null
     	begin
     	select @msg = 'Missing IN Location', @rcode = 1
     	goto bspexit
     	end
    
     select @active=Active, @msg = Description, @jcco=JCCo, @job=Job
         from INLM where INCo = @INCo and Loc = @Loc
    
     if @@rowcount = 0
         begin
         select @msg='Not a valid Location', @rcode=1
         goto bspexit
         end
    
     if @activeopt = 'Y' and @active = 'N'
         begin
         select @msg = 'Not an active Location', @rcode=1
         goto bspexit
         end
    
     bspexit:
        -- if @rcode<>0 select @msg=@msg 
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINLocVal] TO [public]
GO
