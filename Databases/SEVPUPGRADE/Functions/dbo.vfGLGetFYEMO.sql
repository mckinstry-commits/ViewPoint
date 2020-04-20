SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE function [dbo].[vfGLGetFYEMO]
(@glco bCompany = null, @mth bMonth = null)
returns bMonth
/***********************************************************
* CREATED BY	: GG 06/26/06
* MODIFIED BY	
*
* USAGE:
* 	Returns Fiscal Year Ending Month given a GL Co# and Month
*
* INPUT PARAMETERS:
*	@glco		GL Company
*	@mth		Month
*
* OUTPUT PARAMETERS:
*	@fyemo		Fiscal Year Ending Month
*	
*
*****************************************************/
as
begin

declare @fyemo bMonth

select @fyemo = FYEMO
from bGLFY (nolock)
where GLCo = @glco and @mth >= BeginMth and @mth <= FYEMO

exitfunction:
  			
return @fyemo
end

GO
GRANT EXECUTE ON  [dbo].[vfGLGetFYEMO] TO [public]
GO
