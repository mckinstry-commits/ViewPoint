SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPRGroupDesc    Script Date: 8/28/99 9:33:17 AM ******/
  CREATE    proc dbo.vspPRGroupDesc
  /***********************************************************
   * CREATED BY: EN 11/15/05
   * MODIFIED By : 
   *
   * USAGE:
   *	Used in PRGroup to return description to the key field.
   *
   * INPUT PARAMETERS
   *   PRCo   PR Co to validate against
   *   Group  PR Group to validate
   * OUTPUT PARAMETERS
   *   @msg      Description of Group
   * RETURN VALUE
   *   0         success
   *   1         Failure
   *****************************************************/ 
  
  	(@prco bCompany = 0, @group bGroup = 0, @msg varchar(60) output)
  as
  
  set nocount on
  
  declare @rcode int
  
  select @rcode = 0, @msg = ''
  
  if @prco is not null and @group <> 0
	begin
	select @msg = Description from dbo.PRGR with (nolock) where PRCo = @prco and PRGroup=@group 
  	end
  
  bspexit:
  	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPRGroupDesc] TO [public]
GO
