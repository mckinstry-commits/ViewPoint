SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMPADesc    Script Date: 04/29/2005 ******/
CREATE   proc [dbo].[vspPMPADesc]
/*************************************
 * Created By:	GF 04/29/2005
 * Modified by:	GF 12/20/2006 - 6.x issue #123360
 *				GF 02/13/2008 - changed output for percent from bPct to numeric(12,8)
 *				GF 02/27/2008 - issue #127210 basis cost type output parameter
 *				GF 05/05/2008 - issue #22100 revenue addon output parameters
 *				GF 08/03/2010 - issue #134354 standard and round amount parameters
 *
 *
 *
 * called from PMProjectAddons to return project add-on key description.
 * Also returns PMCA values to use as defaults when adding add-on to project.
 *
 *
 * Pass:
 * PMCo			PM Company
 * Project		PM Project
 * Addon		PM Project Add-on
 *
 * Returns:
 * Description
 * Basis
 * Percent
 * Amount
 * Phase
 * CostType
 * Contractitem
 * TotalType
 * Include
 * BasisCostType
 * RevRedirect
 * RevItem
 * RevUseItem
 * RevStartAtItem
 * RevFixedACOItem
 * Standard
 * RoundAmount
 *
 *
 * Success returns:
 *	0 and Description from PMPA
 *
 * Error returns:
 * 
 *	1 and error message
 **************************************/
(@pmco bCompany, @project bJob, @addon tinyint = 0, 
 @description bDesc output, @basis varchar(1) output, @pct numeric(12,8) output,
 @amount bDollar output, @phase bPhase output, @costtype bJCCType output,
 @item bContractItem output, @totaltype varchar(1) output, @include bYN output,
 @netcalclevel varchar(1) output, @basiscosttype bJCCType output, @revredirect bYN = 'N' output,
 @revitem bContractItem = null output, @revuseitem char(1) = 'U' output, 
 @revstartatitem int = null output, @revfixedacoitem bACOItem = null output,
 ----#134354
 @Standard char(1) = 'N' output, @RoundAmount char(1) = 'N' output,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = ''

if @addon <> 0
	begin
	-- -- -- get project add-on description
	select @msg = Description
	from dbo.PMPA where PMCo=@pmco and Project=@project and AddOn=@addon
	-- -- -- get company add-on values
	select @description=Description, @basis=isnull(Basis,'P'), @pct=isnull(Pct,0), @amount=isnull(Amount,0),
			@phase=Phase, @costtype=CostType, @item=Item, @totaltype=isnull(TotalType,'N'),
			@include = isnull(Include,'N'), @netcalclevel = isnull(NetCalcLevel,'T'),
			@basiscosttype=BasisCostType, @revredirect = RevRedirect, @revitem=RevItem,
			@revuseitem=RevUseItem, @revstartatitem=RevStartAtItem, @revfixedacoitem=RevFixedACOItem,
			@Standard=Standard, @RoundAmount=RoundAmount
	from dbo.PMCA where PMCo=@pmco and Addon=@addon
	end




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMPADesc] TO [public]
GO
