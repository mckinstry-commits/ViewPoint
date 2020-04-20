SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.vspJCJMDesc    Script Date: 05/03/2005 ******/
CREATE  proc [dbo].[vspJCJMDesc]
/*************************************
 * Created By:	GF 05/03/2005
 * Modified By:	CHS 11/24/08 - #130774 - added country output parameter
 *				CHS 11/24/08 - #124188
 *				GF 01/20/2010 - issue #137646 misspelling in warning
 *				06/25/2010 GF - ISSUE #135813 expanded SL to varchar(30)
 *				GF 01/15/2011 - issue #142721 the check for POIT/SLIT using wrong company
 *				GF 07/30/2011 - TK-07143 PO expanded
 *
 *
 * USAGE:
 * Called from JCJM and PM Projects to get key description for job. If new job, checks
 * the Job Cost History table to see if the Job number has been used.
 *
 *
 * INPUT PARAMETERS
 * @jcco			JC Company
 * @job				JC Job
 * @validatestatus	validate job status for jc where 'Y' will not allow pending contract to be entered.
 *
 * Success returns:
 *	0 and Description from JCJM
 *
 * Error returns:
 *	1 and error message
 **************************************/
(@jcco bCompany, @job bJob, @validatestatus char(1), @country varchar(10) output, @msg varchar(255) output)
as
set nocount on


select @country = HQCO.DefaultCountry
from HQCO with (nolock)
left join JCCO with (nolock) on JCCO.JCCo = @jcco
where HQCO.HQCo = isnull(JCCO.PRCo, @jcco)


declare @rcode int, @contract bContract, @jobstatus tinyint

select @rcode = 0, @msg = ''

if isnull(@job,'') = ''
	begin
   	select @msg = 'Job cannot be null.', @rcode = 1
   	goto bspexit
	end



-- -- -- get job description, if job exists done no check of history needed
select @jobstatus = JobStatus, @msg=Description
from bJCJM with (nolock) where JCCo=@jcco and Job=@job
if @@rowcount = 1 
	begin 
		if isnull(@validatestatus,'N') = 'Y' and isnull(@jobstatus,98) = 0
			begin
				select @msg = 'Job is pending, access not allowed.', @rcode = 1
				goto bspexit
			end
		goto bspexit
   end


-- check if job used somewhere
if not exists(select 1 from bJCJM with (nolock) where JCCo=@jcco and Job=@job)
	begin
		-- check job cost history for job
		if exists(select 1 from bJCHJ with (nolock) where JCCo=@jcco and Job=@job)
			begin
				select top 1 @contract=Contract from bJCHJ with (nolock) where JCCo=@jcco and Job=@job
				select @msg = @job + ' was previously used with contract ' + isnull(@contract,'') + '. Cannot' + char(13) + char(10) +
							' use ' + isnull(@job,'') + ' until the contract is purged from Contract/Job ' + char(13) + char(10) +
							'History - use JC Contract Purge form to purge contract.', @rcode = 1
				goto bspexit	
			end
		

		-- check POIT for job - #124188
		---- #142721
		if exists(select 1 from bPOIT with (nolock) WHERE PostToCo=@jcco and Job=@job)
			BEGIN
			----TK-07143
				declare @po VARCHAR(30), @poitem bItem
				select top 1 @po=PO, @poitem=POItem from bPOIT with (nolock) where PostToCo=@jcco and Job=@job
				select @msg = 'Job ' + ltrim(@job) + ' is associated with PO ' + rtrim(isnull(@po,'')) + '.' + char(13) + char(10) + 
							'Cannot use ' + ltrim(isnull(@job,'')) + ' until the job is purged from PO.' + char(13) + char(10) + 
							'Use PO Purge Form to purge PO.', @rcode = 1
				goto bspexit	
			end

		-- check SLIT for job - #124188
		---- #142721
		if exists(select 1 from bSLIT with (nolock) where JCCo=@jcco and Job=@job)
			begin
				declare @sl VARCHAR(30), @slitem bItem
				select top 1 @sl=SL, @slitem=SLItem from bSLIT with (nolock) where JCCo=@jcco and Job=@job
				select @msg = 'Job ' + ltrim(@job) + ' is associated with SL ' + rtrim(isnull(@sl,'')) + '.' + char(13) + char(10) + 
							'Cannot use ' + ltrim(isnull(@job,'')) + ' until the job is purged from SL.' + char(13) + char(10) +
							'Use SL Purge Form to purge SL.', @rcode = 1
				goto bspexit	
			end

		-- check APTL for job - #124188
		if exists(select 1 from bAPTL with (nolock) where JCCo=@jcco and Job=@job)
			begin
				declare @apref bAPReference
				select top 1 @apref=h.APRef from bAPTL l with (nolock) 
					left join bAPTH h with (nolock) on h.APCo = l.APCo and h.Mth = l.Mth and h.APTrans = l.APTrans
					where l.JCCo=@jcco and l.Job=@job
				select @msg = 'Job ' + ltrim(@job) + ' is associated with AP Invoices ' + rtrim(isnull(@apref,'')) + char(13) + '.' + char(10) + 
							'Cannot use ' + ltrim(isnull(@job,'')) + ' until the job is purged from AP.' + char(13) + char(10) + 
							'Use AP Purge Form to purge AP Invoices.' + char(13) + char(10), @rcode = 1
				goto bspexit	
			end

	end

bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCJMDesc] TO [public]
GO
