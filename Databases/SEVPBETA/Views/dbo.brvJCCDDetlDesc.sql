SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE    VIEW [dbo].[brvJCCDDetlDesc] 
	AS
 
/*==================================================================================          
    
Author:       
??      
    
Create date:       
??      
    
Usage:
View for JC Detail Reports.  
Selects all data from JCCD and then creates a new field called DetlDesc that concatenates
a lot of data and descriptions from the various JCCD.Source Types and their related
maintenance tables(views). The related report has a flag asking if the user wants to 
see the detailed description or not.
    
Things to keep in mind:
Please be sure to correctly convert non-text fields to text or the related report
will fail. 
    
Related reports: 
JC Detail (ID: 506)
JC Revenue and Cost Drilldown (ID: 546)  
   
Revision History          
Date  Author   Issue      Description
12/16/2009	TMS		CL-131486 / V1-??	Used IsNull function to prevent CASE statements from 
	returning NULL when concatenating
07/10/2012 ScottAlvey	CL-NA / V1-B-10098	Add Workorder fields to various reports.
	Pulled in the Work Order field from JCCD so it can be added to the report. Filled in 
	some documentation holes and changed the documentation format.
  
==================================================================================*/   


SELECT 
	JCCD.*, 
         DetlDesc= Case when JCCD.Source = 'JC CostAdj' AND JCCD.JCTransType ='JC' then 
                           (case when IsNull(JCCD.Description,' ') <> ' ' then JCCD.Description else '' end)
               when JCCD.JCTransType='AP' then  
  			  (case when IsNull(JCCD.Vendor, 0) <> 0 then (CONVERT(varchar(6), IsNull(JCCD.Vendor, 0)) +  ' ' + left(IsNull(APVM.Name, ' '),20)) else '' end) +
  			  (case when IsNull(JCCD.APRef ,' ') <>' ' then  (' '+ IsNull(JCCD.APRef, ' ')) else '' end)+
              (case when IsNull(JCCD.APTrans,0) <> 0  then  (' / TR# '+  CONVERT(varchar(7), IsNull(JCCD.APTrans, ' ')) + '/' + CONVERT(varchar(5), ISNULL(JCCD.APLine,' '))) else ''   end) +
  			  (case when IsNull(JCCD.Material,' ') <> ' ' then (' / Matl: '+ IsNull(JCCD.Material, ' ') + '-' + IsNull(HQMT.Description, ' ')) else '' end) +
  			  (case when IsNull(JCCD.APCo,0) <> 0 then ('/ APCo: '+ CONVERT (varchar(3), IsNull(JCCD.APCo, ' '))) else '' end) +
              (case when IsNull(JCCD.PO,' ') <>' ' then ('/ PO#-Line ' + IsNull(JCCD.PO, ' ') + '-' + CONVERT (varchar(5),IsNull(JCCD.POItem,0)))else '' end)+
  			  (case when IsNull(JCCD.SL,' ') <> ' ' then ('/ SL#-Item ' + IsNull(JCCD.SL, ' ') + '-' + CONVERT (varchar(5),IsNull(JCCD.SLItem,0)))else '' end)+
              (case when IsNull(JCCD.Description,' ') <> ' ' then IsNull(JCCD.Description, ' ') else '' end) +
  			  (case when IsNull(JCCD.SMWorkOrder, ' ') <> ' ' then (' /WO: ' + convert(varchar(8),JCCD.SMWorkOrder)) else '' end)
  			 
  		       when JCCD.JCTransType ='CO' then 
              (case when IsNull(JCCD.ACO,' ') <> ' ' then (JCCD.ACO +' /Item '+JCCD.ACOItem+ IsNull(JCOI.Description,isNull(JCOH.Description,' '))) else '' end) +
              (case when IsNull(JCCD.Description,' ') <> ' ' then JCCD.Description else '' end)            
  		      
               when JCCD.JCTransType='EM' then 
              (Case when IsNull(JCCD.EMEquip,' ')<> ' ' then (JCCD.EMEquip + ' '+ IsNull(EMEM.Description,' ') + '/'+ IsNull(JCCD.Description,' ')+'/ ') else '' end) +
 			  (Case when IsNull(JCCD.EMTrans,0) <> 0 then convert(varchar(5),JCCD.EMTrans)else '' end) +
  			  (Case when IsNull(JCCD.EMRevCode,' ')<> ' ' then '/ Rev Code: '+ JCCD.EMRevCode + IsNull(EMRC.Description,' ') else '' end)+
              (Case when IsNull(JCCD.Employee,0)<>0 then ('/  Emp: '+ convert(varchar(6),JCCD.Employee)+'/'+IsNull(PREHName.LastName,' ') +' '+IsNull(PREHName.Suffix,' ')+', '+IsNull(PREHName.FirstName,' ') +' '+IsNull(PREHName.MidName,' ')) else '' end )+
  			  (case when IsNull(JCCD.SMWorkOrder, ' ') <> ' ' then (' /WO: ' + convert(varchar(8),JCCD.SMWorkOrder)) else '' end)
  		      
 		       when JCCD.JCTransType ='IC' then 
              (case when IsNull(JCCD.Description,' ') <> ' ' then JCCD.Description else '' end) + 
         	  (case when IsNull(JCCD.SrcJCCo,0) <> 0 then (' /Src JCCo: '+ convert (varchar(3),JCCD.SrcJCCo)) else '' end)  

 		       when JCCD.JCTransType='IN' then 
              (Case when IsNull(JCCD.Material,' ') <> ' ' then(JCCD.Material+'  '+ IsNull(HQMT.Description,' ') +'-'+IsNull(JCCD.Description,' ')) else '' end)+ 
  			  (case when IsNull(JCCD.Loc,' ')<>' ' then (' /Loc '+ JCCD.Loc +' '+IsNull(INLM.Description,' ')) else '' end )+
  			  (case when IsNull(JCCD.SMWorkOrder, ' ') <> ' ' then (' /WO: ' + convert(varchar(8),JCCD.SMWorkOrder)) else '' end)
 		        
  		       when JCCD.JCTransType ='MO' then 
 			  (case when IsNull(JCCD.MO,' ') <>' ' then ( 'MO# '+ IsNull(JCCD.MO,' ')+' /MOItem '+ convert (varchar(5), IsNull(JCCD.MOItem, ' ')) + ' /Mat ' + IsNull(JCCD.Material, ' ') + ' ' + IsNull(HQMT.Description, ' ')) else '' end)+
              (Case when IsNull(JCCD.Description,' ') <> ' ' then JCCD.Description else '' end)+
  			  (case when IsNull(JCCD.SMWorkOrder, ' ') <> ' ' then (' /WO: ' + convert(varchar(8),JCCD.SMWorkOrder)) else '' end)        
  		       
              when JCCD.JCTransType='MS' then 
  		   	  (case when IsNull(JCCD.Material,' ') <>' ' then ('Mat '+JCCD.Material+'  '+IsNull(HQMT.Description,' ')+' / '+convert (varchar(7),IsNull(JCCD.MSTrans,0))) else '' end) +
              (case when IsNull(JCCD.Loc,' ')<>' ' then ('Loc '+JCCD.Loc +' '+INLM.Description) else '' end)+
 			  (Case when IsNull(JCCD.Description,' ')<> ' ' then JCCD.Description else '' end)+
  			  (case when IsNull(JCCD.SMWorkOrder, ' ') <> ' ' then (' /WO: ' + convert(varchar(8),JCCD.SMWorkOrder)) else '' end) 
                     	
  		      when JCCD.JCTransType='MI' then 
              (Case when IsNull(JCCD.Material,' ')<>' ' then ('Mat# '+ JCCD.Material +'-'+ IsNull(HQMT.Description,' ')+' / ' +IsNull(JCCD.Description,'')) else'' end)+
  			  (case when IsNull(JCCD.SMWorkOrder, ' ') <> ' ' then (' /WO: ' + convert(varchar(8),JCCD.SMWorkOrder)) else '' end)
  		      	
  		      when JCCD.JCTransType='PO' then 
  			  (case when IsNull(JCCD.PO,' ')<>' ' then (IsNull(JCCD.PO, ' ') +' /Item '+ convert (varchar(5),IsNull(JCCD.POItem,0))+' '+IsNull(POIT.Description,IsNull(POHD.Description,'')) + '/'+' Desc: '+ IsNull(JCCD.Description,''))else''end)+
              (case when IsNull(JCCD.Vendor,0) <> 0 then ('/ '+ convert (varchar(6),IsNull(JCCD.Vendor,0))+ '-'+ left(IsNull(APVM.Name,' '),20)) else '' end) +
  			  (case when IsNull(JCCD.Material,' ') <> ' ' then (' / Matl: '+ IsNull(JCCD.Material, ' ') + '-' + IsNull(HQMT.Description, ' ')) else '' end) +
  			  (case when IsNull(JCCD.SMWorkOrder, ' ') <> ' ' then (' /WO: ' + convert(varchar(8),JCCD.SMWorkOrder)) else '' end)
                         
  		       when JCCD.JCTransType= 'PR' then  
 			  (case when IsNull(JCCD.Craft,' ') <>' ' then (RTrim(JCCD.Craft) /*+IsNull(PRCM.Description,' ')*/+'/'+IsNull(RTrim(JCCD.Class),' ')/*+IsNull(PRCC.Description,'')*/) else '' end) +' ' +
  			  (case when isnull(JCCD.EarnFactor,0)<> 0 then (convert(varchar(9),convert(decimal(10,2),round(JCCD.EarnFactor,2)))) else '' end) +'/'+
              (case when IsNull(JCCD.Employee,0) <> 0 then (convert (varchar(6),IsNull(JCCD.Employee,0))+'/'+IsNull(PREHName.LastName,' ') +' '+IsNull(PREHName.Suffix,' ')+', '+IsNull(PREHName.FirstName,' ') +' '+IsNull(PREHName.MidName,' ') ) else '' end)+
 			  (Case when IsNull(JCCD.Description,' ')<>' ' then JCCD.Description else '' end) +
              (case when IsNull(JCCD.Crew,' ')<> ' ' then (JCCD.Crew + IsNull(PRCR.Description,' ')) else '' end) + 			
 			  (case when IsNull(JCCD.EMEquip,' ') <> ' ' then (JCCD.EMEquip +'/'+ IsNull(EMEM.Description,' ') +'/'+ IsNull(JCCD.EMRevCode,' ')) else '' end) +
 			  (case when IsNull(JCCD.EarnType,0)<>0 then (convert (varchar(4),JCCD.EarnType)+' ' +IsNull(HQET.Description,''))else '' end)+
 			  (case when IsNull(JCCD.LiabilityType,0)<> 0 then (convert (varchar(4),JCCD.LiabilityType)+' ' +IsNull(HQLT.Description,' ')) else''end)+
  			  (case when IsNull(JCCD.SMWorkOrder, ' ') <> ' ' then (' /WO: ' + convert(varchar(8),JCCD.SMWorkOrder)) else '' end)
   		      
              when JCCD.JCTransType='SL' then 
  			  (case when IsNull(JCCD.SL,' ') <>' ' then (JCCD.SL + ' '+IsNull(SLIT.Description,IsNull(SLHD.Description,''))  +' SLItem: '+convert (varchar(5),IsNull(JCCD.SLItem,0))+ '/'+IsNull(JCCD.Description,' ')) else '' end)+
 			  (case when IsNull(JCCD.Vendor,0) <> 0 then ('/ '+ convert (varchar(6),IsNull(JCCD.Vendor,0))+ '-'+ left(IsNull(APVM.Name,' '),20)) else '' end) +
  			  (case when IsNull(JCCD.SMWorkOrder, ' ') <> ' ' then (' /WO: ' + convert(varchar(8),JCCD.SMWorkOrder)) else '' end)
                    
  		      when JCCD.JCTransType in ('CV','IC','JC','PF','PE','AR','RU')  then 
 			  (Case when IsNull(JCCD.Description,' ')<> ' ' then JCCD.Description else 'No Description Entered' end)
 
  		      else  'JCTransType/Source: '+ JCCD.JCTransType+ '/' + JCCD.Source end 

FROM				dbo.JCCD WITH(nolock)
	LEFT OUTER JOIN dbo.APVM with(nolock)		ON JCCD.VendorGroup = APVM.VendorGroup AND JCCD.Vendor = APVM.Vendor
	LEFT OUTER JOIN dbo.EMEM with(nolock)		ON JCCD.EMCo = EMEM.EMCo AND JCCD.EMEquip = EMEM.Equipment
	LEFT OUTER JOIN dbo.HQMT with(nolock) 		ON JCCD.MatlGroup = HQMT.MatlGroup AND JCCD.Material = HQMT.Material
	LEFT OUTER JOIN dbo.PREHName with(nolock)	ON JCCD.PRCo = PREHName.PRCo AND JCCD.Employee = PREHName.Employee
	LEFT OUTER JOIN dbo.JCOH with(nolock) 		ON JCCD.JCCo = JCOH.JCCo AND JCCD.Job = JCOH.Job AND JCCD.ACO = JCOH.ACO
	LEFT OUTER JOIN dbo.JCOI with(nolock) 		ON JCCD.JCCo = JCOI.JCCo AND JCCD.Job = JCOI.Job AND JCCD.ACO = JCOI.ACO AND JCCD.ACOItem = JCOI.ACOItem
	LEFT OUTER JOIN dbo.EMRC with(nolock) 		ON JCCD.EMGroup = EMRC.EMGroup AND JCCD.EMRevCode = EMRC.RevCode
	LEFT OUTER JOIN dbo.INLM with(nolock) 		ON JCCD.INCo = INLM.INCo AND JCCD.Loc = INLM.Loc
	LEFT OUTER JOIN dbo.POHD with(nolock) 		ON JCCD.APCo = POHD.POCo AND JCCD.PO = POHD.PO
	LEFT OUTER JOIN dbo.POIT with(nolock) 		ON JCCD.APCo = POIT.POCo AND JCCD.PO = POIT.PO AND JCCD.POItem = POIT.POItem
	LEFT OUTER JOIN dbo.PRCM with(nolock) 		ON JCCD.PRCo = PRCM.PRCo AND JCCD.Craft = PRCM.Craft
	LEFT OUTER JOIN dbo.PRCC with(nolock) 		ON JCCD.PRCo = PRCC.PRCo AND JCCD.Craft = PRCC.Craft AND JCCD.Class = PRCC.Class
	LEFT OUTER JOIN dbo.PRCR with(nolock) 		ON JCCD.PRCo = PRCR.PRCo AND JCCD.Crew = PRCR.Crew
	LEFT OUTER JOIN dbo.HQET with(nolock) 		ON JCCD.EarnType =HQET.EarnType
	LEFT OUTER JOIN dbo.HQLT with(nolock) 		ON JCCD.LiabilityType = HQLT.LiabType
	LEFT OUTER JOIN dbo.SLHD with(nolock) 		ON JCCD.APCo = SLHD.SLCo AND JCCD.SL = SLHD.SL
	LEFT OUTER JOIN dbo.SLIT with(nolock) 		ON JCCD.APCo = SLIT.SLCo AND JCCD.SL = SLIT.SL AND JCCD.SLItem = SLIT.SLItem
GO
GRANT SELECT ON  [dbo].[brvJCCDDetlDesc] TO [public]
GRANT INSERT ON  [dbo].[brvJCCDDetlDesc] TO [public]
GRANT DELETE ON  [dbo].[brvJCCDDetlDesc] TO [public]
GRANT UPDATE ON  [dbo].[brvJCCDDetlDesc] TO [public]
GO
