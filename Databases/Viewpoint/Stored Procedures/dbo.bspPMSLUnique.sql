SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMSLUnique    Script Date: 8/28/99 9:35:19 AM ******/
CREATE     proc [dbo].[bspPMSLUnique]
/***********************************************************
 * Created By:	kb 12/24/97
 * Modified By:	GF 05/19/2000 - don't check different project
 *				GF 09/26/2006 - 6.x change to check JCCo/Job and batch message
 *				GF 05/27/2008 - issue #128452 check for non interfaced PMSL
 *				GF 12/11/2009 - issue #137003 check for co and job match changed to 'or'
 *				GF 06/28/2010 - issue #135813 SL expanded to 30 characters
 *
 *
 * USAGE:
 * validates SL to insure that it is unique.  Checks SLHD and SLHB
 *
 * INPUT PARAMETERS
 * SLCo			SL Co to validate against
 * PMCo			PM Company
 * Project		PM Project
 * SL			SL to Validate
 *
 * OUTPUT PARAMETERS
 *   @msg
 * RETURN VALUE
 *   0         success
 *   1         Failure  'if Fails THEN it fails.
 *****************************************************/
(@slco bCompany = 0, @pmco bCompany, @project bJob, @sl VARCHAR(30),
 @slinbatch varchar(100) = null output, @nonintfcflag bYN = 'Y' output,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @jcco bCompany, @job bJob

select @rcode = 0, @slinbatch = '', @nonintfcflag = 'Y'

-- -- -- get description for SLHD
select @msg = Description, @jcco=JCCo, @job=Job
from SLHD with (nolock) where SLCo=@slco and SL=@sl
if @@rowcount = 0
	begin
	select @msg = 'Subcontract not on file'
	goto bspexit
	end

---- check for PMSL detail not yet interfaced
if not exists(select 1 from PMSL where PMCo=@pmco and SLCo=@slco and SL=@sl and InterfaceDate is null)
	begin
	select @nonintfcflag = 'N'
	end

if isnull(@jcco,0) <> @pmco or isnull(@job,'') <> @project
	begin
	select @msg='SL: ' + isnull(@sl,'') + ' already exists for JCCo: ' + isnull(convert(varchar(3),@jcco),'') + ' and Job: ' + isnull(@job,'') + '!', @rcode = 1
	goto bspexit
	end

-- -- -- check to make sure it is not in a batch
select @slinbatch = 'Warning: SL: ' + isnull(@sl,'') + ' is in use for Batch Month: ' + substring(convert(varchar(12),Mth,3),4,5) + ' Batch Id: ' + convert(varchar(10),BatchId)
from bSLHB with (nolock) where Co=@slco and SL=@sl
if @@rowcount = 0 select @slinbatch = ''




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMSLUnique] TO [public]
GO
