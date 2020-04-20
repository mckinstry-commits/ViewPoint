SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCCMValForPM    Script Date: 05/20/2005 ******/
CREATE proc [dbo].[vspJCCMValForPM]
/***********************************************************
 * Creadted By: GF 05/20/2005
 * Modified By:	GF 03/16/2009 - issue #132564 output param for contract amount
 *				TJL 12/01/09 - Issue #129894, added output for JCCM.MaxRetgOpt for Max Retainage Enhancement
 *
 *
 *
 * USAGE:
 * validates JC contract for PM Projects and PM Contract Items
 * an error is returned if any of the following occurs
 * no contract passed, no contract found in JCCM.
 *
 * INPUT PARAMETERS
 * JCCo			JC Co to validate against
 * Contract		Contract to validate
 * FromForm		
 * Project		PM Project
 *
 * OUTPUT PARAMETERS
 * @status      	Contract Status
 * @department  	Contract Department
 * @customer    	Contract Customer
 * @retg			Contract Retainage Pct
 * @startmonth  	Contract Start Month
 * @exists			Contract exists (auto-add contract)
 * @siregion		Contract SIRegion
 * @defaultbilltype	Contract Default Bill Type
 * @simetric		Contract SI metric use flag
 * @taxcode			Contract Tax Code
 * @origamount		Contract Original Amount
 * @msg			error message if error occurs otherwise Description of Contract
 *
 * RETURN VALUE
 *   0         success
 *   1         Failure
 *****************************************************/
(@jcco bCompany = 0, @contract bContract = null, @from varchar(1) = 'P', @project bJob = null,
 @status tinyint output, @department bDept = null output, @customer bCustomer = null output,
 @retg bPct output, @startmonth bMonth = null output, @exists bYN = 'N' output, 
 @siregion varchar(6) output, @defaultbilltype char(1) output, @simetric bYN output, 
 @taxcode bTaxCode output, @origamount bDollar output, @jbtemplate varchar(10) = null output,
 @custgroup bGroup = null output, @curramount bDollar = 0 output, @maxretgopt char(1) output,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @jobstatus tinyint

select @rcode = 0, @status=0, @retg = 0, @msg = '', @exists = 'N'

if @jcco is null
  	begin
  	select @msg = 'Missing JC Company!', @rcode = 1
  	goto bspexit
  	end

if @contract is null
  	begin
  	select @msg = 'Missing Contract!', @rcode = 1
  	goto bspexit
  	end



if @from = 'I'
	begin
	-- -- -- get contract info
	select @msg=Description, @status=ContractStatus, @department=Department,
			@startmonth=StartMonth, @customer=Customer, @retg=isnull(RetainagePCT,0),
			@taxcode=TaxCode, @defaultbilltype=DefaultBillType, @siregion=SIRegion,
			@simetric=SIMetric, @origamount=OrigContractAmt, @jbtemplate=JBTemplate,
			---- #132564
			@custgroup=CustGroup, @curramount=ContractAmt, @maxretgopt = MaxRetgOpt
	from JCCM with (nolock) where JCCo = @jcco and Contract = @contract
	if @@rowcount = 0
		begin
	  	select @msg = 'Contract not on file!', @rcode = 1
	  	goto bspexit
	  	end
	-- -- -- done for items
	set @exists = 'Y'
	goto bspexit
	end

-- -- -- Check Contract history to see if this contract number has been used -- DC 18385
exec @rcode = dbo.bspJCJMJobVal @jcco, @contract, 'C', @msg output
if @rcode = 1 goto bspexit

-- -- -- get contract info
select @msg=Description, @status=ContractStatus, @department=Department,
		@startmonth=StartMonth, @customer=Customer, @retg=isnull(RetainagePCT,0),
		@taxcode=TaxCode, @defaultbilltype=DefaultBillType, @siregion=SIRegion,
		@simetric=SIMetric, @origamount=OrigContractAmt, @jbtemplate=JBTemplate,
		@custgroup=CustGroup
from JCCM with (nolock) where JCCo = @jcco and Contract = @contract
if @@rowcount = 0
	begin
	if @from <> 'P'
		begin
  		select @msg = 'Contract not on file!', @rcode = 1
  		goto bspexit
  		end
	else
		begin
		select @exists = 'N', @rcode = 0
		goto bspexit
		end
	end

select @exists = 'Y'

-- -- -- if from project (P) and exists in JCJM compare status
if @from = 'P' and isnull(@project,'') <> ''
	begin
	select @jobstatus=JobStatus
	from JCJM where JCCo=@jcco and Job=@project
	if @@rowcount = 0 goto bspexit
	if @jobstatus <> @status
		begin
		select @msg = 'Job Status must be same as Contract Status', @rcode = 1
		goto bspexit
		end
	end




bspexit:
	if @rcode<>0 select @msg = isnull(@msg,'')
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspJCCMValForPM] TO [public]
GO
