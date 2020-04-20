SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************/
CREATE proc [dbo].[vspJCCommonInfoGetForJCCM]
/********************************************************
 * Created By:	GF 08/31/2009
 * Modified By:	
 *               
 *
 * USAGE:
 * Retrieves common info from JCCO for use in various
 * form's DDFH LoadProc field 
 *
 * INPUT PARAMETERS:
 *	JC Company
 *
 * OUTPUT PARAMETERS:
 * DefaultBillType
 * ARCo 
 * TaxGroup
 * CustomerGroup
 * ContractDefaultSecurityGroup,
 * ContractSecurityStatus bContract Data type security where 0 is off and 1 is on
 * GL Close Level
 *	
 * RETURN VALUE:
 * 	0 	    Success
 *	1 & message Failure
 *
 **********************************************************/
(@jcco bCompany = 0, @defaultbilltype bYN = null  output, @arco bCompany = null  output,
 @usetaxgroup bGroup = null output, @custgroup bGroup = null output, 
 @contractdefaultsecuritygroup int = null output, @contractsecuritystatus bYN = null output,
 @glcloselevel tinyint = null output, @pcmodule_active bYN = 'N' output,
 @errmsg varchar(255) = null output)
as 
set nocount on

declare @rcode int, @errortext varchar(255)

select @rcode = 0, @errmsg = null

---- valid JC company
select @defaultbilltype = DefaultBillType, @arco = ARCo, @glcloselevel = GLCloseLevel
from dbo.bJCCO with (nolock) where JCCo = @jcco
if @@rowcount = 0
	begin
	select @errmsg = 'JC Company ' + convert(varchar(3), @jcco) + ' is not setup!', @rcode = 1
	goto bspexit
	end

---- get tax group from HQCO for JC company.
select @usetaxgroup = TaxGroup
from dbo.bHQCO with (nolock) where HQCo = @jcco
if @@rowcount = 0
	begin
	select @errmsg = 'Error in retrieving group information from Head Quarters!', @rcode = 1
	goto bspexit
	end

---- get customer group from HQCO for JC AR company.
select @custgroup = CustGroup
from dbo.bHQCO with (nolock) where HQCo = @arco

---- get PC module active flag
select @pcmodule_active = Active
from dbo.vDDMO where Mod = 'PC'
if @@rowcount = 0 set @pcmodule_active = 'N'

---- get data type security information for the bJob data type.
exec @rcode = dbo.bspVADataTypeSecurityGet 'bContract', @DflSecurtiyGroup = @contractdefaultsecuritygroup output, @Secure = @contractsecuritystatus output, @msg = @errortext output
if @rcode <> 0
	begin
	select @errmsg = 'Error in retrieving bContract data type security!', @rcode = 1
	goto bspexit
	end




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCCommonInfoGetForJCCM] TO [public]
GO
