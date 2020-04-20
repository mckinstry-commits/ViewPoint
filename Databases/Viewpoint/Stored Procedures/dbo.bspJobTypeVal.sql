SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJobTypeVal    Script Date: 8/28/99 9:35:08 AM ******/
 CREATE          procedure [dbo].[bspJobTypeVal]
/***********************************************************
    * CREATED: SE   4/30/97
    * MODIFIED: kf 5/28/97
    *				GG 03/12/02 - cleanup, used for IN Material Orders
    *				SR 07/09/02 - issue 17738 passing @PhaseGroup to bspJCVPHASE & bspJCVCOSTTYPE
    *		        DANF 09/05/02 - issue 17738 Add @PhaseGroup as a parameter.		
    *				TV - 23061 added isnulls
    *				MV 06/08/04 - #24776 - fix Job error message.
*					GF 12/12/2007 - issue #25569 use separate closed job flags in JCCo enhancement
*
*
    * USAGE:
    * Validates Job, Phase, and Cost Type information for PO, SL, and MO
    *
    * Used in PORBVal, POCBVal, POHBVal, SLCBVal, SLXBVal, INMBVal
    *
    * INPUTS
    *   @jcco			Job Cost Co#
    *   @phasegroup 	Group
    *   @job       	Job 
    *   @phase     	Phase 
    *   @costtype  	Cost type 
    *
    * OUTPUTS
    *   @jcum		Job cost unit of measure
    *   @errmsg	Error message 
    *
    * RETURNS
    *   0 on SUCCESS
    *   1 on FAILURE
    *
    *****************************************************/
 @jcco bCompany = null, @phasegroup bGroup = null, @job bJob = null, @phase bPhase = null, @costtype bJCCType = null,
 @jcum bUM = null output, @errmsg varchar(255) output
as
set nocount on

declare @rcode int, @postclosedjobs bYN, @postsoftclosedjobs bYN, @status tinyint, @sendjcct varchar(5)

select @rcode = 0, @errmsg = 'Valid'
   
-- validate Job Co#
select @postclosedjobs = PostClosedJobs, @postsoftclosedjobs=PostSoftClosedJobs
from bJCCO where JCCo = @jcco
if @@rowcount = 0
   	begin
	select @errmsg = 'Company ' + isnull(convert(varchar(3),@jcco),'') + ' is not a valid JC Co#.', @rcode = 1
	goto bspexit
	end

-- validate Job
select @status = JobStatus
from bJCJM where JCCo = @jcco and Job = @job
if @@rowcount=0
	begin
	select @errmsg = 'Job: ' + isnull(@job,'') + ' is not setup in JC Co#: ' + isnull(convert(varchar(3),@jcco),''), @rcode = 1
	goto bspexit
	end
if @status = 2 and @postsoftclosedjobs = 'N'
	begin
	select @errmsg = 'Job: ' + isnull(@job,'') + ' is soft-closed.', @rcode=1
	goto bspexit
	end
if @status = 3 and @postclosedjobs = 'N'
	begin
	select @errmsg = 'Job: ' + isnull(@job,'') + ' is hard-closed.', @rcode=1
	goto bspexit
	end

-- validate Phase
exec @rcode = bspJCVPHASE @jcco, @job, @phase, @phasegroup, 'N', @msg=@errmsg output
if @rcode = 1 goto bspexit

-- validate Cost Type
select @sendjcct = convert(varchar(5),@costtype)
exec @rcode = bspJCVCOSTTYPE @jcco, @job, @phasegroup,@phase, @sendjcct, 'N', @um = @jcum output, @msg=@errmsg output
if @rcode = 1 goto bspexit





bspexit:
	
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJobTypeVal] TO [public]
GO
