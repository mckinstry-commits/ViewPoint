SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     proc [dbo].[vspINMODescVal]

  /*************************************
  * CREATED BY:  DANF 03/29/2006
  * Modified By:
  *
  * Returns MO Description for Cost Adjustments
  *
  * Pass:
  *   INCo - Inventory Company
  *   MO   - Material Order  
  *
  *
  * Success returns:
  *
  *
  * Error returns:
  *	1 and error message
  **************************************/
  (@inco tinyint = null,  @MO bMO = null, @msg varchar(256) output)
  as
  set nocount on
  
declare @rcode int 
  
  select @rcode = 0
  
  if @inco is null
  	begin
  	select @msg = 'Missing IN Company', @rcode = 1
  	goto vspexit
  	end
If @MO is null
  	begin
  	select @msg = 'Missing Material Order', @rcode = 1
  	goto vspexit
  	end
  --Get INMO information
  Select @msg = Description from dbo.INMO with (nolock) where INCo = @inco and MO = @MO
  if @@rowcount = 0
      begin
      select @msg='Not a valid Material Order', @rcode=1
      goto vspexit
      end
  vspexit:
    --  if @rcode<>0 select @msg=@msg + char(13) + char(10) + '[vspINMOInfoGet]' 
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspINMODescVal] TO [public]
GO
