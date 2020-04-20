SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     proc [dbo].[vspINMOInfoGet]

  /*************************************
  * CREATED BY:  TRL 10/23/05
  * Modified By:
  *
  * Gets the Available Open Matl Orders for INMOPurge
  *
  * Pass:
  *   INCo - Inventory Company  
  *
  *
  * Success returns:
  *
  *
  * Error returns:
  *	1 and error message
  **************************************/
  (@inco tinyint = null,  @mth smalldatetime = null, @msg varchar(256) output)
  as
  set nocount on
  
declare @rcode int 
  
  select @rcode = 0
  
  if @inco is null
  	begin
  	select @msg = 'Missing IN Company', @rcode = 1
  	goto vspexit
  	end
If @mth is null
  	begin
  	select @msg = 'Missing Month', @rcode = 1
  	goto vspexit
  	end
  --Get INMO information
  Select MO, Description from dbo.INMO with(nolock) where INCo = @inco And Status = 2 And InUseBatchId is null and MthClosed is not Null and MthClosed <= @mth
  vspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspINMOInfoGet] TO [public]
GO
