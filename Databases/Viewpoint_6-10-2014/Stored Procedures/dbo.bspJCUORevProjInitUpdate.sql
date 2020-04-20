SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**********************************************/
CREATE   proc [dbo].[bspJCUORevProjInitUpdate]
/***********************************************************
* CREATED BY	: DANF 03/04/2005
* MODIFIED BY	: CHS	04/09/2008 - issue # 123378
*
* USAGE:
*  Updates the revenue projection initialize options in bJCUO
*
*
* INPUT PARAMETERS
*	JCCo		JC Company
*	Form		JC Form Name
*	UserName	VP UserName
*
* OUTPUT PARAMETERS
*   @msg

* RETURN VALUE
*   0         success
*   1         Failure  'if Fails THEN it fails.
*****************************************************/
(@jcco bCompany, @form varchar(30), @username bVPUserName, @RevProjFilterBegItem bContractItem, 
	@RevProjFilterEndItem bContractItem, @RevProjFilterBillType char(1), 
	@RevProjCalcWriteOverPlug char(1), @RevProjCalcMethod char(1), 
	@RevProjCalcMethodMarkup bPct, @RevProjCalcBillType char(1), 
	@RevProjCalcBegContract bContract, @RevProjCalcEndContract bContract, 
	@RevProjCalcBegItem bContractItem, @RevProjCalcEndItem bContractItem, 
	@RevProjFilterBegDept bDept = null, @RevProjFilterEndDept bDept = null, 
	@RevProjCalcBegDept bDept = null, @RevProjCalcEndDept bDept = null,
	@msg varchar(255) output)

as
set nocount on

declare @rcode integer

select @rcode = 0

-- insert projection user options record
update dbo.bJCUO 
		Set RevProjFilterBegItem = @RevProjFilterBegItem,
		RevProjFilterEndItem = @RevProjFilterEndItem,
		RevProjFilterBillType = @RevProjFilterBillType,
		RevProjCalcWriteOverPlug = @RevProjCalcWriteOverPlug,
		RevProjCalcMethod = @RevProjCalcMethod,
		RevProjCalcMethodMarkup = @RevProjCalcMethodMarkup,
		RevProjCalcBillType = @RevProjCalcBillType,
		RevProjCalcBegContract = @RevProjCalcBegContract,
		RevProjCalcEndContract = @RevProjCalcEndContract, 
		RevProjCalcBegItem = @RevProjCalcBegItem,
		RevProjCalcEndItem = @RevProjCalcEndItem,

		RevProjFilterBegDept = @RevProjFilterBegDept,
		RevProjFilterEndDept = @RevProjFilterEndDept, 
		RevProjCalcBegDept = @RevProjCalcBegDept, 
		RevProjCalcEndDept = @RevProjCalcEndDept

where JCCo=@jcco and Form=@form and UserName=@username



bspexit:
	if @rcode <> 0 select @msg=@msg
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCUORevProjInitUpdate] TO [public]
GO
