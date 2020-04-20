SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPRPCGroupVal    Script Date: 09/24/2007 9:33:21 AM ******/
   CREATE   proc [dbo].[vspPRPCGroupVal]
   /***********************************************************
    * CREATED BY: EN 09/24/2007
    * MODIFIED By : 
    *
    * USAGE:
    * validates PR Group from PRGR and returns PayFreq ... used by PRPayPdControl
    *
    * INPUT PARAMETERS
    *   PRCo   PR Co to validate agains 
    *   Group  PR Group to validate
    * OUTPUT PARAMETERS
	*	@payfreq  PayFreq from PRGR
    *   @msg      error message if error occurs otherwise Description of PR Group
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/ 
   
   	(@prco bCompany = 0, @group bGroup = null, @payfreq bFreq output, @msg varchar(60) output)
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   if @prco is null
   	begin
   	select @msg = 'Missing PR Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @group is null
   	begin
   	select @msg = 'Missing PR Group!', @rcode = 1
   	goto bspexit
   	end
   
   select @payfreq = PayFreq, @msg = Description
   	from dbo.PRGR (nolock)
   	where PRCo = @prco and PRGroup = @group 
   if @@rowcount = 0
   	begin
   	select @msg = 'PR Group not on file!', @rcode = 1
   	goto bspexit
   	end
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPRPCGroupVal] TO [public]
GO
