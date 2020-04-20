SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE  view [dbo].[brvPRECConvert]
   
   as
   
   Select cPRCo=PRCo,cEarnCode=Convert(varchar(10),(space(10-datalength(convert(varchar(10),EarnCode))) + convert(varchar(10),EarnCode))),EDLType = 'E',* From PREC
   
   
   
  
 



GO
GRANT SELECT ON  [dbo].[brvPRECConvert] TO [public]
GRANT INSERT ON  [dbo].[brvPRECConvert] TO [public]
GRANT DELETE ON  [dbo].[brvPRECConvert] TO [public]
GRANT UPDATE ON  [dbo].[brvPRECConvert] TO [public]
GO
