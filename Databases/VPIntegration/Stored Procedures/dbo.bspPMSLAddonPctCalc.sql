SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMSLAddonPctCalc    Script Date: 8/28/99 9:35:18 AM ******/
CREATE   proc [dbo].[bspPMSLAddonPctCalc]
/*************************************
* CREATED BY    : LM 2/17/99
* LAST MODIFIED : GF 06/28/2010 - issue #135813 SL expanded to 30 characters
*
*
* Calc SL Addon Pct amount for SL Items not entered through initialize proc
*
* Pass:
*       PMCO
*       Project
*       SLCo
*       SL
*	     Addon
*
*
* Success returns:
*	0 on Success, 1 on ERROR
*
* Error returns:
*	1 and error message
**************************************/
(@pmco bCompany, @project bJob, @slco bCompany, @sl VARCHAR(30), @addon tinyint, @addonpct bPct,
  @addonamt bDollar output, @msg varchar(60) output)
as
set nocount on

declare @rcode tinyint, @pmaddonamt bDollar, @sladdonamt bDollar, @addontype char(1)

select @rcode = 0
if @pmco is null or @project is null
   begin
    select @msg = 'Missing information!', @rcode = 1
    goto bspexit
   end

select @addontype=Type from dbo.bSLAD with (nolock) where SLCo=@slco and Addon=@addon
if @addontype='A' 
	begin
	select @addonamt=Amount from dbo.bSLAD with (nolock) where SLCo=@slco and Addon=@addon
	goto bspexit
	end
   select @pmaddonamt=(sum(isnull(Amount,0)) * @addonpct)
      from dbo.PMSL with (nolock) 
      where PMCo=@pmco and Project=@project and SLCo=@slco and SL=@sl
      and SLItemType in (1,2) and InterfaceDate is null
   select @sladdonamt=(sum(isnull(OrigCost,0)) * @addonpct)
      from dbo.SLIT with (nolock) 
      where JCCo=@pmco and Job=@project and SLCo=@slco and SL=@sl
      and ItemType in (1,2)
   select @addonamt = isnull(@pmaddonamt,0) + isnull(@sladdonamt,0)
   
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMSLAddonPctCalc] TO [public]
GO
