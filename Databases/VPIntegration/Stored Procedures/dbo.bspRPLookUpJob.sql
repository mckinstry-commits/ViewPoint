SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspRPLookUpJob] (@JCCo bCompany = null)
   as
   select distinct Job, Description, JobStatus
   from JCJM
   where JCCo=isnull(@JCCo,1)

GO
GRANT EXECUTE ON  [dbo].[bspRPLookUpJob] TO [public]
GO
