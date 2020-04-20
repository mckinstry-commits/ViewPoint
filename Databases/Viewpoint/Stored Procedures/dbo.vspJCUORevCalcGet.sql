SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[vspJCUORevCalcGet]
/***********************************************************
* CREATED BY	: DANF
* MODIFIED BY	: CHS 04/11/2008 - issue # 124378
*
* USAGE:
*  retreiving the projection calculation initialize options from bJCUO
*
*
* INPUT PARAMETERS
*	JCCo		JC Company
*	Form		JC Form Name
*	UserName	VP UserName
*
* OUTPUT PARAMETERS
*	WriteOver	Write Over Plug option
*	InitOption	Initialize option
*	
*   @msg

* RETURN VALUE
*   0         success
*   1         Failure  'if Fails THEN it fails.
*****************************************************/
   (@jcco bCompany, 
		@form varchar(30), 
		@username bVPUserName, 
		@revprojcalcwriteoverplug char(1) output, 
		@revprojcalcmethod char(1) output, 
		@revprojcalcmethodmarkup bPct output, 
		@revprojcalcbilltype char(1) output, 
		@revprojbegcontract bContract output,
		@revprojendcontract bContract output, 
		@revprojcalcbegitem bContractItem output, 
		@revprojcalcenditem bContractItem output,
		@revprojfilterbegitem bContractItem output,
		@revprojfilterenditem bContractItem output,
		@revprojfilterbilltype char(1) output,
		@revprojfilterbegdept bDept output,
		@revprojfilterenddept bDept output,
		@revprojcalcbegdept bDept output, 
		@revprojcalcenddept bDept output,
		@msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode integer
   
   select @rcode = 0
   
	select	@revprojcalcwriteoverplug = RevProjCalcWriteOverPlug, 
			@revprojcalcmethod = RevProjCalcMethod, 
			@revprojcalcmethodmarkup = isnull(RevProjCalcMethodMarkup,0), 
			@revprojcalcbilltype = RevProjCalcBillType, 
			@revprojbegcontract = RevProjCalcBegContract,
			@revprojendcontract = RevProjCalcEndContract, 
			@revprojcalcbegitem = RevProjCalcBegItem, 
			@revprojcalcenditem = RevProjCalcEndItem,
			@revprojfilterbegitem = RevProjFilterBegItem,
			@revprojfilterenditem = RevProjFilterEndItem,
			@revprojfilterbilltype = RevProjFilterBillType,
			@revprojfilterbegdept = RevProjFilterBegDept,
			@revprojfilterenddept = RevProjFilterEndDept,
			@revprojcalcbegdept = RevProjCalcBegDept, 
			@revprojcalcenddept = RevProjCalcEndDept

	from bJCUO with (nolock)
	where JCCo= @jcco and Form = @form and UserName= @username 

	if @@rowcount <> 1 select @rcode = 1, @msg = 'Missing User Options'


   bspexit:
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCUORevCalcGet] TO [public]
GO
