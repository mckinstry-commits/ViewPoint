SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.brptPOMatDrillDown    Script Date: 8/28/99 9:33:53 AM ******/      
CREATE     proc [dbo].[brptPOMatDrillDown]      
    
(@POCo bCompany,    
@BeginMaterial bMatl ='',     
@EndMaterial bMatl= 'zzzzzzzzz',      
@BeginDate bDate ='1/1/1950',     
@EndDate bDate= '12/31/2050',    
@Vendor bVendor='')    
/* created 01/8/97*/      
  
  
--declare @POCo bCompany  
--set @POCo = 1  
--  
--declare @BeginMaterial bMatl  
--set @BeginMaterial =''  
--  
--declare @EndMaterial bMatl  
--set @EndMaterial = 'zzzzzzzzz'  
--  
--declare @BeginDate bDate  
--set @BeginDate  = '2009-11-01 00:00:00'  
--  
--declare @EndDate bDate  
--set @EndDate = '2009-11-30 00:00:00'  
--  
--declare @Vendor bVendor  
--set @Vendor = 788890  
  
    
as      
    
create table #MaxUnitCost      
(POCO    tinyint    NULL,      
MatlGroup   tinyint    NULL,      
Material   varchar(20)   NULL,      
UCType    char(1)    NULL,      
VendorGroup   tinyint    Null,      
Vendor    int     Null,      
VendorMaxUC   numeric(16,5)  Null,      
VendorMaxOrderDate smalldatetime  Null,      
MaterialMaxUC  numeric(16,5)  Null,      
MaterialMaxOrderDate smalldatetime  Null )      
    
    
    
         
/* insert MaxUnitCost info for Vendor */      
insert into #MaxUnitCost      
(POCO, MatlGroup,Material,VendorGroup,Vendor,VendorMaxUC,VendorMaxOrderDate,UCType)      
     
select     
POIT.POCo,    
POIT.MatlGroup,    
POIT.Material,    
POHD.VendorGroup,    
POHD.Vendor,      
VendorMaxUC=Max(POIT.CurUnitCost),    
VendorMaxOrderDate=Max(POHD.OrderDate),    
'V'      
from POIT with(nolock)      
join POHD with(nolock) on  POIT.POCo=POHD.POCo and POIT.PO=POHD.PO        
where POHD.OrderDate =  ( select Max(p.OrderDate)       
       from POHD p with(nolock)      
       join POIT t with(nolock)     
        on p.POCo=t.POCo     
        and p.PO=t.PO     
        and POIT.POCo=t.POCo      
        and  POIT.MatlGroup=t.MatlGroup     
        and POIT.Material=t.Material      
        and POHD.VendorGroup=p.VendorGroup     
        and POHD.Vendor=p.Vendor)      
       group by POIT.MatlGroup,POIT.Material,POIT.POCo,POHD.VendorGroup,POHD.Vendor      
     
    
    
    
    
/* insert MaxUnitCost with Max Material Info */      
insert into #MaxUnitCost      
(POCO, MatlGroup,Material,MaterialMaxUC,MaterialMaxOrderDate,UCType)      
     
select     
POIT.POCo,    
POIT.MatlGroup,    
POIT.Material,     
Max(POIT.CurUnitCost),    
MAX(POHD.OrderDate),    
'M'      
from POIT with(nolock)      
join  POHD with(nolock)     
 on POIT.POCo=POHD.POCo     
 and POIT.PO=POHD.PO      
where  POHD.OrderDate =  ( select Max(p.OrderDate)       
       from POHD p with(nolock)      
       join POIT t with(nolock) on p.POCo=t.POCo     
       and p.PO=t.PO     
       and POIT.POCo=t.POCo      
       and  POIT.MatlGroup=t.MatlGroup     
       and POIT.Material=t.Material)      
group by POIT.MatlGroup,POIT.Material,POIT.POCo      
    
    
    
     
/* select the results */      
select      
CoName=HQCO.Name,     
POIT.POCo,     
POIT.PO,     
POIT.POItem,     
POIT.ItemType,     
POIT.TaxType,    
POHD.VendorGroup,     
POHD.Vendor,     
VendorName= APVM.Name,     
VendMatId=POVM.VendMatId,       
PODesc=POHD.Description,     
POHD.OrderDate,     
POIT.MatlGroup,     
POIT.Material,      
MatDesc= HQMT.Description,    
v.VendorMaxUC,     
v.VendorMaxOrderDate,    
m.MaterialMaxUC,    
m.MaterialMaxOrderDate,      
ItemDesc=POIT.Description,     
POIT.UM,     
POIT.PostToCo,     
POIT.Loc,     
POIT.Job,     
POIT.Phase,      
POIT.JCCType,     
POIT.Equip,     
POIT.CostCode,     
POIT.EMCType,     
POIT.WO,     
POIT.WOItem,     
POIT.GLCo,     
POIT.GLAcct,      
POIT.OrigUnits,     
POIT.OrigUnitCost,     
POIT.OrigECM,     
POIT.OrigCost,     
POIT.OrigTax,      
POIT.CurUnits,     
POIT.CurUnitCost,     
POIT.CurECM,     
POIT.CurCost,     
POIT.CurTax,      
POIT.RecvdUnits,     
POIT.RecvdCost,     
POIT.BOUnits,     
POIT.BOCost,     
POIT.InvUnits,      
POIT.InvCost,     
POIT.InvTax,     
POIT.RemUnits,     
POIT.RemCost,     
POIT.RemTax,     
VendorSortName=APVM.    
SortName,    
BeginMaterial=@BeginMaterial,     
EndMaterial=@EndMaterial,     
BegDate=@BeginDate,     
Enddate=@EndDate,     
Vendor=@Vendor,      
WODesc=EMWH.Description,     
JobDesc=JCJM.Description,     
LocDesc=INLM.Description,     
EqDesc=EMEM.Description,        
GLAcctDesc = GLAC.Description      
from POIT with(nolock)       
join POHD  with(nolock)     
 on POIT.POCo=POHD.POCo     
 and POIT.PO=POHD.PO      
join HQCO with(nolock)     
 on POIT.POCo=HQCO.HQCo      
join APVM with(nolock)     
 on POHD.VendorGroup=APVM.VendorGroup     
 and POHD.Vendor=APVM.Vendor      
left outer join HQMT with(nolock)     
 on POIT.MatlGroup=HQMT.MatlGroup     
 and POIT.Material=HQMT.Material      
left outer join #MaxUnitCost v with(nolock)     
 on v.UCType='V'     
 and POIT.POCo=v.POCO     
 and POIT.MatlGroup=v.MatlGroup     
 and POIT.Material=v.Material     
 and POHD.VendorGroup=v.VendorGroup      
 and POHD.Vendor=v.Vendor      
left outer join #MaxUnitCost m with(nolock)     
 on m.UCType='M'     
 and POIT.POCo=m.POCO     
 and POIT.MatlGroup=m.MatlGroup     
 and POIT.Material=m.Material      
left join POVM with(nolock)     
 on POVM.VendorGroup=v.VendorGroup     
 and POVM.Vendor=v.Vendor     
 and POVM.MatlGroup=v.MatlGroup      
 and POVM.Material=v.Material      
left outer join EMEM with(nolock)     
 on POIT.PostToCo = EMEM.EMCo     
 and POIT.Equip = EMEM.Equipment      
left outer join JCJM with(nolock)     
 on POIT.PostToCo = JCJM.JCCo     
 and POIT.Job = JCJM.Job      
left outer join INLM with(nolock)     
 on POIT.PostToCo = INLM.INCo     
 and POIT.Loc = INLM.Loc      
left outer join EMWH with(nolock)     
 on POIT.PostToCo = EMWH.EMCo     
 and POIT.WO = EMWH.WorkOrder       
left outer join GLAC with(nolock)     
 on POIT.GLCo = GLAC.GLCo     
 and POIT.GLAcct = GLAC.GLAcct      
where POIT.POCo=@POCo     
and POIT.Material>=@BeginMaterial     
and POIT.Material<=@EndMaterial     
and POHD.OrderDate>=@BeginDate       
and POHD.OrderDate<=@EndDate     
and isnull(v.Vendor,@Vendor)=(case when @Vendor=0 then  isnull(v.Vendor,@Vendor) else @Vendor end)--AA 10/11 
GO
GRANT EXECUTE ON  [dbo].[brptPOMatDrillDown] TO [public]
GO
