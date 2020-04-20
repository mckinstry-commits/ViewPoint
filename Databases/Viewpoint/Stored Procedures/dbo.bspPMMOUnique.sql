SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/******************************************************/
CREATE  proc [dbo].[bspPMMOUnique]
/***********************************************************
 * CREATED BY:	GF 02/14/2002
 * MODIFIED BY: GF 12/05/2003 - #23212 - check error messages, wrap concatenated values with isnull
 *				GF 05/27/2008 - issue #128452 check for non interfaced PMMF
 *
 *
 * USAGE:
 * validates MO to insure that it is unique.  Checks INMO and INMB 
 *
 * INPUT PARAMETERS
 *  PMCo		PM Company to validate against
 *	Project		PM Project to validate against
 *	INCo		IN Company to validate against
 *  MO			MO to Validate
 * 
 * OUTPUT PARAMETERS
 *   @msg     
 * RETURN VALUE
 *   0         success
 *   1         Failure  'if Fails THEN it fails.
 *****************************************************/ 
(@pmco bCompany = null, @project bJob = null, @inco bCompany = null, @mo varchar(10) = null,
 @moinbatch varchar(100) = null output, @nonintfcflag bYN = 'Y' output,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @jcco bCompany, @job bJob

select @rcode = 0, @nonintfcflag = 'Y'

if @pmco is null
   	begin
   	select @msg = 'Missing PM Company', @rcode = 1
   	goto bspexit
   	end

if @project is null
   	begin
   	select @msg = 'Missing PM Project', @rcode = 1
   	goto bspexit
   	end

if @inco is null
   	begin
   	select @msg = 'Missing IN Company', @rcode = 1
   	goto bspexit
   	end

---- get description for INMO
select @msg = Description
from INMO with (nolock) where INCo=@inco and MO=@mo
if @@rowcount = 0
	begin
	select @msg = 'Material Order not on file'
	goto bspexit
	end

---- check for PMMF detail not yet interfaced
if not exists(select 1 from PMMF where PMCo=@pmco and INCo=@inco and MO=@mo and InterfaceDate is null)
	begin
	select @nonintfcflag = 'N'
	end

---- check if MO assigned to a different JCCo, Job
select @jcco=JCCo, @job=Job
from INMO with (nolock) where INCo=@inco and MO=@mo
if @@rowcount <> 0
	begin
	if @jcco <> @pmco or @job <> @project
		begin
		select @msg = 'MO: ' + isnull(@mo,'') + ' already exists for JCCo: ' + convert(varchar(3),@jcco) + ' and Project: ' + isnull(@job,'') + ' !', @rcode = 1
		goto bspexit
		end
	end

---- check to make sure it is not in a batch
select @moinbatch = 'Warning: MO: ' + isnull(@mo,'') + ' is in use for Batch Month: ' + substring(convert(varchar(12),Mth,3),4,5) + ' Batch Id: ' + convert(varchar(10),BatchId)
from bINMB with (nolock) where Co=@inco and MO=@mo
if @@rowcount = 0 select @moinbatch = ''



bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMMOUnique] TO [public]
GO
