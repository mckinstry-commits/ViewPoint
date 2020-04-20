SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMImportUploadContVal    Script Date: 06/06/2006 ******/
CREATE proc [dbo].[vspPMImportUploadContVal]
/*************************************
 * Created By:	GF 06/06/2006 - for 6.x
 * Modified By:	
 *
 *
 *
 * validates PM Import Upload Contract.
 * Returns contract info when exists.
 *
 * Pass:
 * PM Company
 * PM Project
 * PM Contract
 *
 * Output:
 * Exists Flag
 * Contract Warning Flag
 * Contract Description
 * Department
 * Customer
 * Retainage Pct
 * Start Month
 * Tax Code
 *
 * Success returns:
 *	0 and JCCM Description
 *
 * Error returns:
 *	1 and error message
 **************************************/
(@pmco bCompany = null, @project bJob = null, @contract bContract = null,
 @exists bYN = 'Y' output, @contwarnflag bYN = 'N' output, @cont_desc bItemDesc = null output,
 @dept bDept = null output, @customer bCustomer = null output, @retainpct bPct = 0 output,
 @startmth bMonth = null output, @taxcode bTaxCode = null output, @msg varchar(255) output)
as 
set nocount on

declare @rcode int, @contractstatus tinyint, @jobstatus tinyint

select @rcode = 0, @contwarnflag = 'N', @exists = 'Y'

if @pmco is null
   	begin
   	select @msg = 'Missing PM Company.', @rcode = 1
   	goto bspexit
   	end

if @contract is null
	begin
	select @msg = 'Missing Contract.', @rcode = 1
	goto bspexit
	end

if @project is null
	begin
	select @msg = 'Missing Project.', @rcode=1
   	goto bspexit
	end


------ validate JCCM Contract
select @msg=Description, @contractstatus=ContractStatus
from JCCM with (nolock) where JCCo=@pmco and Contract=@contract
if @@rowcount = 0 
   	begin
   	select @msg = 'New Contract', @exists = 'N'
	goto bspexit
   	end

------ get Job Status if exists
select @jobstatus = JobStatus
from JCJM with (nolock) where JCCo=@pmco and Job=@project
if @@rowcount <> 0
	begin
	------ contract status must match job status
	if @contractstatus <> @jobstatus
		begin
		select @msg = 'Contract status must be the same as job status.', @rcode = 1
		goto bspexit
		end
	end

------ get contract info
select @cont_desc=Description, @dept=Department, @customer=Customer, @retainpct=RetainagePCT,
		@startmth=StartMonth, @taxcode=TaxCode
from JCCM with (nolock) where JCCo=@pmco and Contract=@contract 
if @@rowcount = 0
   	begin
   	select @msg = 'Error has occurred get job/contract information.' , @rcode = 1
   	goto bspexit
   	end

------ check if contract items exists in JCCI for contract
if exists(select * from JCCI with (nolock) where JCCo=@pmco and Contract=@contract)
	select @contwarnflag = 'Y'





bspexit:
	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMImportUploadContVal] TO [public]
GO
