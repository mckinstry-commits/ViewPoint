SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================  
-- Author:  Mike Brewer  
-- Create date: 4/22/09  
-- Description: Code to parse dallor amount on check into words  
-- Issue #131608   
-- =============================================  
  
  
CREATE view [dbo].[vrvAPPBaus] as   
select   
a.*,  
dbo.vfNumberToText(substring(cast(a.Amount as varchar),CHARINDEX('.', cast(a.Amount as varchar) )-7,1)) as 'Millions',  
dbo.vfNumberToText(substring(cast(a.Amount as varchar),CHARINDEX('.', cast(a.Amount as varchar) )-6,1)) as 'HundThous',  
dbo.vfNumberToText(substring(cast(a.Amount as varchar),CHARINDEX('.', cast(a.Amount as varchar) )-5,1)) as 'TensThous',  
dbo.vfNumberToText(substring(cast(a.Amount as varchar),CHARINDEX('.', cast(a.Amount as varchar) )-4,1)) as 'Thousands',  
dbo.vfNumberToText(substring(cast(a.Amount as varchar),CHARINDEX('.', cast(a.Amount as varchar) )-3,1)) as 'Hundreds',  
dbo.vfNumberToText(substring(cast(a.Amount as varchar),CHARINDEX('.', cast(a.Amount as varchar) )-2,1)) as 'Tens',  
dbo.vfNumberToText(substring(cast(a.Amount as varchar),CHARINDEX('.', cast(a.Amount as varchar) )-1,1)) as 'Units',  
substring(cast(a.Amount as varchar),CHARINDEX('.', a.Amount)+1,2) as 'Cents'  
From APPB a  
  
  
  
  
  
  
GO
GRANT SELECT ON  [dbo].[vrvAPPBaus] TO [public]
GRANT INSERT ON  [dbo].[vrvAPPBaus] TO [public]
GRANT DELETE ON  [dbo].[vrvAPPBaus] TO [public]
GRANT UPDATE ON  [dbo].[vrvAPPBaus] TO [public]
GO
