declare @ExpirationDate smalldatetime  
declare @JobNumber varchar(10)  
declare @SubcontractNumber varchar(30)  
declare @Contract bContract  
declare @Vendor int  
declare @GLDepartment varchar(4)  
declare @POC_PM  varchar(30)   

set @ExpirationDate  = null 
set @JobNumber   = null 
set @SubcontractNumber = null --'100159-002005' --'100159-002004' 
set @Contract   = null 
set @Vendor    = null 
set @GLDepartment  = null 
set @POC_PM    = null  

--select * from dbo.mfnSLComplianceAuditReport(@ExpirationDate,@JobNumber,@SubcontractNumber,@Contract,@Vendor,@GLDepartment,@POC_PM)
--select * from SLHD where SL= '100159-002004' 

select  
	sl.* 
, sl.CompType as SLCompType 
, sl.Complied as SLComplied 
, sl.ExpDate as SLExpDate 
, hqcp.CompType as VMCompType 
, apvc.APCo
, apvc.Complied as VMComplied 
, apvc.ExpDate  as VMExpDate 
, 'UPDATE SLCT set VendorGroup=' + cast(sl.VendorGroup as varchar(10)) + ', Vendor=' + cast(sl.Vendor as varchar(20)) + ' WHERE SLCo=' + cast(sl.SLCo as varchar(10)) + ' AND SL=''' + sl.Subcontract + ''' AND CompCode=''' + sl.CompCode + ''' and ( VendorGroup<>' + cast(apvc.VendorGroup as varchar(20)) + ' or Vendor<>' + cast(apvc.Vendor as varchar(20)) + ' or VendorGroup is null or Vendor is null)' as UpdateVendorSQL
, 'UPDATE SLCT set ExpDate=''' + convert(varchar(10),apvc.ExpDate,101) + ''', Complied=' + coalesce('''' + apvc.Complied + '''','null') + ' WHERE SLCo=' + cast(sl.SLCo as varchar(10)) + ' AND SL=''' + sl.Subcontract + ''' AND CompCode=''' + sl.CompCode + ''' and VendorGroup=' +cast(apvc.VendorGroup as varchar(20)) + ' and Vendor=' + cast(apvc.Vendor as varchar(20)) + ' and (ExpDate<>''' + convert(varchar(10),apvc.ExpDate,101) + ''' or Complied<>' + coalesce('''' + apvc.Complied + '''','null') + ')' as UpdateSQLWithVendor
, 'UPDATE SLCT set ExpDate=''' + convert(varchar(10),apvc.ExpDate,101) + ''', Complied=' + coalesce('''' + apvc.Complied + '''','null') + ' WHERE SLCo=' + cast(sl.SLCo as varchar(10)) + ' AND SL=''' + sl.Subcontract + ''' AND CompCode=''' + sl.CompCode + ''' and /* VendorGroup=' +cast(apvc.VendorGroup as varchar(20)) + ' and Vendor=' + cast(apvc.Vendor as varchar(20)) + ' and */ (ExpDate<>''' + convert(varchar(10),apvc.ExpDate,101) + ''' or Complied<>' + coalesce('''' + apvc.Complied + '''','null') + ')' as UpdateSQL
from   
	dbo.mfnSLComplianceAuditReport(@ExpirationDate,@JobNumber,@SubcontractNumber,@Contract,@Vendor,@GLDepartment,@POC_PM) sl join  
	APVC apvc on
		sl.SLCo=apvc.APCo
	and sl.VendorGroup=apvc.VendorGroup  
	and sl.Vendor=apvc.Vendor  
	and sl.CompCode=apvc.CompCode join  
	HQCP hqcp on   
		apvc.CompCode=hqcp.CompCode  
	and sl.CompType=hqcp.CompType 
where  
	sl.ExpDate <> apvc.ExpDate 
or sl.Complied <> apvc.Complied
order by  
	sl.SLCo 
,	sl.Subcontract 
,	sl.CompCode


