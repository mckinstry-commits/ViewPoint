SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspPRGetFreqList]
/*************************************
* Created: GG 05/16/07
* Modified:
* 
* Returns a resultset of Frequency codes used by PR D/Ls
*
* Input:
*	@prco			PR Company
*
* Output:
*	resultset of Frequency codes
*
**************************************/
(@prco bCompany)

as 
set nocount on
 
--return a list of Frequency codes with their Description  
select distinct d.Frequency, f.Description
from dbo.bPRDL d (nolock)
join dbo.bHQFC f (nolock) on d.Frequency = f.Frequency
where d.PRCo = @prco and d.AutoAP = 'Y'
union
select distinct e.Frequency, f.Description
from dbo.bPREC e (nolock)
join dbo.bHQFC f (nolock) on e.Frequency = f.Frequency
where e.PRCo = @prco and e.AutoAP = 'Y'


vspexit:
  	return

GO
GRANT EXECUTE ON  [dbo].[vspPRGetFreqList] TO [public]
GO
