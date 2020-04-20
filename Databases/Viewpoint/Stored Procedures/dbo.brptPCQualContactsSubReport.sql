SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[brptPCQualContactsSubReport]    Script Date: 05/19/2009 15:58:17 ******/    
    
-- =============================================    
-- Author:  Mike Brewer    
-- Create date: 4/27/09    
-- Description: PCQualificationReport, Contacts subreport    
--Null values are used if enduser chooses Blank Form    
-- =============================================    
CREATE PROCEDURE [dbo].[brptPCQualContactsSubReport]    
-- @Type  varchar(12) --Report or Blank Form    
 @Vendor bVendor, @VendorGroup bGroup    
AS    
BEGIN    
  Select  
  'R' as 'CRType',    
  Null as 'Line',    
  NULL as 'GLCo',   
  PC.VendorGroup as 'VendorGroup',    
  PC.Vendor as 'Vendor',   
  PC.IsBidContact as 'BidContact',   
  PC.ContactTypeCode as 'ContactTypeCode',   
  ( select [Description]    
   from dbo.PCContactTypeCodes     
   where VendorGroup = PC.VendorGroup     
   and ContactTypeCode = PC.ContactTypeCode) as 'ContactTypeDescription',    
  PC.[Name] as 'Name',    
  PC.Title as 'Title',    
  PC.CompanyYears as 'CompanyYears',    
  PC.RoleYears as 'RoleYears',    
  PC.Phone as 'Phone',    
  PC.Cell as 'Cell',    
  PC.Fax as 'Fax',  
  PC.Email as 'Email',    
 case PC.PrefMethod  
 when 'E' then 'E - Email'  
 when 'F' then 'F - Fax'  
 when 'M' then 'M - Print'  
 else '' end as 'PreferredMethod', 
 IsBidContact  
  from PCContacts PC    
  where Vendor = @Vendor    
  and VendorGroup = @VendorGroup    
  
    
Union all    
  
Select   
'B' as 'CRType',    
'1' as 'Line',   
NULL as 'GLCo',   
NULL as 'VendorGroup',   
NULL as 'Vendor',   
NULL as 'BidContact',  
NULL as 'ContactTypeCode',   
NULL as 'ContactTypeDescription',  
NULL as 'Name',     
NULL as 'Title',   
NULL as 'CompanyYears',   
NULL as 'RoleYears',   
NULL as 'Phone',    
NULL as 'Cell',   
Null as 'Fax',  
NULL as 'Email',   
Null as 'PreferredMethod', 
Null as 'IsBidContact'    
  
Union all    
  
Select   
'B' as 'CRType',    
'2' as 'Line',   
NULL as 'GLCo',   
NULL as 'VendorGroup',   
NULL as 'Vendor',   
NULL as 'BidContact',  
NULL as 'ContactTypeCode',   
NULL as 'ContactTypeDescription',  
NULL as 'Name',     
NULL as 'Title',   
NULL as 'CompanyYears',   
NULL as 'RoleYears',   
NULL as 'Phone',    
NULL as 'Cell',   
Null as 'Fax',  
NULL as 'Email',   
Null as 'PreferredMethod',
Null as 'IsBidContact'      
  
Union all    
  
Select   
'B' as 'CRType',    
'3' as 'Line',   
NULL as 'GLCo',   
NULL as 'VendorGroup',   
NULL as 'Vendor',   
NULL as 'BidContact',  
NULL as 'ContactTypeCode',   
NULL as 'ContactTypeDescription',  
NULL as 'Name',     
NULL as 'Title',   
NULL as 'CompanyYears',   
NULL as 'RoleYears',   
NULL as 'Phone',    
NULL as 'Cell',   
Null as 'Fax',  
NULL as 'Email',   
Null as 'PreferredMethod',
Null as 'IsBidContact'      
  
Union all    
  
Select   
'B' as 'CRType',    
'4' as 'Line',   
NULL as 'GLCo',   
NULL as 'VendorGroup',   
NULL as 'Vendor',   
NULL as 'BidContact',  
NULL as 'ContactTypeCode',   
NULL as 'ContactTypeDescription',  
NULL as 'Name',     
NULL as 'Title',   
NULL as 'CompanyYears',   
NULL as 'RoleYears',   
NULL as 'Phone',    
NULL as 'Cell',   
Null as 'Fax',  
NULL as 'Email',   
Null as 'PreferredMethod',
Null as 'IsBidContact'      
  
Union all    
  
Select   
'B' as 'CRType',    
'5' as 'Line',   
NULL as 'GLCo',   
NULL as 'VendorGroup',   
NULL as 'Vendor',   
NULL as 'BidContact',  
NULL as 'ContactTypeCode',   
NULL as 'ContactTypeDescription',  
NULL as 'Name',     
NULL as 'Title',   
NULL as 'CompanyYears',   
NULL as 'RoleYears',   
NULL as 'Phone',    
NULL as 'Cell',   
Null as 'Fax',  
NULL as 'Email',   
Null as 'PreferredMethod',
Null as 'IsBidContact'      
  
END    
    
GO
GRANT EXECUTE ON  [dbo].[brptPCQualContactsSubReport] TO [public]
GO
