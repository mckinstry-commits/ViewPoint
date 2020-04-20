SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Mike Brewer
-- Create date: 4/27/09
-- Description:	PCQualificationReport, States subreport
--Null values are used if enduser chooses Blank Form
-- =============================================
CREATE PROCEDURE [dbo].[brptPCQualRegionsSubReport]
--	@Type  varchar(12) --Report or Blank Form
 @Vendor bVendor, @VendorGroup bGroup
AS
BEGIN

select 
'R' as 'CRType',
NULL as 'Line',
PCW.Vendor as 'Vendor',
PCW.VendorGroup as 'VendorGroup',
PCW.RegionCode as 'RegionCode',
(select [Description] from PCRegionCodes where VendorGroup = PCW.VendorGroup and RegionCode = PCW.RegionCode) as 'Region Desc',
CONVERT(varchar(12), CONVERT (decimal(6,2), PCW.WorkPrevious * 100 )) as 'WorkPrevious%',
Convert(varchar(12), Convert (decimal(6,2), PCW.WorkNext * 100     ))  as 'WorkNext%',
case PCW.NoPriorWork when 'Y' then 'X' else '' end as 'NoPriorWork'
from PCWorkRegions PCW
where Vendor = @Vendor
and VendorGroup = @VendorGroup

Union all

select 'B' as 'CRType', '1' as 'Line', NULL as 'Vendor', NULL as 'VendorGroup', 
NULL as 'RegionCode', NULL as 'Region Desc', NULL as 'WorkPrevious%', NULL as 'WorkNext%', NULL as 'NoPriorWork'

Union all

select 'B' as 'CRType', '2' as 'Line', NULL as 'Vendor', NULL as 'VendorGroup', 
NULL as 'RegionCode', NULL as 'Region Desc', NULL as 'WorkPrevious%', NULL as 'WorkNext%', NULL as 'NoPriorWork'

Union all

select 'B' as 'CRType', '3' as 'Line', NULL as 'Vendor', NULL as 'VendorGroup', 
NULL as 'RegionCode', NULL as 'Region Desc', NULL as 'WorkPrevious%', NULL as 'WorkNext%', NULL as 'NoPriorWork'

Union all

select 'B' as 'CRType', '4' as 'Line', NULL as 'Vendor', NULL as 'VendorGroup', 
NULL as 'RegionCode', NULL as 'Region Desc', NULL as 'WorkPrevious%', NULL as 'WorkNext%', NULL as 'NoPriorWork'

Union all

select 'B' as 'CRType', '5' as 'Line', NULL as 'Vendor', NULL as 'VendorGroup', 
NULL as 'RegionCode', NULL as 'Region Desc', NULL as 'WorkPrevious%', NULL as 'WorkNext%', NULL as 'NoPriorWork'

END

GO
GRANT EXECUTE ON  [dbo].[brptPCQualRegionsSubReport] TO [public]
GO
