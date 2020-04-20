SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE    proc [dbo].[vspPMInterfaceProjectVal]
/************************************
* CREATED BY:	TRL 04/19/2011 TK-04412
* MODIFIED BY:	GF 02/15/2012 TK-12748 #145870 do not try to update force phase item to JCJP if the phase is inactive. trigger error occurs
*
* USAGE: used by PMProjectInterface validate Project to see if it can be interfaced
*
* Pass in :
*	PMCo, Project, Mth, 
*
* Output
*  errmsg
*
* Returns
*	Error message and return code
*******************************/
(@pmco bCompany = 0, @project bJob = NULL, @interfacetype varchar(50) = NULL,
 @id varchar(50), @apco bCompany = 0, @mth bMonth = NULL, @errmsg varchar(255) output)

as

set nocount on
 
declare @rcode int,@PostClosedJobs bYN,@PostSoftClosedJobs bYN,@JobStatus tinyint, 
		@LiabilityTemplate int, @PRState varchar(4), @Contract bContract,@StartMonth bMonth,
		@InactiveCheck varchar(2000),@ValidCnt int,@Phase bPhase, @CostType bJCCType
 
select @rcode = 0,@ValidCnt = 0

If IsNull(@interfacetype,'') = ''
begin
	select @errmsg = 'Missing interface type',@rcode = 1
	goto vspexit
end

-- Validate and check to make sure Job is not closed
select @PostClosedJobs=PostClosedJobs, @PostSoftClosedJobs=PostSoftClosedJobs
from dbo.JCCO 
where JCCo=@pmco
if @@rowcount = 0
begin
	select @errmsg = 'Company ' + convert(varchar(3),@pmco) + ' is not a valid JC Company', @rcode=1
	goto vspexit
end

-- check project
select @JobStatus=JobStatus, @Contract=[Contract],@LiabilityTemplate=LiabTemplate,@PRState=PRStateCode
from dbo.JCJM 
where JCCo=@pmco and Job=@project
if @@rowcount=0
begin
	select @errmsg='Job ' + isnull(@project,'') + ' must be setup in JC Job Master ' + convert(varchar(3),@pmco), @rcode=1
	goto vspexit
end
---- check job status and post closed job flags
if @JobStatus = 2 and @PostSoftClosedJobs = 'N'
begin
	select @errmsg='Job ' + isnull(@project,'') + ' is soft-closed and you are not allowed to post to soft-closed jobs in company ' + convert(varchar(3),@pmco), @rcode=1
	goto vspexit
end
---- check job status and post closed job flags
if @JobStatus = 3 and @PostClosedJobs = 'N'
begin
	select @errmsg='Job ' + isnull(@project,'') + ' is hard-closed and you are not allowed to post to hard-closed jobs in company ' + convert(varchar(3),@pmco), @rcode=1
	goto vspexit
end

if @LiabilityTemplate is null
begin
	select @errmsg='Job ' + isnull(@project,'') + ' Project is missing Liability Template, must be assigned before interface', @rcode=1
	goto vspexit
end

if IsNull(@PRState,'') = ''
begin
	select @errmsg='Job ' + isnull(@project,'') + ' Project is missing PR State, must be assigned before interface ', @rcode=1
	goto vspexit
end

--Check the contract start month.  For originals, mth is entered in JCCH trigger;
--for Change Orders, POs, SLs, must be equal or after
select @StartMonth=StartMonth
from dbo.JCCM 
where JCCo=@pmco and Contract=@Contract
if @mth < @StartMonth
begin
 	select @errmsg='The month must be equal to or after the contract start month. ' + convert(varchar(12),@StartMonth), @rcode=1
 	goto vspexit
end

IF @interfacetype = 'Project Update' OR @interfacetype = 'Project Pending'
begin
	-- check JCJP.Active = 'N' with JCCH.SourceStatus='Y' ready to interface. Do not allow
	select @Phase=a.Phase, @CostType=a.CostType
	from dbo.JCCH a 
	inner join dbo.JCJP b on b.JCCo=a.JCCo and b.Job=a.Job and b.Phase=a.Phase
	where a.JCCo=@pmco and a.Job=@project and a.SourceStatus='Y' and b.ActiveYN='N'
	if @@rowcount <> 0
	begin
		select @errmsg = 'Phase: ' + isnull(@Phase,'') + ' is inactive. Activate Phase before interfacing.', @rcode=1
		goto vspexit
	end
end

----Validate PO company
--If @interfacetype In ('Purchase Order - Original','Purchase Order CO')
--begin
--	if not exists(select * from dbo.POCO where POCo=@apco)
--	begin
--		select @errmsg = 'PO Company is not set up. Cannot interface Purchase Orders.', @rcode = 1
--		goto vspexit
--	end
--end	 
 	
----Validate SL company
--If @interfacetype In ('Subcontract - Original','Subcontract CO')
--begin
--	if not exists(select * from dbo.SLCO where SLCo=@apco)
--	begin
--		select @errmsg = 'SL Company is not set up. Cannot interface Purchase Orders.', @rcode = 1
--		goto vspexit
--	end
--end	 

vspexit:
	return @rcode 
 

GO
GRANT EXECUTE ON  [dbo].[vspPMInterfaceProjectVal] TO [public]
GO
