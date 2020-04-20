SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================      
-- Author:  Mike Brewer      
-- Create date: 10/11/09      
-- Description: PCQualificationReport      
-- =============================================      
CREATE PROCEDURE [dbo].[brptPOVendorMaterials]      
-- @Type  varchar(12) --Report or Blank Form      
(@HQCo bCompany, @BegVendor bVendor, @EndVendor bVendor)      
  
AS     
   
BEGIN      
  
SELECT   
POVM.Material,   
POVM.Vendor as 'POVendor',   
POVM.UM,   
POVM.VendMatId,   
POVM.CostOpt,   
POVM.VendorGroup,   
POVM.MatlGroup,   
APVM.Name as 'APName',   
HQMT.Description,   
APVM.Vendor as 'APVendor',   
POVM.UnitCost,   
POVM.CostECM,   
POVM.BookPrice,   
POVM.PriceECM,   
POVM.PriceDisc,   
HQCO.HQCo,   
HQCO.Name as 'COName',   
POVM.Notes  
FROM  POVM   
INNER JOIN HQCO   
 ON POVM.VendorGroup=HQCO.VendorGroup   
LEFT OUTER JOIN HQMT   
 ON POVM.MatlGroup=HQMT.MatlGroup   
 AND POVM.Material=HQMT.Material   
LEFT OUTER JOIN APVM   
 ON POVM.VendorGroup=APVM.VendorGroup   
 AND POVM.Vendor=APVM.Vendor  
WHERE  HQCO.HQCo=@HQCo   
AND POVM.Vendor>=@BegVendor   
AND POVM.Vendor<=@EndVendor  
ORDER BY POVM.VendorGroup, POVM.Vendor, POVM.MatlGroup, POVM.Material  
  
End  
  
GO
GRANT EXECUTE ON  [dbo].[brptPOVendorMaterials] TO [public]
GO
