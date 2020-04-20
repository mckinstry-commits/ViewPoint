SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 /****** this view will be used for Textura SL Export 
Coder:MB
Created:11/2/2009
Issue#:135302
 ******/                      
                   
CREATE view [dbo].[vrvSLTexturaSubconComplianceExport]                      
----------                              
as                      
--         
------LDR Record        
--select distinct      
--ExportString,      
--Code,      
--SortOrder,      
--RecordType,      
--Co,      
--Job,      
--Vendor,       
--SL as 'SubContract',      
--[Contract],      
--InCompliance      
--from(        
    
SELECT distinct                      
1 as 'SortOrder',       
SLHD.SLCo as 'Co',                      
SLHD.Job as 'Job',                         
--'LDR' as 'RecordType',                      
  isnull(SLCT.Description,'') + Char(44) + ' '                 
  + isnull(cast (SLCT.CompCode as varchar),'') + '-' --3 Description                      
  + isnull(cast(SLCT.Seq as varchar),'') as 'Code',                 
                   
--Null as 'Vendor',   -- SLHD.Vendor as 'Vendor',                        
--Null as 'SL',      --SLHD.SL as 'SL',              
--Null as 'Contract',        
--Null as 'InCompliance',             
--Export String                      
char(34)--"                      
  + 'LDR'   --1                      
 + char(34)--"                      
+ Char(44)--,                      
 + char(34)                       
  + isnull(SLHD.Job,'') --2 Job Number                      
 + char(34)                      
+ Char(44)                      
 + char(34)                      
  + isnull(SLCT.Description,'') + Char(44) + ' '                 
  + isnull(cast (SLCT.CompCode as varchar),'') + '-' --3 Description                      
  + isnull(cast(SLCT.Seq as varchar),'')                         
 + char(34)                             
+ Char(44)                  
 + char(34)                     
  + ISNULL(SLCT.Verify,'N')  --4 Enforced           #138095  2/17/10 MB           
 + char(34)                
+ Char(44)                           
  + ''  --5 FirstWarningLeadDays                      
+ Char(44)                        
  + ''  --6 SecondWarningLeadDays                      
+ Char(44)                      
 + char(34)                        
  + 'N'  --7 FirstTierOnly                       
 + char(34)                      
+ Char(44)                       
 + char(34)                      
  + isnull(SLHD.Job,'')  --8 Main_Job                      
 + char(34) as 'ExportString'                      
FROM   SLHD                    
join SLCT                       
 ON SLCT.SLCo=SLHD.SLCo                       
 AND SLCT.SL=SLHD.SL           
--where SLHD.Job = ' 1000-Tex'               
      
                     
Union All                      
             
                    
SELECT distinct                      
2 as 'SortOrder',       
SLHD.SLCo as 'Co',                      
SLHD.Job as 'Job',                       
--'SLDR' as 'RecordType',                      
  isnull(SLCT.Description,'') + Char(44) + ' '                
  + isnull(cast (SLCT.CompCode as varchar),'') + '-' --3 Description                      
  + isnull(cast(SLCT.Seq as varchar),'') as 'Code',                 
                     
--SLHD.Vendor  as 'Vendor', --SLHD.Vendor as 'Vendor',                        
--SLHD.SL as 'SL', --SLHD.SL as 'SL',              
--Null as 'Contract',       
--Null as 'InCompliance',                      
--Export String                      
char(34)                      
  + 'SLDR'   --1                      
 + char(34)                      
+ Char(44)                 
 + char(34)                       
  + isnull(cast(SLHD.Job as varchar),'') --2 Job Number                      
 + char(34)                      
+ Char(44)                    
 + char(34)                      
  + isnull(SLCT.Description,'') + Char(44) + ' '                
  + isnull(cast (SLCT.CompCode as varchar),'') + '-' --3 Description                      
  + isnull(cast(SLCT.Seq as varchar),'')                            
 + char(34)    
+ Char(44)                   
 + char(34)                        
  + ''  --4 Remark                      
 + char(34) as 'ExportString'                      
FROM  SLHD                         
join SLCT                   
 ON SLCT.SLCo=SLHD.SLCo                       
 AND SLCT.SL=SLHD.SL                       
--where SLHD.Job = ' 1000-Tex'       
                     
Union All                      
      
             
SELECT distinct                      
3 as 'SortOrder',        
SLHD.SLCo as 'Co',                      
SLHD.Job as 'Job',                         
--'SLDRD' as 'RecordType',               
  isnull(SLCT.Description,'') + Char(44) + ' '                 
  + isnull(cast (SLCT.CompCode as varchar),'') + '-' --3 Description                      
  + isnull(cast(SLCT.Seq as varchar),'') as 'Code',                    
                  
--SLHD.Vendor as 'Vendor',                        
--SLHD.SL as 'SL',                
--Null as 'Contract',       
--Null as 'InCompliance',                    
--Export String                      
char(34)                   
  + 'SLDRD'  --1 Record ID                      
 + char(34)                      
+ Char(44)                      
 + char(34)                       
  + isnull(cast(SLHD.Job as varchar),'') --2 Job Number                      
 + char(34)                      
+ Char(44)                      
 + char(34)                      
  + isnull(SLCT.Description,'') + Char(44) + ' '                
  + isnull(cast (SLCT.CompCode as varchar),'') + '-' --3 Description                      
  + isnull(cast(SLCT.Seq as varchar),'')                            
 + char(34)                      
+ Char(44)                      
 + char(34)                        
  + ''  --4 Remark                      
 + char(34)                      
+ Char(44)                       
 + char(34)                        
--  + case SLCT.Verify when 'Y' then isnull(cast(SLHD.Vendor as varchar),'') else '' end  --5 VendorID                      
  + case SLCT.Verify when 'Y' then isnull(cast(SLHD.Vendor as varchar),'') else '' end --VendorName           
 + char(34) as 'ExportString'                           
FROM  SLHD                     
join  SLCT                         
 ON SLCT.SLCo=SLHD.SLCo                       
 AND SLCT.SL=SLHD.SL                     
--where SLHD.Job = ' 1000-Tex'              
                 
Union All                      
            
                 
Select distinct                      
4 as 'SortOrder',        
SLHD.SLCo as 'Co',                      
SLHD.Job as 'Job',                     
--'L' as 'RecordType',                      
  isnull(SLCT.Description,'') + Char(44) + ' '                 
  + isnull(cast (SLCT.CompCode as varchar),'') + '-' --3 Description                      
  + isnull(cast(SLCT.Seq as varchar),'') as 'Code',                 
                      
--SLHD.Vendor as 'Vendor',                        
--SLHD.SL as 'SL',            
--JCCM.Contract as 'Contract',         
--Case SLCT.Verify when 'Y' then                  
--   case HQCP.CompType when 'D' then                   
--       Case When isnull(SLCT.ExpDate, '1950-01-01')  < getdate() then 'N'   else 'Y'  End                  
--   else isnull(SLCT.Complied,'N') end                  
--    else 'Y'  end as 'InCompliance',                    
--Export String                      
char(34)                      
  + 'L'  --1 Record ID                      
 + char(34)                      
+ Char(44)                      
 +  char(34)                      
 + Left(SLHD.SL,20) --as 'Contract_No'                      
 + char(34)                      
+ Char(44)                      
 + char(34)                       
 + isnull(cast(SLHD.Vendor as varchar),'') --as 'Vendor_ID'                      
 + char(34)                      
+ Char(44)                      
 + char(34)                       
 + '' --as 'Comm_Log_Type'                      
 + char(34)                      
+ Char(44)                      
 + char(34)                       
  + isnull(SLCT.Description,'') + Char(44) + ' '                
  + isnull(cast (SLCT.CompCode as varchar),'') + '-' --3 Description                      
  + isnull(cast(SLCT.Seq as varchar),'')                             
 + char(34)                      
+ Char(44)                      
 + char(34)                       
 + isnull(APVC.Memo,'') --as 'Vendor Memo'                      
 + char(34)                      
+ Char(44)                 
 + char(34)                       
  + isnull(Isnull(right('00' + convert(varchar(2),month(SLCT.ReceiveDate)),2) + '-' +                     
   right('00' + convert(varchar(2),day(SLCT.ReceiveDate)),2) + '-' +                       
   convert(varchar(4),year(SLCT.ReceiveDate)),''),'') --as 'ExpDate'                      
 + char(34)                      
+ Char(44)                      
 + char(34)                       
  + isnull(Isnull(right('00' + convert(varchar(2),month(SLCT.ExpDate)),2)  +  '-' +                     
   right('00' + convert(varchar(2),day(SLCT.ExpDate)),2) +  '-' +                     
   convert(varchar(4),year(SLCT.ExpDate)),''),'') --as 'ExpDate'                      
 + char(34)                      
+ Char(44)                      
 + char(34)                       
 + '' --as 'Req_Date'                      
 + char(34)                      
+ Char(44)                      
 + char(34)                       
 + '' --as 'Provider_Name'                      
 + char(34)                      
+ Char(44)                      
 + char(34)                       
 + isnull(cast(SLHD.Job as varchar),'') --as 'Job_Number'                      
 + char(34)                      
+ Char(44)                      
 + char(34)                       
 + '' --as 'Parent_Job_Number'                      
 + char(34)                      
+ Char(44)                      
 + char(34)                    
 + Case SLCT.Verify when 'Y' then                  
   case HQCP.CompType when 'D' then                   
       Case When isnull(SLCT.ExpDate, '1950-01-01')  < getdate() then 'N'   else 'Y'  End                  
   else isnull(SLCT.Complied,'N') end                  
    else 'Y'  end + char(34) as 'ExportString'                      
from      SLHD                     
join   SLCT                  
 on SLCT.SLCo=SLHD.SLCo                       
 and SLCT.SL=SLHD.SL                     
join HQCP                       
 on SLCT.CompCode = HQCP.CompCode                     
join SLIT                      
 ON SLIT.SLCo=SLHD.SLCo                       
 AND SLIT.SL=SLHD.SL                       
INNER JOIN JCJM                       
 ON SLHD.JCCo=JCJM.JCCo                       
 AND SLHD.Job=JCJM.Job                       
LEFT OUTER JOIN JCCM                       
 ON JCJM.JCCo=JCCM.JCCo                       
 AND JCJM.Contract=JCCM.Contract                      
LEFT OUTER JOIN APVC                       
 on SLCT.SLCo=APCo                       
 and SLHD.VendorGroup = APVC.VendorGroup                       
 and SLHD.Vendor = APVC.Vendor                       
 and SLCT.CompCode=APVC.CompCode        
--where SLHD.Job = ' 1000-Tex'         
--order by 4, 3      
      
--      
-- ) as x        
--where Job = ' 1000-Tex'           
--order by 8, 2, 3            
-- 
GO
GRANT SELECT ON  [dbo].[vrvSLTexturaSubconComplianceExport] TO [public]
GRANT INSERT ON  [dbo].[vrvSLTexturaSubconComplianceExport] TO [public]
GRANT DELETE ON  [dbo].[vrvSLTexturaSubconComplianceExport] TO [public]
GRANT UPDATE ON  [dbo].[vrvSLTexturaSubconComplianceExport] TO [public]
GO
