SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPRClassDesc    Script Date: 8/28/99 9:33:17 AM ******/
  CREATE     proc dbo.vspPRClassDesc
  /***********************************************************
   * CREATED BY: EN 11/15/05
   * MODIFIED By : 
   *
   * USAGE:
   *	Used in PRCraftClass to return description to the key field.
   *
   * INPUT PARAMETERS
   *   PRCo   PR Co to validate against
   *   Craft  PR Craft to validate against
   *   Class  PR Class to validate
   * OUTPUT PARAMETERS
   *   @msg      Description of Department
   * RETURN VALUE
   *   0         success
   *   1         Failure
   *****************************************************/ 
  
  	(@prco bCompany = 0, @craft bCraft = null, @class bClass = null, @msg varchar(60) output)
  as
  
  set nocount on
  
  declare @rcode int
  
  select @rcode = 0, @msg = ''
  
  if @prco is not null and isnull(@craft,'') <> '' and isnull(@class,'') <> ''
	begin
	select @msg = Description from dbo.PRCC with (nolock) where PRCo = @prco and Craft=@craft and Class=@class 
  	end
  
  bspexit:
  	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPRClassDesc] TO [public]
GO
