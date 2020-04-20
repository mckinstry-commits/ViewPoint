SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPRCraftVal    Script Date: 8/28/99 9:33:15 AM ******/
  CREATE    proc [dbo].[vspPRCraftVal]
  /***********************************************************
   * CREATED BY	: EN 5/20/05
   * MODIFIED BY	: 
   *
   * USAGE:
   * validates PR Craft from PRCM ... like bspPRCraft except returns YN value to say whether bPRCS entries exist
   * an error is returned if any of the following occurs
   *
   * INPUT PARAMETERS
   *   PRCo   PR Co to validate agains t
   *   Craft  PR Craft to validate against
   * OUTPUT PARAMETERS
   *   @PRCSExistsYN	equals 'Y' if PRCS entries exist for Craft
   *   @msg      error message if error occurs otherwise Description of Ded/Earnings/Liab Code
   * RETURN VALUE
   *   0         success
   *   1         Failure
   ******************************************************************/ 
  
  	(@prco bCompany = 0, @craft bCraft = null, @PRCSExistsYN bYN output, @msg varchar(90) output)
  as
  
  set nocount on
  
  declare @rcode int
  
  select @rcode = 0
  
  if @prco is null
  	begin
  	select @msg = 'Missing PR Company!', @rcode = 1
  	goto bspexit
  	end
  
  if @craft is null
  	begin
  	select @msg = 'Missing PR Craft!', @rcode = 1
  	goto bspexit
  	end
  
  select @msg=Description from PRCM where PRCo=@prco and Craft=@craft
  if @@rowcount = 0
  	begin
  	select @msg = 'Craft not on file!', @rcode = 1 	goto bspexit
  	end
  
  select @PRCSExistsYN='N'
  if (select count(*) from dbo.PRCS (nolock) where PRCo=@prco and Craft=@craft)>0 select @PRCSExistsYN='Y'

  bspexit:
  	
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPRCraftVal] TO [public]
GO
