SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPREarnDesc    Script Date: 8/28/99 9:33:17 AM ******/
  CREATE    proc dbo.vspPREarnCodeDesc
  /***********************************************************
   * CREATED BY: EN 1/18/06
   * MODIFIED By : 
   *
   * USAGE:
   *	Used in PREarnCode to return description to the key field.
   *
   * INPUT PARAMETERS
   *   PRCo   PR Co to validate agains 
   *   Earn   PR earnings code to validate
   * OUTPUT PARAMETERS
   *   @msg      Description of Earnings Code
   * RETURN VALUE
   *   0         success
   *   1         Failure
   *****************************************************/ 
  
  	(@prco bCompany = 0, @earncode bEDLCode = null, @msg varchar(60) output)
  as
  
  set nocount on
  
  declare @rcode int
  
  select @rcode = 0, @msg = ''
  
  if @prco is not null and isnull(@earncode,'') <> ''
	begin
	select @msg = Description from dbo.PREC with (nolock) where PRCo = @prco and EarnCode=@earncode 
  	end
  
  bspexit:
  	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPREarnCodeDesc] TO [public]
GO
