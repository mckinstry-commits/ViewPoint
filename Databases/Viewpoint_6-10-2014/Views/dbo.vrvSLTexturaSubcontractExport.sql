SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




/****** this view will be used for Textura SL Export         
Coder:MB        
Created:6/2/2009        

Modified:  11/2/2010 DH.  Issue 140718. Changed SortOrder values, added SL Item, SL ChangeOrder, and fixed SL Change Order
						  header section to return one line per SL Change Order.
										
Usage:  The view returns Subcontract header/items for original amounts and subcontract change orders for the 
	    SL Textura Subcontract Export report, which is used to generate an import file that customers upload to Textura.
	    The view returns the following columns:
			SortOrder:  Value of 1 for original records, 2 for change orders next.  Used for grouping in the report.
			RecordType:  C, CI, CCO, CCOI.  Subcontract Header, Items, Change Order Header, Change Order Items, respectively.
			Co:  SL Company
			Job:  Job from SL Header
			SL:   Subcontract Number.  Truncated at 20 characters because field in Textura software limited to 20.
			ExportString:  Single string field concatenated with required SL data.  Each field within the concatenated
						   string is separated by a comma (char(44)) with string fields enclosed in quotes (char(34)
			
	  
******/          
        
              
CREATE view [dbo].[vrvSLTexturaSubcontractExport]          
      
       
as         
          
--C Record        
--Contract (SL) Header       
select           
1 as 'SortOrder',          
'C' as 'RecordType',          
SLIT.SLCo as 'Co',  --integer          
SLHD.Job as 'Job',  --varchar          
SLHD.Vendor as 'Vendor',  --int          
Left(SLHD.SL,20) as 'SL', --varchar        
Null as 'SLChangeOrder', 
Null as 'SLItem',       
'C'          --1          
+ Char(44) +             
char(34) + isnull(SLHD.Job, '') + char(34) --2          
+ Char(44) +             
''          --3          
+ Char(44) +           
isnull(cast(SLHD.Vendor as Varchar),'') --4          
+ Char(44) +            
char(34) + isnull(Left(SLHD.SL,20), '') + char(34)      --5          
+ Char(44) +            
char(34) + isnull(max(replace(SLHD.Description, Char(44),' ')), '') + char(34) --6          
+ Char(44) +           
          
          
Isnull(right('00' + convert(varchar(2),month(getdate())),2) + '-' +          
 right('00' + convert(varchar(2),day(Getdate())),2) + '-' +          
 convert(varchar(4),year(getdate())),'') --7          
          
          
+ Char(44) +              
isnull(cast(Cast(Round(max(SLIT.WCRetPct)*100,2,1) as decimal(18,2)) as varchar),'')  --8          
+ Char(44) +          
cast((sum(SLIT.OrigCost)) as varchar) --9          
--+ Char(44) +            
--''          --10          
--+ Char(44) +                      
--''          --11           
as 'ExportString'                     
from SLHD          
join SLIT          
 ON SLIT.SLCo=SLHD.SLCo           
 AND SLIT.SL=SLHD.SL           
group by           
SLIT.SLCo,          
SLHD.Job,          
SLHD.Vendor,          
SLHD.SL          
          
      
      
      
      
Union ALL          
          
--CI Record          
--Contract  (SL) Items      
select           
1 as 'SortOrder',          
'CI' as 'RecordType',          
SLIT.SLCo as 'Co', --integer          
SLHD.Job as 'Job',  --varchar          
SLHD.Vendor as 'Vendor',--int          
Left(SLHD.SL,20) as 'SL', --varchar       
Null as 'SLChangeOrder',   
SLIT.SLItem as 'SLItem',   
'CI'         --1          
+ Char(44) +              
char(34) + isnull(SLHD.Job,'') + char(34)--2          
+ Char(44) +            
''          --3          
+ Char(44) +              
isnull(cast(SLHD.Vendor as Varchar),'') --4          
+ Char(44) +            
char(34) + isnull(Left(SLHD.SL,20),'') + char(34) --5          
+ Char(44) +              
isnull(cast(SLIT.SLItem as varchar),'') --6          
+ Char(44) +          
char(34) + isnull(SLIT.Description, '') + Char(34) --7          
+ Char(44) +          
char(34) + isnull(SLIT.Phase, '') + char(34)  --8          
+ Char(44) +             
isnull(cast(SLIT.JCCType as varchar),'') --9          
+ Char(44) +             
cast(Cast(Round((SLIT.WCRetPct * 100),2,1) as decimal(18,2)) as varchar) --10          
+ Char(44) +          
isnull(cast((SLIT.OrigCost) as varchar),'') as 'ExportString'            
from SLHD          
join SLIT          
 ON SLIT.SLCo=SLHD.SLCo           
 AND SLIT.SL=SLHD.SL           
          
          
Union all       
    
------------------------------------------------------------------      
------------------------------------------------------------------       
    
       
          
--Change Order Header        
select          
2 as 'SortOrder',          
'CCO' as 'RecordType',          
SLHD.SLCo as 'Co',          
SLHD.Job as 'Job',          
SLHD.Vendor as 'Vendor',          
Left(SLHD.SL,20) as 'SL',        
SLCD.SLChangeOrder as 'SL',        
Null as 'SLItem',
'CCO'         --1          
+ Char(44) +              
char(34) + isnull(SLHD.Job, '') + char(34) --2          
+ Char(44) +             
''          --3          
+ Char(44) +            
isnull(cast(SLHD.Vendor as varchar),'') --4          
+ Char(44) +                
char(34) + isnull(Left(SLHD.SL,20), '') + char(34)  --5          
+ Char(44) +             
isnull(cast(SLCD.SLChangeOrder as varchar),'') --6          
+ Char(44) +             
--isnull(CONVERT(varchar,SLCD.ActDate,101), '')           
Isnull(right('00' + convert(varchar(2),month(max(SLCD.ActDate))),2) + '-' +          
 right('00' + convert(varchar(2),day(max(SLCD.ActDate))),2) + '-' +          
 convert(varchar(4),year(max(SLCD.ActDate))),'')---7          
+ Char(44) +           
char(34) + isnull((replace(case when count(distinct SLCD.AppChangeOrder) > 1 
								then cast(isnull(count(distinct SLCD.AppChangeOrder),0) as varchar(5))+' OCOs' 
								else max(SLCD.AppChangeOrder) end
						   , Char(44)
						   , Char(34) + Char(44)+ Char(34)
						    ) --end replace
				   )
			,'') + char(34) --8  /*Returns AppChangeOrder if only one assigned to the Subcontract Change Order else count of multiple OCOs)*/
								 /*replace function replaces any commas in the AppChangeOrder column with quote+comma+quote
								  (encloses any commas with quotes*/
+ Char(44) +          
char(34) + isnull(
				cast(
					max(replace(SLCD.Notes,char(13)+char(10),' ')) --replace carriage return line feeds with space
				 as Varchar(145)) --end cast
			, '') --end isnull
+ char(34)  --9          
--+ Char(44) +          
--''          --10          
--+ Char(44) +            
--''           
as 'ExportString'   --11         
from SLHD SLHD          
join SLIT SLIT          
 ON SLIT.SLCo=SLHD.SLCo           
 AND SLIT.SL=SLHD.SL           
join SLCD SLCD           
 ON SLIT.SLCo=SLCD.SLCo           
 AND SLIT.SL=SLCD.SL           
 AND SLIT.SLItem=SLCD.SLItem
 
Group By	SLHD.SLCo ,          
			SLHD.Job ,          
			SLHD.Vendor ,          
			Left(SLHD.SL,20),
			SLCD.SLChangeOrder       
          
Union all          
          
--Change Order Detail Lines      
select          
2 as 'SortOrder',          
'CCOI' as 'RecordType',          
SLHD.SLCo as 'Co',          
SLHD.Job as 'Job',          
SLHD.Vendor as 'Vendor',          
Left(SLHD.SL,20) as 'SL',          
SLCD.SLChangeOrder as 'SL',        
SLCD.SLItem as 'SLItem',
'CCOI'     --1          
+ Char(44) +                 
char(34) + isnull(SLHD.Job, '') +char(34) --2          
+ Char(44) +             
''          --3          
+ Char(44) +                  
isnull(cast(SLHD.Vendor as varchar),'') --4          
+ Char(44) +           
char(34) + isnull(Left(SLHD.SL,20), '') + char(34)  --5          
+ Char(44) +                 
isnull(cast(SLCD.SLChangeOrder as varchar), '')--6          
+ Char(44) +             
isnull(cast(SLCD.SLItem as varchar),'') --7          
+ Char(44) +             
char(34) + isnull(max(SLIT.Phase), '') + char(34)     --8          
+ Char(44) +                    
isnull(cast(max(SLIT.JCCType) as varchar),'') --9          
+ Char(44) +               
isnull(cast(sum(SLCD.ChangeCurCost) as varchar),'') --10          
--+ Char(44) +             
--''           
as 'ExportString'     --11                 
from SLHD SLHD          

join SLIT SLIT          
 ON SLIT.SLCo=SLHD.SLCo           
 AND SLIT.SL=SLHD.SL           

join SLCD SLCD           
 ON SLIT.SLCo=SLCD.SLCo           
 AND SLIT.SL=SLCD.SL           
 AND SLIT.SLItem=SLCD.SLItem 
 
Group By	SLHD.SLCo ,          
			SLHD.Job ,          
			SLHD.Vendor ,          
			Left(SLHD.SL,20),
			SLCD.SLChangeOrder,
			SLCD.SLItem
			







GO
GRANT SELECT ON  [dbo].[vrvSLTexturaSubcontractExport] TO [public]
GRANT INSERT ON  [dbo].[vrvSLTexturaSubcontractExport] TO [public]
GRANT DELETE ON  [dbo].[vrvSLTexturaSubcontractExport] TO [public]
GRANT UPDATE ON  [dbo].[vrvSLTexturaSubcontractExport] TO [public]
GRANT SELECT ON  [dbo].[vrvSLTexturaSubcontractExport] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvSLTexturaSubcontractExport] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvSLTexturaSubcontractExport] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvSLTexturaSubcontractExport] TO [Viewpoint]
GO
