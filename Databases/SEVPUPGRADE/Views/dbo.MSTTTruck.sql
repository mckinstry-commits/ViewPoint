SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSTTTruck] as 
/***************************************
* Created: ??
* Modified: GG 04/10/08 - added top 100 percent and order by, commented out unused joins 
*
* Used to list Truck Types from all MS companies
*
*************************************/
select distinct top 100 percent(a.TruckType), min(a.Description) as TruckTypeDesc
from MSTT a (nolock)
--left join MSVT b on b.TruckType=a.TruckType
--left join HQCO c on c.HQCo=a.MSCo and c.VendorGroup=b.VendorGroup
group by a.TruckType
order by a.TruckType

GO
GRANT SELECT ON  [dbo].[MSTTTruck] TO [public]
GRANT INSERT ON  [dbo].[MSTTTruck] TO [public]
GRANT DELETE ON  [dbo].[MSTTTruck] TO [public]
GRANT UPDATE ON  [dbo].[MSTTTruck] TO [public]
GO
