SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspJCPPPhasesInsert    Script Date: 8/28/99 9:35:04 AM ******/
CREATE   PROC [dbo].[bspJCPPPhasesInsert]
/************************************************************
* Created By:
* Modified TV - 23061 added isnulls
*
* Inserts Selected phases from progress entry.
*
*
*************************************************************/
(@jcco bCompany, @month bMonth, @batchid bBatchID, @job bJob, @PhaseGroup tinyint,
 @phase bPhase, @msg varchar(60) output)
as
set nocount on

declare @rcode integer

set @rcode = 0

if not exists(select 1 from dbo.JCJM with (nolock) where JCCo=@jcco and Job=@job)
	begin
	select @msg = 'Job not in Job Master!', @rcode = 1
	goto bspexit
	end

if not exists(select 1 from dbo.JCJP with (nolock) where JCCo=@jcco and Job=@job and Phase=@phase) 
	begin
	select @msg = 'Phase not in Job Phases!', @rcode = 1
	goto bspexit
	end

---- insert phases into JCPPPhases
insert into bJCPPPhases
values(@jcco, @month, @batchid, @job, @PhaseGroup, @phase)
   
bspexit:
	return @rcode
   


GO
GRANT EXECUTE ON  [dbo].[bspJCPPPhasesInsert] TO [public]
GO
