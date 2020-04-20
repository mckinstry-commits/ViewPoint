SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMOHDesc    Script Date: 11/15/2005 ******/
CREATE  proc [dbo].[vspPMOHDesc]
/*************************************
 * Created By:	GF 11/15/2005
 * Modified by:
 *
 * called from PMACO to return project ACO key description
 * and ACO Sequence number.
 *
 * Pass:
 * PMCo			PM Company
 * Project		PM Project
 * ACO			PM ACO
 *
 * Returns:
 * ACOSequence	Next ACO Sequence number for default
 * DfltStatus	Default final status from PMCO or PMSC
 *
 * Success returns:
 *	0 and Description from PMOH
 *
 * Error returns:
 * 
 *	1 and error message
 **************************************/
(@pmco bCompany, @project bJob, @aco bACO,
 @acoseq smallint = 0 output, @dfltstatus varchar(6) = null output, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @jcacoseq int, @pmacoseq int

select @rcode = 0, @msg = '', @jcacoseq = 0, @pmacoseq = 0

-- -- -- get description from PMOP
if isnull(@aco,'') <> ''
	begin
	select @msg = Description
	from PMOH with (nolock) where PMCo=@pmco and Project=@project and ACO=@aco
	end

-- -- -- get default final status from PMCo or PMSC
select @dfltstatus = FinalStatus from PMCO with (nolock) where PMCo=@pmco
if isnull(@dfltstatus,'') = ''
	begin
	select @dfltstatus = min(Status) from PMSC with (nolock) where CodeType='F'
	end

-- -- -- get PMOH ACOSequence
select @pmacoseq = 1 + isnull(max(ACOSequence),0)
from PMOH where PMCo=@pmco and Project=@project
if @pmacoseq is null select @pmacoseq = 0
-- -- -- get JCOH ACOSequence
select @jcacoseq = 1 + isnull(max(ACOSequence),0)
from JCOH where JCCo=@pmco and Job=@project
if @jcacoseq is null select @jcacoseq = 0
-- -- -- set next ACO Sequence number
if @pmacoseq = 0 and @jcacoseq = 0 select @acoseq = 1
if @pmacoseq > @jcacoseq select @acoseq = @pmacoseq
if @pmacoseq <= @jcacoseq select @acoseq = @jcacoseq



bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMOHDesc] TO [public]
GO
