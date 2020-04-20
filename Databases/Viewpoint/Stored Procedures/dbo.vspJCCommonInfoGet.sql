SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************/
CREATE proc [dbo].[vspJCCommonInfoGet]
/********************************************************
 * Created By:	Dan 05/08/2005
 * Modified By:	GF 12/12/2007 - issue #25569 return JCCO.PostSoftClosedJobs as output parameter.
 *				GF 02/08/2008 - issue #124680 removed ProjUnit, ProjHour, ProjCost, ProjUnitcost not used.
 *				TRL 02/20/08 - issue 21452
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
 * ValidPhaseChars, 
 * PostClosedJobs, 
 * UseJobBilling,
 * DefaultBillType,
 * ARCo, 
 * INCo,
 * GLCo,
 * PRCo, 
 * GLCostOveride,
 * GLRevOveride,
 * ValidateMaterial,
 * UseTaxOnMaterial,
 * PostCrewProgress, 
 * ProjMethod,
 * ProjMinPct,
 * ProjPercent,
 * ProjOverUnder,
 * ProjRemain, 
 * AddJCSICode,
 * Phasegroup,
 * UseTaxGroup,
 * CustGroup,
 * JobDefaultSecurityGroup,
 * JobSecurityStatus bJob Data type security where 0 is off and 1 is on 
 * ContractDefaultSecurityGroup,
 * ContractSecurityStatus bContract Data type security where 0 is off and 1 is on 
 * JB Template
 * GL Close Level
 * Projection Active Phases
 * Misc Material Account
 * Material Group
 *	
 * RETURN VALUE:
 * 	0 	    Success
 *	1 & message Failure
 *
 **********************************************************/
(@jcco bCompany=0, @validphasechars tinyint = null  output, @postclosedjobs bYN = null  output, 
 @usejobbilling bYN = null  output, @defaultbilltype bYN = null  output, @arco bCompany = null  output,
 @inco bCompany = null  output, @glco bCompany = null  output, @prco bCompany = null  output,
 @glcostoveride bYN = null  output, @glrevoveride bYN = null output, @validatematerial bYN = null  output,
 @usetaxonmaterial bYN = null  output, @postcrewprogress bYN = null  output,
 @projmethod char(1) = null output, @projminpct  bPct = null output, @projpercent bYN = null output, 
 @projoverunder bYN = null output, @projremain bYN = null output, @projunit bYN = null output,
 @projhour bYN = null output, @projcost bYN = null output, @projunitcost bYN = null output,
 @addjcsicode bYN = null output, @phasegroup bGroup = null output, @usetaxgroup bGroup = null output,
 @custgroup bGroup = null output, @jobdefaultsecuritygroup int = null output,
 @jobsecuritystatus bYN = null output, @contractdefaultsecuritygroup int = null output,
 @contractsecuritystatus bYN = null output, @jbtemplate varchar(10) = null output,
 @glcloselevel tinyint = null output, @projinactivephases bYN = null output, 
 @glmiscmatacct bGLAcct = null output, @materialgroup bGroup = null output,
 @postsoftclosedjobs bYN = null output,@attachbatchreports bYN output, @errmsg varchar(255) = null output)
as 
set nocount on

declare @rcode int, @errortext varchar(255)

select @rcode = 0, @errmsg = null, @projhour = 'N', @projcost = 'N', @projunitcost = 'N'

select
	@validphasechars = ValidPhaseChars, 
	@postclosedjobs = PostClosedJobs, 
	@usejobbilling = UseJobBilling,
	@defaultbilltype = DefaultBillType,
	@arco = ARCo, 
	@inco = INCo,
	@glco = GLCo,
	@prco = PRCo, 
	@glcostoveride = GLCostOveride,
	@glrevoveride = GLRevOveride,
	@validatematerial = ValidateMaterial,
	@usetaxonmaterial = UseTaxOnMaterial,
	@postcrewprogress = PostCrewProgress, 
	@projmethod = ProjMethod,
	@projminpct = ProjMinPct,
	@projpercent = ProjPercent,
	@projoverunder = ProjOverUnder,
	@projremain = ProjRemain, 
	@addjcsicode = AddJCSICode,
	@glcloselevel = GLCloseLevel,
	@projinactivephases = ProjInactivePhases,
	@glmiscmatacct = GLMiscMatAcct,
	@postsoftclosedjobs = PostSoftClosedJobs,
	@attachbatchreports = IsNull(AttachBatchReportsYN,'N')
from dbo.bJCCO with (nolock) where JCCo = @jcco
if @@rowcount <> 1
           begin
           select @errmsg = 'JC Company ' + convert(varchar(3), @jcco) + ' is not setup!', @rcode = 1
           goto bspexit
           end

-- get phase group from HQCO for JC company.
select @phasegroup = PhaseGroup, @usetaxgroup = TaxGroup, @materialgroup = MatlGroup
from dbo.bHQCO with (nolock) where HQCo = @jcco
   if @@rowcount <> 1
           begin
           select @errmsg = 'Error in retrieving group information from Head Quarters!', @rcode = 1
           goto bspexit
           end

-- get customer group from HQCO for JC AR company.
select @custgroup = CustGroup
from dbo.bHQCO with (nolock) where HQCo = @arco

-- get customer group from HQCO for JC AR company.
select @jbtemplate=JBTemplate
from dbo.bJBCO with (nolock) where JBCo = @jcco

-- get data type security information for the bJob data type.
exec @rcode = dbo.bspVADataTypeSecurityGet 'bJob', @DflSecurtiyGroup = @jobdefaultsecuritygroup output, @Secure = @jobsecuritystatus output, @msg = @errortext output
   if @rcode <> 0
           begin
           select @errmsg = 'Error in retrieving bJob data type security!', @rcode = 1
           goto bspexit
           end

-- get data type security information for the bJob data type.
exec @rcode = dbo.bspVADataTypeSecurityGet 'bContract', @DflSecurtiyGroup = @contractdefaultsecuritygroup output, @Secure = @contractsecuritystatus output, @msg = @errortext output
   if @rcode <> 0
           begin
           select @errmsg = 'Error in retrieving bContract data type security!', @rcode = 1
           goto bspexit
           end




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCCommonInfoGet] TO [public]
GO
