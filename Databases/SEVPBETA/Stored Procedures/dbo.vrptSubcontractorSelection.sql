SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================            
-- Author:  Mike Brewer            
-- Create date: 5/21/09          
-- Description: This Procedure will be used for the          
-- Subcontractor selection Report. This report will ask for a variety             
-- of criteria such as geographic region, Work scope, size of project, etc,             
-- and print a list of all subs that meet the entered criteria.            
-- Modifications:	12/2/2010 - #138790 HH added handles for empty input parameters and changed where clause
-- =============================================            
CREATE PROCEDURE [dbo].[vrptSubcontractorSelection]            
            
(@GLCO int,
@GeoRegion varchar(10),            
@ScopeDescription varchar (60),            
@ProjectType varchar (60),            
@Size numeric (18,0)
)            
            
            
            
AS            
BEGIN            
 -- SET NOCOUNT ON added to prevent extra result sets from            
 -- interfering with SELECT statements.            
SET NOCOUNT ON;            
--          
--declare @GeoRegion varchar(10)            
--set @GeoRegion = 'AZ'            
--            
--declare @ScopeDescription varchar (60)            
--set @ScopeDescription = NULL          
--          
--declare @ProjectType varchar (60)          
--set @ProjectType = Null          
--            
--declare @Size numeric (18,0)            
--set  @Size = 50000            
--          
----declare @VendorGroup int          
----set @VendorGroup = 30          
--          
--declare @GLCO int          
--set @GLCO = 1          
          
  
declare @VendorGroup int  
  
select @VendorGroup = VendorGroup from HQCO  
where HQCo = @GLCO  
  
  
            
--convert empty stings to Nulls          
--set @GeoRegion = nullif(@GeoRegion, '')   
declare @AllRegionCode int
if @GeoRegion is null or @GeoRegion = ''
	begin
		set @AllRegionCode = 1
	end
else
	set @AllRegionCode = 0
set @GeoRegion = isnull(@GeoRegion, '')  
      
--set @ScopeDescription = nullif(@ScopeDescription, '')            
declare @AllScopeCode int
if @ScopeDescription is null or @ScopeDescription = ''
	begin
		set @AllScopeCode = 1
	end
else
	set @AllScopeCode = 0
set @ScopeDescription = isnull(@ScopeDescription, '')      
      
--set @ProjectType = nullif(@ProjectType, '');   
declare @AllProjectTypeCode int
if @ProjectType is null or @ProjectType = ''
	begin
		set @AllProjectTypeCode = 1
	end
else
	set @AllProjectTypeCode = 0     
set @ProjectType = isnull(@ProjectType, '');      
          
          
select distinct
@GLCO as 'GLCo',          
(select [Name]  from HQCO where HQCo = @GLCO) as 'CompanyName',          
Q.[Name],            
Q.Vendor,            
Q.VendorGroup,          
Q.City,           
Q.[State],          
Q.Phone,            
Q.EMail,            
Q.URL ,          
@GeoRegion as 'RegionInput',          
@ProjectType as 'ProjectTypeInput',          
isnull(@Size,0) as 'SizeInput',          
@ScopeDescription as 'ScopeInput'        
--WR.RegionCode,      
--S.ScopeCode,      
--PTC.ProjectTypeCode,      
--Q.LargestEverAmount,        
--Q.LargestThisYearAmount,      
--Q.LargestLastYearAmount      
--'--------params to the right',      
--@GeoRegion as 'R',      
--@ScopeDescription as 'S',      
--@ProjectType as 'PT',      
--@Size as 'Si'      
from PCQualifications Q            
left join PCWorkRegions WR            
  on Q.VendorGroup = WR.VendorGroup            
  and Q.Vendor = WR.Vendor            
left join PCRegionCodes RC            
  on WR.VendorGroup = RC.VendorGroup            
  and WR.RegionCode = RC.RegionCode            
left join PCScopes S            
  on Q.VendorGroup = S.VendorGroup            
  and Q.Vendor = S.Vendor            
left join PCScopeCodes SC            
  on S.VendorGroup = SC.VendorGroup            
  and S.ScopeCode = SC.ScopeCode            
left join PCProjectTypes PCPT            
  on  Q.Vendor = PCPT.Vendor            
  and Q.VendorGroup = PCPT.VendorGroup            
left join PCProjectTypeCodes PTC            
  on PCPT.VendorGroup = PTC.VendorGroup            
  and PCPT.ProjectTypeCode = PTC.ProjectTypeCode            
where Q.GLCo = @GLCO      
and Q.VendorGroup = @VendorGroup    
and Q.[Name] is not null        
and (@AllRegionCode = 1 or WR.RegionCode = @GeoRegion)
and (@AllScopeCode = 1 or S.ScopeCode = @ScopeDescription)            
and (@AllProjectTypeCode = 1 or PTC.ProjectTypeCode = @ProjectType)
and( isnull(Q.LargestEverAmount,0) >= @Size            
   or isnull(Q.LargestThisYearAmount,0) >= @Size           
   or isnull(Q.LargestLastYearAmount,0) >= @Size)
  
End      
      
  
GO
GRANT EXECUTE ON  [dbo].[vrptSubcontractorSelection] TO [public]
GO
