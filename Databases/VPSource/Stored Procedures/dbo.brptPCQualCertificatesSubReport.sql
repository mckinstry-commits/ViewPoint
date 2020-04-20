SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================    
-- Author:  Mike Brewer    
-- Create date: 4/27/09    
-- Description: PCCertificateSubreportReport, States subreport    
--Null values are used if enduser chooses Blank Form   
--Added Exp Date 8/3/2010 MB 
-- =============================================    
CREATE PROCEDURE [dbo].[brptPCQualCertificatesSubReport]    
-- @Type  varchar(12) --Report or Blank Form    
 @Vendor bVendor, @VendorGroup bGroup    
AS    
BEGIN    
  
select  
'R' as 'CRType',    
NULL as 'Line',    
PCC.Vendor as 'Vendor',    
PCC.VendorGroup as 'VendorGroup',    
PCC.CertificateType as 'CertificateType',   
PCCT.Description as 'Description',  
PCC.Certificate as 'Certificate',  
PCC.Agency as 'Agency',
PCC.ExpDate as 'ExpDate'  
from  
PCCertificates PCC join  
PCCertificateTypes PCCT   
on PCC.VendorGroup = PCCT.VendorGroup  
and PCC.CertificateType = PCCT.CertificateType  
where PCC.Vendor = @Vendor    
and PCC.VendorGroup = @VendorGroup    


    
Union all    
    
select 'B' as 'CRType',   
'1' as 'Line',   
NULL as 'Vendor',   
NULL as 'VendorGroup',     
NULL as 'CertificateType',   
NULL as 'Description',  
NULL as 'Certificate',  
NULL as 'Agency',
Null as 'ExpDate'  
  
Union all    
    
select 'B' as 'CRType',   
'2' as 'Line',   
NULL as 'Vendor',   
NULL as 'VendorGroup',     
NULL as 'CertificateType',   
NULL as 'Description',  
NULL as 'Certificate',  
NULL as 'Agency',
Null as 'ExpDate'  
  
Union all    
    
select 'B' as 'CRType',   
'3' as 'Line',   
NULL as 'Vendor',   
NULL as 'VendorGroup',     
NULL as 'CertificateType',   
NULL as 'Description',  
NULL as 'Certificate',  
NULL as 'Agency',
Null as 'ExpDate'   
  
Union all    
    
select 'B' as 'CRType',   
'4' as 'Line',   
NULL as 'Vendor',   
NULL as 'VendorGroup',     
NULL as 'CertificateType',   
NULL as 'Description',  
NULL as 'Certificate',  
NULL as 'Agency',
Null as 'ExpDate'    
  
Union all    
    
select 'B' as 'CRType',   
'5' as 'Line',   
NULL as 'Vendor',   
NULL as 'VendorGroup',     
NULL as 'CertificateType',   
NULL as 'Description',  
NULL as 'Certificate',  
NULL as 'Agency',
Null as 'ExpDate'   
    
End
GO
GRANT EXECUTE ON  [dbo].[brptPCQualCertificatesSubReport] TO [public]
GO
