SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSHaulCodeNoCompany] as
/****************************************
* Created: ??
* Modified: GG 04/10/08 - added top 100 percent and order by
*
* Used to list Haul Codes from all MS companies
*
******************************************/ 
select top 100 percent HaulCode, min(Description) as Description
from bMSHC (nolock)
group by HaulCode
order by HaulCode

GO
GRANT SELECT ON  [dbo].[MSHaulCodeNoCompany] TO [public]
GRANT INSERT ON  [dbo].[MSHaulCodeNoCompany] TO [public]
GRANT DELETE ON  [dbo].[MSHaulCodeNoCompany] TO [public]
GRANT UPDATE ON  [dbo].[MSHaulCodeNoCompany] TO [public]
GO
