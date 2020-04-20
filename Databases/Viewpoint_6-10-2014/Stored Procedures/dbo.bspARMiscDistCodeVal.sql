SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARMiscDistCodeVal    Script Date: 8/28/99 9:32:35 AM ******/
   CREATE  proc [dbo].[bspARMiscDistCodeVal]
   	(@CustGroup bGroup = null, @miscdistcode char(10) = null, @msg varchar(60) output)
   as
   /***********************************************************
    * CREATED BY: CJW 5/8/97
    * MODIFIED By : CJW 5/8/97
    *		TJL 10/06/03 - Issue #17897, Corrected MiscDistCode references to datatype char(10) (Consistent w/AR and MS)
    *
    * USAGE:
    * validates Misc Distribution code
    * an error is returned if any of the following occurs
    * no code passed, or ode doesn't exist in BARMC
    *
    * INPUT PARAMETERS
    *   CustGroup  assigned in bHQCO
    *   Dist code  to valideate
    *
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs otherwise description of tax code
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/
   set nocount on
   declare @rcode int
   select @rcode = 0
   
   if @CustGroup is null
   	begin
   	select @msg = 'Missing Customer Group', @rcode = 1
   	goto bspexit
   	end
   if @miscdistcode is null
   	begin
   	select @msg = 'Missing Misc distribution code', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description
   from bARMC with (nolock)
   where CustGroup = @CustGroup and MiscDistCode = @miscdistcode
   if @@rowcount = 0
   	begin
   	select @msg = 'Distribution code not on file!', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	if @rcode<>0 select @msg=@msg	--+ char(13) + char(10) + '[bspARMiscDistCodeVal]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARMiscDistCodeVal] TO [public]
GO
