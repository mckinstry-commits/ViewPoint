SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  view [dbo].[brvPRROEReason] as   
  
  
--  
--==========================================================  
--Author:  Mike Brewer  
--Create date: 3/15/2010  
--Issue:135792  
--  
--Description:This report is used as an F4 lookup  
  
--==========================================================  
select
'A' as 'Code',      
'Shortage of Work' as 'Reason',    
'A - Shortage of Work' as 'ReasonCode'   
 
  
union  
  
select 
'B' as 'Code',   
'Strike or Lockout' as 'Reason',   
'B - Strike or Lockout'  as 'ReasonCode'        
   
  
union  
              
--when 'Return to school' then 'C'      
select  
'C' as 'Code',     
'Return to School'  as 'Reason',   
'C - Return to School' as 'ReasonCode'        

  
union  
           
--when 'Illness or Injury' then 'D'    
select 
'D' as 'Code',     
'Illness or Injury'  as 'Reason',   
'D - Illness or Injury'  as 'ReasonCode'        
 
  
union  
            
--when 'Quit' then 'E'    
select 
'E' as 'Code',   
'Quit'  as 'Reason',   
'E - Quit'  as 'ReasonCode'        
   
  
union  
             
--when 'Maternity' then 'F'    
select 
'F'  as 'Code',     
'Maternity'  as 'Reason',   
'F - Maternity'  as 'ReasonCode'       
 
  
union  
             
--when 'Retirement' then 'G'  
select 
'G' as 'Code',      
'Retirement'  as 'Reason',   
'G - Retirement' as 'ReasonCode'        

  
union  
               
--when 'Work sharing' then 'H'  
select 
'H'  as 'Code',    
'Work Sharing'  as 'Reason',   
'H - Work Sharing'  as 'ReasonCode'        
  
  
union  
               
--when 'Apprentice Training' then 'J'    
select 
'J'  as 'Code',    
'Apprentice Training'  as 'Reason',   
'J - Apprentice Training'  as 'ReasonCode'       
  
  
union  
             
--when 'Dismissal' then 'M'  
select 
'M' as 'Code',      
'Dismissal'  as 'Reason',   
'M - Dismissal'  as 'ReasonCode'        

  
union  
               
--when 'Leave of absence' then 'N'   
select
'N' as 'Code',     
'Leave of Absence'  as 'Reason',   
'N - Leave of Absence'  as 'ReasonCode'        
  
  
union  
              
--when 'Parental' then 'P'     
select  
'P'  as 'Code',  
'Parental' as 'Reason',   
'P - Parental'  as 'ReasonCode'     
   
  
union  
            
--when 'Other' then 'K'   
select 
'K'  as 'Code',    
'Other' as 'Reason',   
'K - Other'  as 'ReasonCode'       
  
  
union  
              
--when 'Compassionate Care' then 'Z' end as '16-Reason Code',   
select 
'Z'  as 'Code',     
'Compassionate Care'  as 'Reason',   
'Z - Compassionate Care'  as 'ReasonCode'        
  
GO
GRANT SELECT ON  [dbo].[brvPRROEReason] TO [public]
GRANT INSERT ON  [dbo].[brvPRROEReason] TO [public]
GRANT DELETE ON  [dbo].[brvPRROEReason] TO [public]
GRANT UPDATE ON  [dbo].[brvPRROEReason] TO [public]
GO
