SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     Proc [dbo].[vspJCCopyGroupGet]
  
  /***************************************************************
  *	Created: TV 05/24/01
  *			TV - 23061 added isnulls
  *	purpose:
  *	To return Phase Group and tax group to the JCJobCopy
  *
  *	Input:
  *	JCCo, Job
  *
  *	Outputs:
  * New Company
  * Liab Template
  * Payroll State
  *	Tax Group
  *	Phase Group
  *	Customer Group
  * Department
  * Customer
  * Tax Code
  * Retg
  *	msg
  *
  ***************************************************************/
  (@jcco bCompany = 0, @job bJob = null,@newjcco bCompany output,
  @liabtemplate smallint output, @prstate varchar(4) output,
  @taxgroup bGroup output, @phasegroup bGroup output, @custgroup bGroup output,
  @department bDept output, @customer bCustomer output, @taxcode bTaxCode output, @retg bPct output,
  @msg varchar(255) output)
  as
  set nocount on
  
  declare @rcode int, @contract bContract
  
  select @rcode = 0
  
  if @jcco is null
      begin
   	select @msg = 'Missing JC Company!', @rcode = 1
   	goto bspexit
   	end
  
  
  if @job is null
   	begin
   	select @msg = 'Missing job!', @rcode = 1
   	goto bspexit
   	end
  
  select @msg = Description, @liabtemplate = LiabTemplate, @prstate = PRStateCode, @contract = Contract, @taxcode = TaxCode
  from dbo.bJCJM where JCCo=@jcco and Job=@job
  if @@rowcount = 0
      begin
      select @msg = 'Job not on file!', @rcode = 1
      goto bspexit
      end

   select @custgroup=h.CustGroup
  from dbo.bHQCO h with (nolock) JOIN bJCCO j with (nolock) ON (h.HQCo = j.ARCo)
  where j.JCCo = @jcco
  if @@rowcount <> 1
      begin
      select @msg='Invalid HQ Company ' + convert(varchar(3),@jcco) + '!', @rcode=1
      goto bspexit
      end
 
  
  select @taxgroup=TaxGroup, @phasegroup = PhaseGroup
  from dbo.bHQCO where HQCo=@jcco
  if @@rowcount <> 1
      begin
      select @msg='Invalid HQ Company ' + isnull(convert(varchar(3),@jcco),'') + '!', @rcode=1
      goto bspexit
      end
  

  select  @department = Department, @customer = Customer, @retg = RetainagePCT
  from dbo.bJCCM where JCCo=@jcco and Contract=@contract


  select @newjcco = @jcco
  
  bspexit:
      if @rcode<>0 select @msg=@msg
      return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCCopyGroupGet] TO [public]
GO
