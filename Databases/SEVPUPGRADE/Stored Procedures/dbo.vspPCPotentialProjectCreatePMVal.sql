SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE proc [dbo].[vspPCPotentialProjectCreatePMVal]
/***********************************************************
* CREATED BY:	GP	12/06/2010
* MODIFIED BY:
*				JG 01/28/2011 - issue #142580 added checks for the use of the project/job
*				GP 09/05/2012 - TK-17612 Changed bPO to varchar(30)
*				
* USAGE:
* Used in PC Potential Project Create PM to validate Job/Project value
*
* INPUT PARAMETERS
* JCCo   
* PotentialProject 
*
* OUTPUT PARAMETERS
* @msg				PC Potential Project Description of Department if found.
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 
(@JCCo bCompany, @Project bJob, @SubDetailOnly bYN, @msg varchar(255) output)
as
set nocount on
  
declare @rcode int, @Contract bContract

set @rcode = 0

--validation
if isnull(@JCCo,'') = ''
begin
	select @msg = 'JCCo missing.', @rcode = 1
	goto vspexit
end

if isnull(@Project,'') = ''
begin
	select @msg = 'Project missing.', @rcode = 1
	goto vspexit
end

-- check if job used somewhere
if not exists(select 1 from bJCJM with (nolock) where JCCo=@JCCo and Job=@Project)
	begin
		-- check job cost history for job
		if exists(select 1 from bJCHJ with (nolock) where JCCo=@JCCo and Job=@Project)
			begin
				select top 1 @Contract=Contract from bJCHJ with (nolock) where JCCo=@JCCo and Job=@Project
				select @msg = @Project + ' was previously used with contract ' + isnull(@Contract,'') + '. Cannot' + char(13) + char(10) +
							'use ' + isnull(@Project,'') + ' until the contract is purged from Contract/Project ' + char(13) + char(10) +
							'History - use JC Contract Purge form to purge contract.', @rcode = 1
				goto vspexit	
			end
		

		-- check POIT for job - #124188
		---- #142721
		if exists(select 1 from bPOIT with (nolock) WHERE PostToCo=@JCCo and Job=@Project)
			begin
				declare @po varchar(30), @poitem bItem
				select top 1 @po=PO, @poitem=POItem from bPOIT with (nolock) where PostToCo=@JCCo and Job=@Project
				select @msg = 'Project ' + ltrim(@Project) + ' is associated with PO ' + rtrim(isnull(@po,'')) + '.' + char(13) + char(10) + 
							'Cannot use ' + ltrim(isnull(@Project,'')) + ' until the project is purged from PO.' + char(13) + char(10) + 
							'Use PO Purge Form to purge PO.', @rcode = 1
				goto vspexit	
			end

		-- check SLIT for job - #124188
		---- #142721
		if exists(select 1 from SLIT with (nolock) where JCCo=@JCCo and Job=@Project)
			begin
				declare @sl VARCHAR(30), @slitem bItem
				select top 1 @sl=SL, @slitem=SLItem from SLIT with (nolock) where JCCo=@JCCo and Job=@Project
				select @msg = 'Project ' + ltrim(@Project) + ' is associated with SL ' + rtrim(isnull(@sl,'')) + '.' + char(13) + char(10) + 
							'Cannot use ' + ltrim(isnull(@Project,'')) + ' until the project is purged from SL.' + char(13) + char(10) +
							'Use SL Purge Form to purge SL.', @rcode = 1
				goto vspexit	
			end

		-- check APTL for job - #124188
		if exists(select 1 from bAPTL with (nolock) where JCCo=@JCCo and Job=@Project)
			begin
				declare @apref bAPReference
				select top 1 @apref=h.APRef from bAPTL l with (nolock) 
					left join bAPTH h with (nolock) on h.APCo = l.APCo and h.Mth = l.Mth and h.APTrans = l.APTrans
					where l.JCCo=@JCCo and l.Job=@Project
				select @msg = 'Project ' + ltrim(@Project) + ' is associated with AP Invoices ' + rtrim(isnull(@apref,'')) + char(13) + '.' + char(10) + 
							'Cannot use ' + ltrim(isnull(@Project,'')) + ' until the project is purged from AP.' + char(13) + char(10) + 
							'Use AP Purge Form to purge AP Invoices.' + char(13) + char(10), @rcode = 1
				goto vspexit	
			end

	end

--check if job exists
if @SubDetailOnly = 'Y'
begin
	if not exists (select top 1 1 from dbo.JCJMPM where JCCo = @JCCo and Project = @Project)
	begin
		select @msg = 'Project must already exist.', @rcode = 1
		goto vspexit
	end
	
	if (select JobStatus from dbo.JCJMPM where JCCo = @JCCo and Project = @Project) <> 0
	begin
		select @msg = 'Project Status must be Pending.', @rcode = 1
		goto vspexit		
	end
end

if @SubDetailOnly = 'N' and exists (select top 1 1 from dbo.JCJMPM where JCCo = @JCCo and Project = @Project)
begin
	select @msg = 'Project must not already exist.', @rcode = 1
	goto vspexit
end

--get description
select @msg = [Description] from dbo.JCJMPM where JCCo = @JCCo and Project = @Project


vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPCPotentialProjectCreatePMVal] TO [public]
GO
