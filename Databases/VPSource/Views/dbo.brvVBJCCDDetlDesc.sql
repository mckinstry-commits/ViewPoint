SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE    view [dbo].[brvVBJCCDDetlDesc] as
select JCCD.*, 
         DetlDesc= Case when JCCD.Source = 'JC CostAdj' and JCCD.JCTransType ='JC' then 
                           (case when IsNull(JCCD.Description,' ') <> ' ' then JCCD.Description else '' end)
                        when JCCD.JCTransType='AP' then  
  			  (case when IsNull(JCCD.Vendor,0) <> 0 then (convert (varchar(6),IsNull(JCCD.Vendor,0))+ ' '+ left(IsNull(APVM.Name,' '),20)) else '' end) +
  			  (case when IsNull(JCCD.APRef ,' ') <>' ' then  (' '+JCCD.APRef ) else '' end)+
              (case when IsNull(JCCD.APTrans,0) <> 0  then  (' / TR# '+  convert (varchar(7),JCCD.APTrans) +'/'+ convert (varchar(5), ISNULL(JCCD.APLine,' '))) else ''   end) +
  			  (case when IsNull(JCCD.Material,' ') <> ' ' then (' / Matl: '+ JCCD.Material + '-'+ HQMT.Description) else '' end) +
  			  (case when IsNull(JCCD.APCo,0) <> 0 then ('/ APCo: '+ convert (varchar(3),JCCD.APCo)) else '' end) +
              (case when IsNull(JCCD.PO,' ') <>' ' then ('/ PO#-Line ' + JCCD.PO+'-'+convert (varchar(5),IsNull(JCCD.POItem,0)))else '' end)+
  			  (case when IsNull(JCCD.SL,' ') <> ' ' then ('/ SL#-Item ' + JCCD.SL+'-'+convert (varchar(5),IsNull(JCCD.SLItem,0)))else '' end)+
              (case when IsNull(JCCD.Description,' ') <> ' ' then JCCD.Description else '' end)   
  			 
  		       when JCCD.JCTransType ='CO' then 
              (case when IsNull(JCCD.ACO,' ') <> ' ' then (JCCD.ACO +' /Item '+JCCD.ACOItem+ IsNull(JCOI.Description,isNull(JCOH.Description,' '))) else '' end) +
              (case when IsNull(JCCD.Description,' ') <> ' ' then JCCD.Description else '' end)            
  		      
               when JCCD.JCTransType='EM' then 
              (Case when IsNull(JCCD.EMEquip,' ')<> ' ' then (JCCD.EMEquip + ' '+ IsNull(EMEM.Description,' ') + '/'+ IsNull(JCCD.Description,' ')+'/ ') else '' end) +
 			  (Case when IsNull(JCCD.EMTrans,0) <> 0 then convert(varchar(5),JCCD.EMTrans)else '' end) +
  			  (Case when IsNull(JCCD.EMRevCode,' ')<> ' ' then '/ Rev Code: '+ JCCD.EMRevCode + IsNull(EMRC.Description,' ') else '' end)+
              (Case when IsNull(JCCD.Employee,0)<>0 then ('/  Emp: '+ convert(varchar(6),JCCD.Employee)+'/'+IsNull(PREHName.LastName,' ') +' '+IsNull(PREHName.Suffix,' ')+', '+IsNull(PREHName.FirstName,' ') +' '+IsNull(PREHName.MidName,' ')) else '' end )
  		      
 		       when JCCD.JCTransType ='IC' then 
              (case when IsNull(JCCD.Description,' ') <> ' ' then JCCD.Description else '' end) + 
         	  (case when IsNull(JCCD.SrcJCCo,0) <> 0 then (' /Src JCCo: '+ convert (varchar(3),JCCD.SrcJCCo)) else '' end)  

 		       when JCCD.JCTransType='IN' then 
              (Case when IsNull(JCCD.Material,' ') <> ' ' then(JCCD.Material+'  '+ IsNull(HQMT.Description,' ') +'-'+IsNull(JCCD.Description,' ')) else '' end)+ 
  			  (case when IsNull(JCCD.Loc,' ')<>' ' then (' /Loc '+ JCCD.Loc +' '+IsNull(INLM.Description,' ')) else '' end )
 		        
  		       when JCCD.JCTransType ='MO' then 
 			  (case when IsNull(JCCD.MO,' ') <>' ' then ( 'MO# '+ IsNull(JCCD.MO,' ')+' /MOItem '+ convert (varchar(5),JCCD.MOItem)+' /Mat '+JCCD.Material+' '+HQMT.Description) else '' end)+
              (Case when IsNull(JCCD.Description,' ') <> ' ' then JCCD.Description else '' end)               
  		       
              when JCCD.JCTransType='MS' then 
  		   	  (case when IsNull(JCCD.Material,' ') <>' ' then ('Mat '+JCCD.Material+'  '+IsNull(HQMT.Description,' ')+' / '+convert (varchar(7),IsNull(JCCD.MSTrans,0))) else '' end) +
              (case when IsNull(JCCD.Loc,' ')<>' ' then ('Loc '+JCCD.Loc +' '+INLM.Description) else '' end)+
 			  (Case when IsNull(JCCD.Description,' ')<> ' ' then JCCD.Description else '' end) 
                     	
  		      when JCCD.JCTransType='MI' then 
              (Case when IsNull(JCCD.Material,' ')<>' ' then ('Mat# '+ JCCD.Material +'-'+ IsNull(HQMT.Description,' ')+' / ' +IsNull(JCCD.Description,'')) else'' end)
  		      	
  		      when JCCD.JCTransType='PO' then 
  			  (case when IsNull(JCCD.PO,' ')<>' ' then (JCCD.PO +' /Item '+ convert (varchar(5),IsNull(JCCD.POItem,0))+' '+IsNull(POIT.Description,IsNull(POHD.Description,'')) + '/'+' Desc: '+ IsNull(JCCD.Description,''))else''end)+
              (case when IsNull(JCCD.Vendor,0) <> 0 then ('/ '+ convert (varchar(6),IsNull(JCCD.Vendor,0))+ '-'+ left(IsNull(APVM.Name,' '),20)) else '' end) +
  			  (case when IsNull(JCCD.Material,' ') <> ' ' then (' / Matl: '+ JCCD.Material + '-'+ HQMT.Description) else '' end) 
                         
  		       when JCCD.JCTransType= 'PR' then  
 			  (case when IsNull(JCCD.Craft,' ') <>' ' then (RTrim(JCCD.Craft) /*+IsNull(PRCM.Description,' ')*/+'/'+IsNull(RTrim(JCCD.Class),' ')/*+IsNull(PRCC.Description,'')*/) else '' end) +' ' +
  			  (case when isnull(JCCD.EarnFactor,0)<> 0 then (convert(varchar(9),convert(decimal(10,2),round(JCCD.EarnFactor,2)))) else '' end) +'/'+
              (case when IsNull(JCCD.Employee,0) <> 0 then (convert (varchar(6),IsNull(JCCD.Employee,0))+'/'+IsNull(PREHName.LastName,' ') +' '+IsNull(PREHName.Suffix,' ')+', '+IsNull(PREHName.FirstName,' ') +' '+IsNull(PREHName.MidName,' ') ) else '' end)+
 			  (Case when IsNull(JCCD.Description,' ')<>' ' then JCCD.Description else '' end) +
              (case when IsNull(JCCD.Crew,' ')<> ' ' then (JCCD.Crew + IsNull(PRCR.Description,' ')) else '' end) + 			
 			  (case when IsNull(JCCD.EMEquip,' ') <> ' ' then (JCCD.EMEquip +'/'+ IsNull(EMEM.Description,' ') +'/'+ IsNull(JCCD.EMRevCode,' ')) else '' end) +
 			  (case when IsNull(JCCD.EarnType,0)<>0 then (convert (varchar(4),JCCD.EarnType)+' ' +IsNull(HQET.Description,''))else '' end)+
 			  (case when IsNull(JCCD.LiabilityType,0)<> 0 then (convert (varchar(4),JCCD.LiabilityType)+' ' +IsNull(HQLT.Description,' ')) else''end)
   		      
              when JCCD.JCTransType='SL' then 
  			  (case when IsNull(JCCD.SL,' ') <>' ' then (JCCD.SL + ' '+IsNull(SLIT.Description,IsNull(SLHD.Description,''))  +' SLItem: '+convert (varchar(5),IsNull(JCCD.SLItem,0))+ '/'+IsNull(JCCD.Description,' ')) else '' end)+
 			  (case when IsNull(JCCD.Vendor,0) <> 0 then ('/ '+ convert (varchar(6),IsNull(JCCD.Vendor,0))+ '-'+ left(IsNull(APVM.Name,' '),20)) else '' end) 
                    
  		      when JCCD.JCTransType in ('CV','IC','JC','PF','PE','AR','RU')  then 
 			  (Case when IsNull(JCCD.Description,' ')<> ' ' then JCCD.Description else 'No Desc Entered' end)
 
  		      else  'JCTransType/Source: '+ JCCD.JCTransType+ '/' + JCCD.Source end 
  
from dbo.JCCD with(nolock)
 
 left outer join dbo.APVM with(nolock) on JCCD.VendorGroup = APVM.VendorGroup and JCCD.Vendor = APVM.Vendor
 left outer join dbo.EMEM with(nolock) on JCCD.EMCo = EMEM.EMCo and JCCD.EMEquip = EMEM.Equipment
 left outer join dbo.HQMT with(nolock) on JCCD.MatlGroup = HQMT.MatlGroup and JCCD.Material = HQMT.Material
 left outer join dbo.PREHName with(nolock) on JCCD.PRCo = PREHName.PRCo and JCCD.Employee = PREHName.Employee
 left outer join dbo.JCOH with(nolock) on JCCD.JCCo = JCOH.JCCo and JCCD.Job = JCOH.Job and JCCD.ACO = JCOH.ACO
 left outer join dbo.JCOI with(nolock) on JCCD.JCCo = JCOI.JCCo and JCCD.Job = JCOI.Job and JCCD.ACO = JCOI.ACO and JCCD.ACOItem = JCOI.ACOItem
 left outer join dbo.EMRC with(nolock) on JCCD.EMGroup = EMRC.EMGroup and JCCD.EMRevCode = EMRC.RevCode
 left outer join dbo.INLM with(nolock) on JCCD.INCo = INLM.INCo and JCCD.Loc = INLM.Loc
 left outer join dbo.POHD with(nolock) on JCCD.APCo = POHD.POCo and JCCD.PO = POHD.PO
 left outer join dbo.POIT with(nolock) on JCCD.APCo = POIT.POCo and JCCD.PO = POIT.PO and JCCD.POItem = POIT.POItem
 left outer join dbo.PRCM with(nolock) on JCCD.PRCo = PRCM.PRCo and JCCD.Craft = PRCM.Craft
 left outer join dbo.PRCC with(nolock) on JCCD.PRCo = PRCC.PRCo and JCCD.Craft = PRCC.Craft and JCCD.Class = PRCC.Class
 left outer join dbo.PRCR with(nolock) on JCCD.PRCo = PRCR.PRCo and JCCD.Crew = PRCR.Crew
 left outer join dbo.HQET with(nolock) on JCCD.EarnType =HQET.EarnType
 left outer join dbo.HQLT with(nolock) on JCCD.LiabilityType = HQLT.LiabType
 left outer join dbo.SLHD with(nolock) on JCCD.APCo = SLHD.SLCo and JCCD.SL = SLHD.SL
 left outer join dbo.SLIT with(nolock) on JCCD.APCo = SLIT.SLCo and JCCD.SL = SLIT.SL and JCCD.SLItem = SLIT.SLItem

--Grant all on brvVBJCCDDetlDesc to Public
GO
GRANT SELECT ON  [dbo].[brvVBJCCDDetlDesc] TO [public]
GRANT INSERT ON  [dbo].[brvVBJCCDDetlDesc] TO [public]
GRANT DELETE ON  [dbo].[brvVBJCCDDetlDesc] TO [public]
GRANT UPDATE ON  [dbo].[brvVBJCCDDetlDesc] TO [public]
GO
