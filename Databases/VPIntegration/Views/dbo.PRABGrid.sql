SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   view [dbo].[PRABGrid]
   /***************************************
   *	Created by:		??
   *	Modified by:	EN 2/23/05 - added with (nolock)
   *	Used by:		form PRLeaveEntry
   ****************************************/
    as select top 100 percent
      a.Co, a.Mth, a.BatchId, a.BatchSeq,
      a.BatchTransType, a.Trans, a.Employee,
      'Name'= e.LastName + ', ' + isnull(e.FirstName,'') + ' ' + isnull(e.MidName,''), a.LeaveCode,
      a.ActDate, a.Type, a.Amt, a.Accum1Adj, a.Accum2Adj, a.AvailBalAdj, a.Description
      from PRAB a with (nolock)
      inner join PREH e with (nolock) on e.PRCo=a.Co and e.Employee=a.Employee
      order by a.Co, a.Mth, a.BatchId, a.BatchSeq

GO
GRANT SELECT ON  [dbo].[PRABGrid] TO [public]
GRANT INSERT ON  [dbo].[PRABGrid] TO [public]
GRANT DELETE ON  [dbo].[PRABGrid] TO [public]
GRANT UPDATE ON  [dbo].[PRABGrid] TO [public]
GO
