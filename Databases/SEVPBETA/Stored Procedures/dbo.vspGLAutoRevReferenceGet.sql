SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspGLAutoRevReferenceGet]
/*************************************
*  Created:		GG 08/24/06
*  Modified:	GP 04/22/09 - Issue 131863, changed select to include descriptions.
*				GP 11/19/09 - Issue 136675, changed select to check RevStatus
*
*  Returns References used by GL Auto Reversal Entries
*	to populate a list.
*
*  Inputs:
*	@glco		GL Company
*	@mth		Month
*	@jrnl		Journal
*
*  Outputs:
*	 recordset of References 
*
**************************************/
(@glco bCompany = null, @mth bMonth = null, @jrnl char(2) = null)
as
 
set nocount on
  	
-- get list of distinct GL References w/description
select distinct f.GLRef, f.Description
from dbo.bGLRF f with (nolock)
join dbo.bGLDT d on d.GLCo = f.GLCo and d.Mth = f.Mth and d.Jrnl = f.Jrnl and d.GLRef = f.GLRef
where f.GLCo = @glco and f.Mth = @mth and f.Jrnl = @jrnl -- assumes non-null values, journal should be flagged for reversal
	and d.RevStatus = 0 -- not yet reversed

GO
GRANT EXECUTE ON  [dbo].[vspGLAutoRevReferenceGet] TO [public]
GO
