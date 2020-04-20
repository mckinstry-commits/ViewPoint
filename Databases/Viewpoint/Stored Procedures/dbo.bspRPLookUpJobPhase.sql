SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspRPLookUpJobPhase] (@JCCo bCompany = null, @Job bJob = null)
   as
   select distinct Phase, Description
   from JCJP
   where JCCo=isnull(@JCCo,JCCo) and Job=isnull(@Job,Job)

GO
GRANT EXECUTE ON  [dbo].[bspRPLookUpJobPhase] TO [public]
GO
