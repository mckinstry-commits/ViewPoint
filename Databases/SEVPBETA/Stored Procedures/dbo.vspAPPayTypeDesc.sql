SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[vspAPPayTypeDesc]
  /***************************************************
  * CREATED BY    : MV 
  * LAST MODIFIED : 
  * Usage:
  *   Returns description to APPayableType form
  *
  * Input:
  *	@apco         AP Company
  *	@paytype      AP Pay Type
  *
  * Output:
  *   @msg          Pay Type description 
  *
  * Returns:
  *	0             success
  *   1             error
  *************************************************/
  	(@apco bCompany = null, @paytype tinyint = 0,@msg varchar(60) output)
  as
  
  set nocount on
  
  declare @rcode int
  
  select @rcode = 0
  
  if @apco is null
  	begin
  	select @msg = 'Missing AP Company', @rcode = 1
  	goto bspexit
  	end
  
  if @paytype is null
  	begin
  	select @msg = 'Missing Pay Type', @rcode = 1
  	goto bspexit
  	end
  
  select @msg = Description
  from bAPPT
  where APCo = @apco and PayType = @paytype 
 
  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPPayTypeDesc] TO [public]
GO
