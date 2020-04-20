SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSPCTruck] as 
/***************************************
* Created: ??
* Modified: GG 04/10/08 - added top 100 percent and order by, commented out unused joins 
*
* Used to list Pay Codes from all MS companies
*
*************************************/
select distinct top 100 percent (a.PayCode), min(a.Description) as PayCodeDesc
from MSPC a (nolock)
--left join MSVT b on b.PayCode=a.PayCode
--left join HQCO c on c.HQCo=a.MSCo and c.VendorGroup=b.VendorGroup
group by a.PayCode
order by a.PayCode

GO
GRANT SELECT ON  [dbo].[MSPCTruck] TO [public]
GRANT INSERT ON  [dbo].[MSPCTruck] TO [public]
GRANT DELETE ON  [dbo].[MSPCTruck] TO [public]
GRANT UPDATE ON  [dbo].[MSPCTruck] TO [public]
GRANT SELECT ON  [dbo].[MSPCTruck] TO [Viewpoint]
GRANT INSERT ON  [dbo].[MSPCTruck] TO [Viewpoint]
GRANT DELETE ON  [dbo].[MSPCTruck] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[MSPCTruck] TO [Viewpoint]
GO
