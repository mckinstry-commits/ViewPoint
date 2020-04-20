SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMGetNextPMDocNum   Script Date: 11/03/2004 ******/
CREATE  procedure [dbo].[vspJCGetNextSeqNum]
/************************************************************************
* Created By:		CHS 07/17/2009 - Issue #134813
* Modified By:	
*
* INPUT PARAMS:
* @jcco			JC Company
* @job			JC Project
* @phase		JC Document TYPE
* @phasegroup	JC Document Type
* @costtype		JC Calling Form  
*    
* OUTPUT PARAMS
* @nextseq	Next sequence number.
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/
(@jcco bCompany, @job bJob, @phasegroup bGroup, @phase bPhase = null, @costtype bJCCType = null,
	@nextseq int = null output, @errmsg varchar(255) output)
	
as
set nocount on

declare @rcode integer

select @rcode = 0, @nextseq = 0 

---- validate parameters
if @jcco is null
   	begin
   	select @errmsg = 'Missing JC Company.', @rcode = 1
   	goto bspexit
   	end

if @job is null
   	begin
   	select @errmsg = 'Missing JC Job.', @rcode = 1
   	goto bspexit
   	end

if @phasegroup is null
   	begin
   	select @errmsg = 'Missing JC Phase Group.', @rcode = 1
   	goto bspexit
   	end

if @phase is null
   	begin
   	select @errmsg = 'Missing JC Phase.', @rcode = 1
   	goto bspexit
   	end

if @costtype is null
   	begin
   	select @errmsg = 'Missing JC CostType.', @rcode = 1
   	goto bspexit
   	end


---- try to get the next numeric sequnce number

select @nextseq = isnull(max(DetSeq),0)+1
	from JCPD d with (nolock) 
	where d.Co = @jcco 
		and d.Job = @job 
		and d.PhaseGroup = @phasegroup 
		and d.Phase = @phase 
		and d.CostType = @costtype


if @@rowcount = 0
	begin
	select @errmsg = 'Error getting next sequence value!', @rcode = 1
	goto bspexit
	end


bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCGetNextSeqNum] TO [public]
GO
