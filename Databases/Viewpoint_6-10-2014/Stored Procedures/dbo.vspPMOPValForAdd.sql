SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  proc [dbo].[vspPMOPValForAdd]
/*************************************
 * Created By:	GF 02/24/2011 TK-01924
 * Modified by:
 *
 * called from PMPCOAdd to return project PCO key description
 ( and PCO information
 *
 * Pass:
 * PMCo			PM Company
 * Project		PM Project
 * PCOType		PM PCO Type
 * PCO			PM PCO
 *
 * Returns:
 * BeginStatus			PMSC Beginning Status
 * BudgetType
 * SubType
 * POType
 * ContractType
 * Priority
 * IntExt				PM PCO IntExt flag
 *
 *
 * Success returns:
 *	0 and Description from PMOP
 *
 * Error returns:
 * 
 *	1 and error message
 **************************************/
(@pmco bCompany, @project bJob, @pcotype bDocType, @pco bPCO,
 @beginstatus bStatus = null output, @pcointext varchar(1) = 'E' output,
 @pcoexists bYN = 'N' output, @pcodesc bDesc = null output,
 @BudgetType bYN = 'N' OUTPUT, @SubType bYN = 'N' OUTPUT, @POType bYN = 'N' OUTPUT,
 @ContractType bYN = 'Y' OUTPUT, @Priority TINYINT = 3 OUTPUT,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @retcode int, @errmsg varchar(255)

select @rcode = 0, @msg = '', @retcode = 0, @pcoexists = 'N', @pcointext = 'I'

---- get description from PMOP
if isnull(@pco,'') <> ''
	begin
	select @msg = Description, @pcointext=IntExt, @pcodesc=Description,
			@BudgetType=BudgetType, @SubType=SubType, @POType=POType,
			@ContractType=ContractType, @Priority=Priority	
	from dbo.PMOP where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco
	if @@rowcount <> 0 select @pcoexists='Y'
	end

---- get beginning status from PMCo
exec @retcode = dbo.bspPMSCBegStatusGet @pmco, @beginstatus output, @errmsg output

---- internal/EXTERNAL flag is I WHEN CONTRACT TYPE equals N
IF @ContractType = 'N' SET @pcointext = 'I'



bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMOPValForAdd] TO [public]
GO
