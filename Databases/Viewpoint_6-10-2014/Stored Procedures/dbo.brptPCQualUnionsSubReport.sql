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
CREATE PROCEDURE [dbo].[brptPCQualUnionsSubReport]
--	@Type  varchar(12) --Report or Blank Form
 @Vendor bVendor, @VendorGroup bGroup
AS
BEGIN


select 
'R' as 'CRType',
NULL as 'Line',
Vendor as 'Vendor',
VendorGroup as 'VendorGroup',
Seq as 'Seq',
LocalNumber as 'LocalNumber',
[Name] as 'Name', 
Expiration as 'Epiration'
from PCUnionContracts
where Vendor = @Vendor
and VendorGroup = @VendorGroup

Union all

select 'B' as 'CRType', '1' as 'Line', NULL as 'Vendor', NULL as 'VendorGroup', 
Null as  'Seq',
Null as 'LocalNumber',
Null as 'Name', 
Null as 'Epiration'

Union all

select 'B' as 'CRType', '2' as 'Line', NULL as 'Vendor', NULL as 'VendorGroup', 
Null as  'Seq',
Null as 'LocalNumber',
Null as 'Name', 
Null as 'Epiration'

Union all

select 'B' as 'CRType', '3' as 'Line', NULL as 'Vendor', NULL as 'VendorGroup', 
Null as  'Seq',
Null as 'LocalNumber',
Null as 'Name', 
Null as 'Epiration'

Union all

select 'B' as 'CRType', '4' as 'Line', NULL as 'Vendor', NULL as 'VendorGroup', 
Null as  'Seq',
Null as 'LocalNumber',
Null as 'Name', 
Null as 'Epiration'

Union all

select 'B' as 'CRType', '5' as 'Line', NULL as 'Vendor', NULL as 'VendorGroup', 
Null as  'Seq',
Null as 'LocalNumber',
Null as 'Name', 
Null as 'Epiration'

End

GO
GRANT EXECUTE ON  [dbo].[brptPCQualUnionsSubReport] TO [public]
GO
