SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[GLAcctNoCompany]
/*******************************
* Created: ??
* Modified: GG 04/10/08 - added top 100 percent and order by
*
* Used to provide a list of GL Accounts across all GL companies
*
******************************/
as
select top 100 percent GLAcct, min(Description) as Description
from bGLAC (nolock)
group by GLAcct
order by GLAcct

GO
GRANT SELECT ON  [dbo].[GLAcctNoCompany] TO [public]
GRANT INSERT ON  [dbo].[GLAcctNoCompany] TO [public]
GRANT DELETE ON  [dbo].[GLAcctNoCompany] TO [public]
GRANT UPDATE ON  [dbo].[GLAcctNoCompany] TO [public]
GRANT SELECT ON  [dbo].[GLAcctNoCompany] TO [Viewpoint]
GRANT INSERT ON  [dbo].[GLAcctNoCompany] TO [Viewpoint]
GRANT DELETE ON  [dbo].[GLAcctNoCompany] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[GLAcctNoCompany] TO [Viewpoint]
GO
