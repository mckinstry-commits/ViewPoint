SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMSLAddonValAndCalc ******/
CREATE  proc [dbo].[vspPMSLAddonValAndCalc]
/*************************************
 * Created By:	GF 03/31/2006 for 6.x
 * Modified By: GF 07/31/2006 - issue #28854 use CO item amount when filter type is 'P' or 'A'
 *				GF 06/28/2010 - issue #135813 SL expanded to 30 characters
 *
 *
 *
 * Called from PM subcontract detail and PM SL Items forms to validate SL addon and return
 * a Calculated SL Addon Pct amount for SL Items not entered through initialize proc.
 *
 *
 * Pass:
 * PMCO
 * Project
 * SLCo
 * SL
 * Addon
 * RecType		PMSL Type of record (O,P,A)
 * PCOType
 * PCO
 * PCOItem
 * ACO
 * ACOItem
 *
 *
 * Success returns:
 *	0 on Success, 1 on ERROR
 *
 * Error returns:
 *	1 and error message
 **************************************/
(@pmco bCompany, @project bJob, @slco bCompany, @sl VARCHAR(30), @addon tinyint,
 @rectype varchar(1) = 'O', @pcotype bDocType = null, @pco bPCO = null,
 @pcoitem bPCOItem = null, @aco bACO = null, @acoitem bACOItem = null,
 @addontype char(1) output, @addonpct bPct output, @addonamt bDollar output,
 @phase bPhase output, @costtype bJCCType output, @subct_amount bDollar output,
 @coitemamt bDollar = 0 output, @desc bItemDesc output, @msg varchar(255) output)
as
set nocount on

declare @rcode tinyint, @pmaddonamt bDollar, @sladdonamt bDollar

select @rcode = 0, @addontype = '', @addonpct = 0, @addonamt = 0, @subct_amount = 0, @coitemamt = 0

if @pmco is null or @project is null
	begin
	select @msg = 'Missing PM information!', @rcode = 1
	goto bspexit
	end

if @rectype='C' select @rectype='A'

-- -- -- validate addon in SLAD
select @msg=isnull(Description,''), @addontype = Type, @addonpct=Pct,
		@addonamt=Amount, @phase=Phase, @costtype=JCCType, @desc=Description
from SLAD with (nolock)
where SLCo=@slco and Addon=@addon
if @@rowcount = 0
	begin
	select @msg = 'Invalid SL Add-on!', @rcode = 1
	goto bspexit
	end

-- -- -- get subcontract amount from PMSL
-- -- -- calculate the addon amount to return
select @subct_amount = isnull(sum(Amount),0), @pmaddonamt = (isnull(sum(Amount),0) * isnull(@addonpct,0))
from PMSL with (nolock)
where PMCo=@pmco and Project=@project and SLCo=@slco and SL=@sl
and SLItemType in (1,2) and InterfaceDate is null

-- -- -- add in subcontract amount from SLIT
-- -- -- calculate the addon amount to return
select @subct_amount = @subct_amount + isnull(sum(OrigCost),0), @sladdonamt=(isnull(sum(OrigCost),0) * isnull(@addonpct,0))
from SLIT with (nolock)
where JCCo=@pmco and Job=@project and SLCo=@slco and SL=@sl and ItemType in (1,2)
if @subct_amount is null select @subct_amount = 0

------ when addon type = 'A' for amount all done
if @addontype = 'A' goto bspexit

------ add both together and return total
if @rectype = 'O'
	begin
	select @addonamt = isnull(@pmaddonamt,0) + isnull(@sladdonamt,0)
	goto bspexit
	end

------ now lets get the change order amount
if @rectype = 'A'
	begin
	select @coitemamt = isnull(ApprovedAmt,0)
	from PMOI with (nolock) where PMCo=@pmco and Project=@project and ACO=@aco and ACOItem=@acoitem
	end
if @rectype = 'P'
	begin
	select @coitemamt = isnull((case FixedAmountYN when 'Y' then FixedAmount else PendingAmount end), 0) 
	from PMOI with (nolock) where PMCo=@pmco and Project=@project and PCOType=@pcotype
	and PCO=@pco and PCOItem=@pcoitem
	end

------ calculate co add on amount
select @addonamt = isnull(@coitemamt,0) * isnull(@addonpct,0)







	
bspexit:
	if @rcode <> 0 select @msg=isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMSLAddonValAndCalc] TO [public]
GO
