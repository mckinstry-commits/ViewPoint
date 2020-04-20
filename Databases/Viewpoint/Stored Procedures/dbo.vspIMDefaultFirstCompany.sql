SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspIMDefaultFirstCompany]
   /************************************************************************
   * CREATED:  DanF 06/26/2007 
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *   return first hq company greater than zero
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successful 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
   ( @hqco bCompany = null output, @msg varchar(80) = null output)
   
as
set nocount on
   
declare @rcode int
   
select @rcode = 0
   
select top 1 @hqco = HQCo 
from HQCO with (nolock)
where HQCo > 0 order by HQCo

  
bspexit:
   
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspIMDefaultFirstCompany] TO [public]
GO
