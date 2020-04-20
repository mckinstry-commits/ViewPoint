SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[vspAPPayCategoryDesc]
  /***************************************************
  * CREATED BY    : MV 
  * LAST MODIFIED : 
  * Usage:
  *   Returns description to APPayCategory form
  *
  * Input:
  *	@apco         AP Company
  *	@paytype      AP Pay Category
  *
  * Output:
  *   @msg          Pay Catedescription 
  *
  * Returns:
  *	0             success
  *   1             error
  *************************************************/
  	(@apco bCompany = null, @paycategory int = 0,@msg varchar(60) output)
  as
  
  set nocount on
  
  declare @rcode int
  
  select @rcode = 0
  
  if @apco is null
  	begin
  	select @msg = 'Missing AP Company', @rcode = 1
  	goto bspexit
  	end
  
  if @paycategory is null
  	begin
  	select @msg = 'Missing Pay Category', @rcode = 1
  	goto bspexit
  	end
  
  select @msg = Description  from bAPPC with (nolock)
	 where APCo = @apco and PayCategory = @paycategory
 
  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPPayCategoryDesc] TO [public]
GO
