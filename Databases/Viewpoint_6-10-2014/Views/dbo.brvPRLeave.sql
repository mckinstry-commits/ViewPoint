SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE            view [dbo].[brvPRLeave]
 as 
 
 /*******************************
 Created 10/17/05 JH
 
 This view calculates the leave usage and accrual amounts from the current pay period before the 
 auto-leave process has been run.
 
 Reports:  PRLeaveExcept.rpt
 *******************************/
 

--Usage calculated from PRAU - Leave Code setup
select h.PRCo, h.PRGroup, h.PREndDate, h.Employee, h.PaySeq, h.PostSeq, h.PostDate, h.EarnCode, h.Hours, h.Amt, u.LeaveCode, u.Type, u.Basis, u.Rate,
Usage=(case when u.Basis='H' then u.Rate*h.Hours else u.Rate*h.Amt end)
 from PRTH h
left outer join PRAU u on h.PRCo=u.PRCo and h.EarnCode=u.EarnCode 
JOIN PREL e on e.PRCo=u.PRCo and h.Employee=e.Employee and u.LeaveCode=e.LeaveCode
where
NOT EXISTS
   (SELECT *
   FROM PRLB where e.PRCo=PRLB.PRCo and e.Employee=PRLB.Employee and e.LeaveCode=PRLB.LeaveCode)

UNION ALL

--usage from the employee overrides in PR Employee Leave
select h.PRCo, h.PRGroup, h.PREndDate, h.Employee, h.PaySeq, h.PostSeq, h.PostDate, h.EarnCode, h.Hours, h.Amt, l.LeaveCode, l.Type, l.Basis, l.Rate,
Usage=(case when l.Basis='H' then l.Rate*h.Hours else l.Rate*h.Amt end)
 from PRTH h
join PRLB l on h.PRCo=l.PRCo and h.Employee=l.Employee and h.EarnCode=l.EarnCode

GO
GRANT SELECT ON  [dbo].[brvPRLeave] TO [public]
GRANT INSERT ON  [dbo].[brvPRLeave] TO [public]
GRANT DELETE ON  [dbo].[brvPRLeave] TO [public]
GRANT UPDATE ON  [dbo].[brvPRLeave] TO [public]
GRANT SELECT ON  [dbo].[brvPRLeave] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvPRLeave] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvPRLeave] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvPRLeave] TO [Viewpoint]
GO
