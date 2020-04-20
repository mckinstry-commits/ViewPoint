SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
   /*Modified 10/31/2010 CW Issue 140541 Changed linkage of view PRDB from to support new columns EDLCode and EDLType. */     

CREATE VIEW [dbo].[brvPREarnings] as select PRTH.PRCo, PRGroup, PREndDate, Employee, PaySeq, PostSeq, RecType='Timecard', AddonEarnCode=0, DLCode, Rate, Hours, Amt
    From PRTH
    Join PRDB d on d.PRCo=PRTH.PRCo and d.EDLCode=PRTH.EarnCode and d.EDLType='E'
    union
    select PRTA.PRCo, PRGroup, PREndDate, Employee, PaySeq, PostSeq, 'Addon', PRTA.EarnCode, DLCode, Rate, 0, Amt
    From PRTA
    Join PRDB d on d.PRCo=PRTA.PRCo and d.EDLCode=PRTA.EarnCode and d.EDLType='E'


GO
GRANT SELECT ON  [dbo].[brvPREarnings] TO [public]
GRANT INSERT ON  [dbo].[brvPREarnings] TO [public]
GRANT DELETE ON  [dbo].[brvPREarnings] TO [public]
GRANT UPDATE ON  [dbo].[brvPREarnings] TO [public]
GRANT SELECT ON  [dbo].[brvPREarnings] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvPREarnings] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvPREarnings] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvPREarnings] TO [Viewpoint]
GO
