SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE Procedure [dbo].[brptPRRetroPayExport]        
  
(@PRCo bCompany,   
@BegDate bDate,  
@EndDate bDate)   
       
as     
  
  
select   
2 as 'Sort',  
char(34) + isnull(cast( Employee as varchar),'')   + char(34) + Char(44) + --as 'Employee',  
  
+ char(34)                     
 + isnull(Isnull(right('00' + convert(varchar(2),month(PostDate)),2) + '-' +                   
   right('00' + convert(varchar(2),day(PostDate)),2) + '-' +                     
   convert(varchar(4),year(PostDate)),''),'') --as 'ExpDate'                    
 + char(34)                    
+ Char(44) + --as 'PostDate',  
  
char(34) + isnull(cast( JCCo as varchar),'')  + char(34) + Char(44)  + --as 'JCCo',  
  
char(34) + isnull(Job, '')  + char(34) + Char(44) + --as 'Job',  
  
char(34) + isnull(Phase, '')   + char(34) + Char(44) + --as 'Phase',  
  
char(34) + isnull(Craft,'')   + char(34) + Char(44) + --as 'Craft',  
--  
char(34) + isnull(Class,'')   + char(34) + Char(44) + --as 'Class',  
  
char(34) + isnull(cast( sum(Hours) as varchar),'')   + char(34) + Char(44) + --as 'Total Hrs In',  
  
char(34) + isnull(cast( sum(Hours * -1) as varchar),'')   + char(34) + Char(44) + --as 'Total Hrs Out',  
  
char(34) + isnull(cast( sum(Rate) as varchar),'')   + char(34) + Char(44) + --as 'Rate',  
  
char(34) + isnull(cast( sum(Amt) as varchar),'')   + char(34)  --as 'Total Amt',  
as 'ExportString',  
---------------------------------------  
  
Employee as 'Employee',  
PostDate as 'PostDate',  
JCCo  as 'JCCo',  
Job as 'Job',  
Phase as 'Phase',  
Craft as 'Craft',  
Class as 'Class',  
sum(Hours)  as 'Total Hrs In',  
sum(Hours * -1)  as 'Total Hrs Out',  
Rate as 'Rate',  
sum(Amt)  as 'Total Amt'  
from PRTH  
where PREndDate >= @BegDate AND PREndDate <= @EndDate    
and JCCo = @PRCo  
group by  
Employee,  
PostDate,  
JCCo,  
Job,  
Phase,  
Craft,  
Class,  
Rate  
  
  
  
  
  

GO
GRANT EXECUTE ON  [dbo].[brptPRRetroPayExport] TO [public]
GO
