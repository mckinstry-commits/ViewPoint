SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************/
CREATE proc [dbo].[vspPMCommonInfoGetForIntfc]
/********************************************************
 * Created By:	GF 03/21/2007
 * Modified By:	GP 04/01/2009 - Issue 127486, return security group status.
 *               
 *
 * USAGE:
 * Retrieves common info from PMCO and other sources for use in
 * PM Interface form, PM Import Upload DDFH LoadProc
 *
 * INPUT PARAMETERS:
 *	PM Company
 *
 * OUTPUT PARAMETERS:
 * From PMCO:
 * APCO, INCO, MSCO, APInuse, SLInUse,
 * POInUse, INInUse, MSInUse
 * LicLevel from DDMO
 *
 * From JCCO: GLCo, ARCo
 *
 * From HQCO: TaxGroup, CustGroup
 *	
 * RETURN VALUE:
 * 	0 	    Success
 *	1 & message Failure
 *
 **********************************************************/
(@pmco bCompany=0, @apco bCompany =null output, @inco bCompany output, @msco bCompany output,
 @glco bCompany = null output, @apinuse bYN = 'N' output, @slinuse bYN = 'N' output,
 @poinuse bYN = 'N' output, @ininuse bYN = 'N' output, @msinuse bYN = 'N' output,
 @usetaxgroup bGroup = null output, @custgroup bGroup = null output, @arco bCompany = null output,
 @liclevel tinyint = 2 output, @viewname varchar(10) = null output, @ProjectSecurityStatus bYN = 'N' output, 
 @ContractSecurityStatus bYN = 'N' output, @AttachBatchReportsYN bYN = 'N' output, @errmsg varchar(255) output)
as 
set nocount on

declare @rcode int, @errortext varchar(255)

select @rcode = 0, @liclevel = 2

---- missing MS company
if @pmco is null
	begin
   	select @errmsg = 'Missing PM Company!', @rcode = 1
   	goto bspexit
   	end

---- get PM license level
select @liclevel = LicLevel from vDDMO where Mod='PM'
if @@rowcount = 0 select @liclevel = 2

------ Get info from PMCO
select @apco=APCo, @inco=INCo, @msco=MSCo, @apinuse=APInUse, @slinuse=SLInUse,
		@poinuse=POInUse, @ininuse=INInUse, @msinuse=MSInUse, @viewname=DocTrackView,
		@AttachBatchReportsYN=AttachBatchReportsYN
from PMCO with (nolock) where PMCo=@pmco
if @@rowcount <> 1
	begin
	select @errmsg = 'PM Company ' + convert(varchar(3), @pmco) + ' is not setup!', @rcode = 1
	goto bspexit
	end

------ get ARCo, GLCo from JCCo
select @glco=GLCo, @arco=ARCo
from JCCO with (nolock) where JCCo=@pmco

------ get tax, customer groups from HQCO for PM company
select @usetaxgroup=TaxGroup, @custgroup=CustGroup
from HQCO with (nolock) where HQCo = @pmco

---- get data type security information for the bJob data type, 127486.
exec @rcode = dbo.bspVADataTypeSecurityGet 'bJob', null, 
	@ProjectSecurityStatus output, @errmsg output

---- get data type security information for the bContract data type, 127486.
exec @rcode = dbo.bspVADataTypeSecurityGet 'bContract', null, 
	@ContractSecurityStatus output, @errmsg output



bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMCommonInfoGetForIntfc] TO [public]
GO
