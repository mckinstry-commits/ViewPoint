SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPRDeptDesc    Script Date: 8/28/99 9:33:17 AM ******/
  CREATE   proc dbo.vspPRDeptDesc
  /***********************************************************
   * CREATED BY: EN 11/04/05
   * MODIFIED By : 
   *
   * USAGE:
   *	Used in PRDept to return description to the key field.
   *
   * INPUT PARAMETERS
   *   PRCo   PR Co to validate agains 
   *   Dept   PR Department to validate
   * OUTPUT PARAMETERS
   *   @msg      Description of Department
   * RETURN VALUE
   *   0         success
   *   1         Failure
   *****************************************************/ 
  
  	(@prco bCompany = 0, @dept bDept = null, @msg varchar(60) output)
  as
  
  set nocount on
  
  declare @rcode int
  
  select @rcode = 0, @msg = ''
  
  if @prco is not null and isnull(@dept,'') <> ''
	begin
	select @msg = Description from dbo.PRDP with (nolock) where PRCo = @prco and PRDept=@dept 
  	end
  
  bspexit:
  	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPRDeptDesc] TO [public]
GO
