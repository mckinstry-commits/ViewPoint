SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspPMPOUnique    Script Date: 8/28/99 ******/
CREATE proc [dbo].[bspPMPOUnique]
/***********************************************************
 * Created By:	CJW 12/9/97
 * Modified By:	SAE 2/18/98
 *				GF 09/26/2006 - 6.x change to check JCCo/Job and batch message
 *				GF 05/27/2008 - issue #128452 check for non interfaced PMMF
 *				GF 12/11/2009 - issue #137003 check for co and job match changed to 'or'
 *				TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
 *				GP 4/3/2012 - TK-13774 added check against pending purchase order table
 *
 * USAGE:
 * validates PO to insure that it is unique.  Checks POHD and POHB 
 *
 * INPUT PARAMETERS
 * POCo			PO Co to validate against
 * PMCo			PM Company
 * Project		PM Project
 * PO			PO to Validate
 *
 * 
 * OUTPUT PARAMETERS
 * @poinbatch warning message
 * @nonintfcflag	non interfaced PMMF records exists
 * @msg     
 *
 * RETURN VALUE
 *   0         success
 *   1         Failure  'if Fails THEN it fails.
 *****************************************************/ 
(@poco bCompany = 0, @pmco bCompany, @project bJob, @po varchar(30), 
 @poinbatch varchar(100) = null output, @nonintfcflag bYN = 'Y' output,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @jcco bCompany, @job bJob

select @rcode = 0, @poinbatch = '', @nonintfcflag = 'Y'

--Check pending purchase order table
if exists (select 1 from dbo.vPOPendingPurchaseOrder where POCo = @poco and PO = @po)
begin
	set @msg = 'Pending PO ' + @po + ' already exists.'
	return 1
end

---- get description for POHD
select @msg=Description, @jcco=JCCo, @job=Job
from dbo.POHD with (nolock) where POCo=@poco and PO=@po
if @@rowcount = 0
	begin
	select @msg = 'Purchase Order not on file'
	goto bspexit
	end

---- check for PMMF detail not yet interfaced
if not exists(select 1 from dbo.PMMF with (nolock) where PMCo=@pmco and POCo=@poco and PO=@po and InterfaceDate is null)
	begin
	select @nonintfcflag = 'N'
	end


if isnull(@jcco,0) <> @pmco or isnull(@job,'') <> @project
	begin
	select @msg='PO: ' + isnull(@po,'') + ' already exists for JCCo: ' + isnull(convert(varchar(3),@jcco),'') + ' and Job: ' + isnull(@job,'') + '!', @rcode = 1
	goto bspexit
	end

---- check to make sure it is not in a batch
select @poinbatch = 'Warning: PO: ' + isnull(@po,'') + ' is in use for Batch Month: ' + substring(convert(varchar(12),Mth,3),4,5) + ' Batch Id: ' + convert(varchar(10),BatchId)
from dbo.POHB with (nolock) where Co=@poco and PO=@po
if @@rowcount = 0 select @poinbatch = ''



bspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspPMPOUnique] TO [public]
GO
