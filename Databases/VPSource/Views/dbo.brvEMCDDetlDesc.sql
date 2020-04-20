SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

 
 
 
 
 CREATE   view [dbo].[brvEMCDDetlDesc] as
  
  select EMCD.*, 
     DetailDesc = (Case When EMCD.Source in ('PR','EMTime') then 
          ((Case when IsNull(EMCD.Description,' ')<> ' ' then  EMCD.Description +' ' else ''end)  +
          (Case when IsNull(EMCD.WorkOrder,' ')<> ' ' then 'WO: '+ EMCD.WorkOrder +' ' else '' end) +
          (Case when IsNull(EMCD.WOItem,0) <> 0 then  'Item: ' +convert(varchar(5),EMCD.WOItem)+' ' else '' end) +
          (Case when IsNull(EMCD.PRCo,0) <> 0 then 'Co: ' + convert(varchar(3),EMCD.PRCo)+' ' else '' end) + 
          (Case when IsNull(EMCD.PREmployee,0)<> 0 then  'Emp: ' + convert(varchar(6),EMCD.PREmployee)+'-'+PREH.LastName +', '+ PREH.FirstName else ''end))
                 When EMCD.Source = 'AP' then
  	((Case when IsNull(EMCD.Description,' ')<> ' ' then  EMCD.Description +' ' else ''end) + 
          (Case when IsNull(EMCD.APCo,0)<> 0 then 'Co: ' + convert(varchar(3),EMCD.APCo) +' ' else '' end) +
          (Case when IsNull(EMCD.APTrans,0) <> 0 then  'Trans#: ' + convert(varchar(7),EMCD.APTrans)+' ' else '' end) +
          (Case when IsNull(EMCD.APVendor,0) <> 0 then 'Vend: ' + convert(varchar(6),EMCD.APVendor)+'-'+APVM.Name +' ' else '' end) + 
          (Case when IsNull(EMCD.APRef,' ') <> ' ' then 'Ref: ' + EMCD.APRef +' ' else '' end) +
          (Case when IsNull(EMCD.Material,' ') <> ' ' then 'Matl: ' + EMCD.Material else '' end))
                When EMCD.Source = 'PO' then
          ((Case when IsNull(EMCD.Description,' ')<> ' ' then  EMCD.Description +' ' else ''end) + 
          (Case when IsNull(EMCD.WorkOrder,' ')<> ' ' then 'WO: '+ EMCD.WorkOrder + EMWH.Description +' ' else '' end) +
          (Case when IsNull(EMCD.WOItem,0) <> 0 then  'Item: ' +convert(varchar(5),EMCD.WOItem) +' ' else '' end)+
          (Case when IsNull(EMCD.APCo,0)<> 0 then 'Co: ' + convert(varchar(3),EMCD.APCo) +' ' else '' end) +
          (Case when IsNull(EMCD.APVendor,0) <> 0 then 'Vend: ' + convert(varchar(6),EMCD.APVendor)+' ' else '' end) + 
          (Case when IsNull(EMCD.PO,' ')<> ' ' then 'PO: ' + EMCD.PO +'  ' else '' end) +     
          (Case when IsNull(EMCD.POItem,0)<> 0 then 'Item: '+ convert(varchar(5),EMCD.POItem) else '' end ))
                When (Source = 'EMAdj' and EMTransType in ('Equip','Fuel','Parts','WO')) or 
                     (Source in ('EMFuel', 'EMParts', 'EMRev')) then
  	((Case when IsNull(EMCD.Description,' ')<> ' ' then  EMCD.Description +' ' else ''end) + 
          (Case when IsNull(EMCD.WorkOrder,' ')<> ' ' then 'WO: '+ EMCD.WorkOrder +' ' else '' end) +
          (Case when IsNull(EMCD.WOItem,0) <> 0 then  'Item: ' +convert(varchar(5),EMCD.WOItem)+' ' else '' end) +
          (Case when IsNull(EMCD.Material,' ') <> ' ' then 'Matl: ' + EMCD.Material +' ' else '' end)+ 
          (Case when IsNull(EMCD.INCo,0)<> 0 then 'Co: ' + convert(varchar(3),EMCD.INCo)+' ' else '' end) + 
          (Case when IsNull(EMCD.INLocation,' ')<> ' ' then 'Loc: ' + EMCD.INLocation else '' end))
  		Else
  	((Case when IsNull(EMCD.Description,' ')<> ' ' then EMCD.Description else ''end))end)
          
  	
  from EMCD
   left outer join APVM on EMCD.VendorGrp = APVM.VendorGroup and EMCD.APVendor = APVM.Vendor
   left outer join PREH on EMCD.PRCo = PREH.PRCo and EMCD.PREmployee = PREH.Employee
   left outer join EMWH on EMCD.EMCo = EMWH.EMCo and EMCD.WorkOrder = EMWH.WorkOrder and EMCD.Equipment = EMWH.Equipment
  
  
  
  
 
 




GO
GRANT SELECT ON  [dbo].[brvEMCDDetlDesc] TO [public]
GRANT INSERT ON  [dbo].[brvEMCDDetlDesc] TO [public]
GRANT DELETE ON  [dbo].[brvEMCDDetlDesc] TO [public]
GRANT UPDATE ON  [dbo].[brvEMCDDetlDesc] TO [public]
GO
