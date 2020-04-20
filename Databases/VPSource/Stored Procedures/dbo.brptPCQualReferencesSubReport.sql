SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================  
-- Author:  Mike Brewer  
-- Create date: 4/27/09  
-- Description: PCQualificationReport, States subreport  
--Null values are used if enduser chooses Blank Form  
-- =============================================  
CREATE PROCEDURE [dbo].[brptPCQualReferencesSubReport]  
-- @Type  varchar(12) --Report or Blank Form  
 @Vendor bVendor, @VendorGroup bGroup  
AS  
BEGIN  
  
select   
'R' as 'CRType',  
NULL as 'Line',  
PCR.Vendor as 'Vendor',  
PCR.VendorGroup as 'VendorGroup',  
PCR.ReferenceTypeCode as 'ReferenceTypeCode',  
(select [Description] from PCReferenceTypeCodes   
 where VendorGroup = PCR.VendorGroup   
 and ReferenceTypeCode = PCR.ReferenceTypeCode) as 'ReferenceTypeDesc',  
PCR.Contact as 'Contact',  
PCR.Company as 'Company',  
PCR.[Address] as 'Address',  
PCR.City as 'City',  
PCR.[State] as 'State',  
PCR.Zip as 'Zip',  
PCR.Country as 'Country',  
PCR.Phone as 'Phone',  
PCR.Fax as 'Fax',  
PCR.Email as 'Email',
PCR.Notes as 'Notes'  
from PCReferences PCR  
where Vendor = @Vendor  
and VendorGroup = @VendorGroup  
  
Union all  
  
select 'B' as 'CRType', '1' as 'Line', NULL as 'Vendor', NULL as 'VendorGroup',   
NULL as 'ReferenceTypeCode', NULL as 'ReferenceTypeDesc', NULL as 'Contact',  
NULL as 'Company', NULL as 'Address', NULL as 'City', NULL as 'State',  
NULL as 'Zip', NULL as 'Country', NULL as 'Phone', NULL as 'Fax', NULL as 'Email', Null as 'Notes'  
Union all  
  
select 'B' as 'CRType', '2' as 'Line', NULL as 'Vendor', NULL as 'VendorGroup',   
NULL as 'ReferenceTypeCode', NULL as 'ReferenceTypeDesc', NULL as 'Contact',  
NULL as 'Company', NULL as 'Address', NULL as 'City', NULL as 'State',  
NULL as 'Zip', NULL as 'Country', NULL as 'Phone', NULL as 'Fax', NULL as 'Email', Null as 'Notes'   
  
Union all  
  
select 'B' as 'CRType', '3' as 'Line', NULL as 'Vendor', NULL as 'VendorGroup',   
NULL as 'ReferenceTypeCode', NULL as 'ReferenceTypeDesc', NULL as 'Contact',  
NULL as 'Company', NULL as 'Address', NULL as 'City', NULL as 'State',  
NULL as 'Zip', NULL as 'Country', NULL as 'Phone', NULL as 'Fax', NULL as 'Email', Null as 'Notes'   
  
Union all  
  
select 'B' as 'CRType', '4' as 'Line', NULL as 'Vendor', NULL as 'VendorGroup',   
NULL as 'ReferenceTypeCode', NULL as 'ReferenceTypeDesc', NULL as 'Contact',  
NULL as 'Company', NULL as 'Address', NULL as 'City', NULL as 'State',  
NULL as 'Zip', NULL as 'Country', NULL as 'Phone', NULL as 'Fax', NULL as 'Email', Null as 'Notes'   
  
Union all  
  
select 'B' as 'CRType', '5' as 'Line', NULL as 'Vendor', NULL as 'VendorGroup',   
NULL as 'ReferenceTypeCode', NULL as 'ReferenceTypeDesc', NULL as 'Contact',  
NULL as 'Company', NULL as 'Address', NULL as 'City', NULL as 'State',  
NULL as 'Zip', NULL as 'Country', NULL as 'Phone', NULL as 'Fax', NULL as 'Email', Null as 'Notes'   
  
End  
  
GO
GRANT EXECUTE ON  [dbo].[brptPCQualReferencesSubReport] TO [public]
GO
