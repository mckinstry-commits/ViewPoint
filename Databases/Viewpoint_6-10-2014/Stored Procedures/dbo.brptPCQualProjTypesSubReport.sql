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
CREATE PROCEDURE [dbo].[brptPCQualProjTypesSubReport]
--	@Type  varchar(12) --Report or Blank Form
 @Vendor bVendor, @VendorGroup bGroup
AS
BEGIN


select 
'R' as 'CRType',
NULL as 'Line',
PCP.Vendor as 'Vendor',
PCP.VendorGroup as 'VendorGroup',
PCP.ProjectTypeCode as 'ProjectTypeCode',
(select left([Description], 30) from PCProjectTypeCodes where VendorGroup = PCP.VendorGroup and ProjectTypeCode = PCP.ProjectTypeCode) as 'ProjectTypeDesc',
CONVERT(varchar(12), CONVERT (decimal(6,2), PCP.WorkPrevious * 100 )) as 'WorkPrevious%',
Convert(varchar(12), Convert (decimal(6,2), PCP.WorkNext * 100     ))  as 'WorkNext%',
case PCP.NoPriorWork when 'Y' then 'X' else '' end as 'NoPriorWork'
from PCProjectTypes PCP
where Vendor = @Vendor
and VendorGroup = @VendorGroup


Union all

select 'B' as 'CRType', '1' as 'Line', NULL as 'Vendor', NULL as 'VendorGroup', 
NULL as 'ProjectTypeCode', NULL as 'ProjectTypeDesc', NULL as 'WorkPrevious%', NULL as 'WorkNext%', NULL as 'NoPriorWork'

Union all

select 'B' as 'CRType', '2' as 'Line', NULL as 'Vendor', NULL as 'VendorGroup', 
NULL as 'ProjectTypeCode', NULL as 'ProjectTypeDesc', NULL as 'WorkPrevious%', NULL as 'WorkNext%', NULL as 'NoPriorWork'

Union all

select 'B' as 'CRType', '3' as 'Line', NULL as 'Vendor', NULL as 'VendorGroup', 
NULL as 'ProjectTypeCode', NULL as 'ProjectTypeDesc', NULL as 'WorkPrevious%', NULL as 'WorkNext%', NULL as 'NoPriorWork'

Union all

select 'B' as 'CRType', '4' as 'Line', NULL as 'Vendor', NULL as 'VendorGroup', 
NULL as 'ProjectTypeCode', NULL as 'ProjectTypeDesc', NULL as 'WorkPrevious%', NULL as 'WorkNext%', NULL as 'NoPriorWork'

Union all

select 'B' as 'CRType', '5' as 'Line', NULL as 'Vendor', NULL as 'VendorGroup', 
NULL as 'ProjectTypeCode', NULL as 'ProjectTypeDesc', NULL as 'WorkPrevious%', NULL as 'WorkNext%', NULL as 'NoPriorWork'

End

GO
GRANT EXECUTE ON  [dbo].[brptPCQualProjTypesSubReport] TO [public]
GO
