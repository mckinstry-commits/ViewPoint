SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspJCCMDesc    Script Date: 05/17/2005 ******/
CREATE      proc [dbo].[vspJCCMDesc]
/*************************************
* Created By:	GF	05/17/2005
* Modified By:	DANF 06/15/2005
*				CHS	05/04/2008	- issue #121933
*				GF	03/16/2009	- issue #132564 output param for contract amount
*				GF	11/18/2009	- issue #136647 - change to query that checks JCCD for performance.
*				CHS	11/24/2009	- issue #136673 added out put for gl close level
*				TJL 12/01/09 - Issue #129894, added output for JCCM.MaxRetgOpt for Max Retainage Enhancement
*				GF 03/29/2010 - issue #138858 added recompile to update query plan. and use base table for check
*
* USAGE:
* Called from JCCM and PMContract to get key description for contract. If new contract,
* checks the Job Cost History table to see if the Contract number has been used.
*
*
* INPUT PARAMETERS
* @jcco			JC Company
* @contract		JC Contract
* @validatestatus	validate contract status for jc where 'Y' dose not allow pending contract to be entered.
*
* Success returns:
* JBTemplate		JBCo.JBTemplate
* contractitemexist
* jcdetailexists
* original contract amount
* department
* retainage
* start minth
* si region
* bill type
* si metric
* tax code
* 0 and Description from JCCM
*
* Error returns:
* 1 and error message
**************************************/
(@jcco bCompany, @contract bContract, @validatestatus bYN, @jbtemplate varchar(10) output, 
@contractitemexist bYN output, @jcdetailexists bYN output,  @origamount bDollar output,
@department bDept = null output, @retg bPct output, @startmonth bMonth = null output, 
@siregion varchar(6) output, @defaultbilltype char(1) output, @simetric bYN output, 
@taxcode bTaxCode output, @currentdays smallint = 0 output, @postsoftclosedjobs bYN output, 
@curramount bDollar = 0 output, @glcloselevel tinyint output, @maxretgopt char(1) output, 
@msg varchar(255) output)

with recompile  ---- #138858

as
set nocount on

declare @rcode int, @contractstatus tinyint, @validcnt int, @jccd_check int

select @rcode = 0, @msg = '', @contractitemexist ='Y', @jcdetailexists = 'N'
set @currentdays = 0
set @validcnt = 0

if isnull(@contract,'') = ''
	begin
   	select @msg = 'Contract cannot be null.', @rcode = 1
   	goto bspexit
	end

---- get JBCO.JBTemplate
select @jbtemplate=JBTemplate from dbo.bJBCO with (nolock) where JBCo=@jcco

---- get Soft Closed Status Flag - issue #121933 - issue #136673
select @postsoftclosedjobs = PostSoftClosedJobs, @glcloselevel = GLCloseLevel from dbo.bJCCO with (nolock) where JCCo = @jcco

---- get contract description, if contract exists done no check of history needed
select 	@msg=Description, @contractstatus = ContractStatus, @origamount=OrigContractAmt,
		@department = Department, @retg = RetainagePCT, @startmonth = StartMonth, 
 		@siregion = SIRegion, @defaultbilltype = DefaultBillType, @simetric = SIMetric,
		---- #132564
 		@taxcode= TaxCode, @currentdays=CurrentDays, @curramount=ContractAmt, @maxretgopt = MaxRetgOpt
from dbo.JCCM with (nolock) 
where JCCo=@jcco and Contract=@contract

-----
--select @msg = 'here' + @maxretgopt, @rcode = 1
--goto bspexit
-----

if @@rowcount = 1 
	begin
		if isnull(@validatestatus,'N') = 'Y' and isnull(@contractstatus,98) = 0
			begin
				select @msg = 'Contract is pending, access not allowed.', @rcode = 1
				goto bspexit
			end

		  ------ see if cost detail exists
		  ----if exists (select top 1 1 from JCJP with (nolock)
  		----			join JCCD with (nolock) 
				----	on JCJP.JCCo=JCCD.JCCo and JCJP.Job=JCCD.Job and JCJP.PhaseGroup = JCCD.PhaseGroup and JCJP.Phase = JCCD.Phase
		  ----			where JCJP.JCCo=@jcco and JCJP.Contract = @contract and JCCD.JCTransType not in ('OE','PE','PF','CV'))
		  ----begin 
		  ----	select @jcdetailexists='Y'
		  ----end
	  
		----Tech rewrite  CPU 0  READS 7 DURATION 0 #136647
		----#138858
		set @jccd_check = 0
		select top 1 @jccd_check = 1
		from dbo.bJCJP with (nolock) join dbo.bJCCD with (nolock) on bJCJP.JCCo=bJCCD.JCCo and bJCJP.Job=bJCCD.Job
		and bJCJP.PhaseGroup = bJCCD.PhaseGroup and bJCJP.Phase = bJCCD.Phase
		where bJCJP.JCCo=@jcco and bJCJP.Contract = @contract and bJCCD.JCTransType not in ('OE','PE','PF','CV')	
		if @jccd_check = 1 set @jcdetailexists = 'Y'
  
		  -- See if revenue exists
		  if exists (select top 1 1 from bJCID with (nolock)
					where bJCID.JCCo=@jcco and bJCID.Contract = @contract and bJCID.JCTransType <> 'OC')
		  	begin
		  	select @jcdetailexists='Y'
		  	end

			if not exists (Select top 1 1 from dbo.bJCCI with (nolock) 
						   where JCCo = @jcco  and Contract = @contract)
				set @contractitemexist = 'N'
			else
				set @contractitemexist = 'Y'
		----#138858

	goto bspexit
	end

-- -- --DC Issue 18385
if exists(select 1 from dbo.bJCHC with (nolock) where JCCo=@jcco and Contract=@contract)
	begin
  	select @msg = 'Contract ' + isnull(@contract,'') + ' was previously used.' + char(13) + char(10) + 
				'Cannot be used until the contract is purged from Contract/Job' + char(13) + char(10) +
				'History- use JC Contract Purge form to purge contract.', @rcode = 1
  	goto bspexit
	end





bspexit:
	return @rcode



GO
GRANT EXECUTE ON  [dbo].[vspJCCMDesc] TO [public]
GO
