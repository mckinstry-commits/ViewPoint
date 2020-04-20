SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/*****************************************
   * Created By:
   * Modfied By:
   *
   * Provides a view of JC Job Jobs not pending
   *
   *****************************************/
   
   CREATE  view [dbo].[JCJMJobs] as
select a.* From dbo.JCJM a WHERE a.JobStatus > 0




GO
GRANT SELECT ON  [dbo].[JCJMJobs] TO [public]
GRANT INSERT ON  [dbo].[JCJMJobs] TO [public]
GRANT DELETE ON  [dbo].[JCJMJobs] TO [public]
GRANT UPDATE ON  [dbo].[JCJMJobs] TO [public]
GO
