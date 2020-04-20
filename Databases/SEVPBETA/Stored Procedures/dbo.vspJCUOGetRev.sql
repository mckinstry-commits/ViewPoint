SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[vspJCUOGetRev]
/***********************************************************
* CREATED BY:	DANF	08/14/2005
* MODIFIED BY:	CHS		04/11/2008 - issue # 124378
*
*
* USAGE:
*  Returns the user options for revenue projections
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
   (@jcco bCompany, 
	@form varchar(30), 
	@username bVPUserName, 
	@RevProjFilterBegItem bContractItem output, --
	@RevProjFilterEndItem bContractItem output, --
	@RevProjFilterBillType varchar(1) output, --
	@RevProjFilterBegDept bDept output, --
	@RevProjFilterEndDept bDept output,
    @msg varchar(255) output)
   as
   set nocount on

   declare @rcode integer, @jcco_projmethod char(1)
   
   select @rcode = 0
   
   -- validate JCCo
   select @jcco_projmethod=ProjMethod
   from dbo.bJCCO with (nolock) where JCCo=@jcco
   if @@rowcount = 0
   	begin
   	select @msg = 'Invalid JC Company.', @rcode = 1
   	goto bspexit
   	end
   
   -- validate form
   if not exists(select Form from dbo.DDFI with (nolock) where Form=@form)
   	begin
   	select @msg = 'Invalid JC Form.', @rcode = 1
   	goto bspexit
   	end

select 
	@RevProjFilterBegItem = RevProjFilterBegItem, 
	@RevProjFilterEndItem = RevProjFilterEndItem, 
	@RevProjFilterBillType = RevProjFilterBillType,
	@RevProjFilterBegDept = RevProjFilterBegDept, 
	@RevProjFilterEndDept = RevProjFilterEndDept
from bJCUO with (nolock)
where JCCo= @jcco and Form= @form and UserName= @username
if @@rowcount = 0
   	begin
   	select @msg = 'Unable to retrieve default user options from JCUO.', @rcode = 1
   	goto bspexit
   	end
   

   bspexit:
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCUOGetRev] TO [public]
GO
