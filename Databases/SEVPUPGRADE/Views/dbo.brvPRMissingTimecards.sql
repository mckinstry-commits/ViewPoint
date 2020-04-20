SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[brvPRMissingTimecards] as SELECT PREH.PRCo, PREH.Employee, PREH.SortName,PREH.LastName, PREH.FirstName, PREH.MidName, PREH.PRGroup, 
         PREH.PRDept, PREH.Craft, PREH.JCCo, PREH.Job, PREH.ActiveYN,
         PRPC.PREndDate
     FROM PRPC
     Full Outer JOIN PREH on PREH.PRCo=PRPC.PRCo and PREH.PRGroup=PRPC.PRGroup
    
     WHERE  PREH.ActiveYN = 'Y' AND 
         not exists (select * from PRTH where PREH.PRCo = PRTH.PRCo AND PREH.PRGroup = PRTH.PRGroup AND
     	    PREH.Employee = PRTH.Employee and PRTH.PREndDate=PRPC.PREndDate)

GO
GRANT SELECT ON  [dbo].[brvPRMissingTimecards] TO [public]
GRANT INSERT ON  [dbo].[brvPRMissingTimecards] TO [public]
GRANT DELETE ON  [dbo].[brvPRMissingTimecards] TO [public]
GRANT UPDATE ON  [dbo].[brvPRMissingTimecards] TO [public]
GO
