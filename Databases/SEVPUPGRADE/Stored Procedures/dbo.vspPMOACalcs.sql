SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**********************************************************/
CREATE proc [dbo].[vspPMOACalcs]
/***********************************************************
* Created By:	GF 02/29/2008 - issue #127195 and #127210 for 6.1.0
* Modified By:	GF 12/20/2008 - issue #129669 distribute addons to phase/cost types
*				GF 08/31/2009 - issue #135339 change to calculate net total not basis add-ons in numeric add-on order.
*				GF 03/10/2010 - issue #138436 zero-out add-on amounts first before re-calcuating.
*			`	GF 08/03/2010 - issue #134354 use the round amount flag from PMPA to round to nearest whole dollar
*				GF 08/30/2010 - issue #141203 addon amount was being set to zero when phase total plus markup was zero in error.
*
*
*
* USAGE:
* updates PMOA
*
* INPUT PARAMETERS
*   PMCo
*   Project
*   PCOType
*   PCO
*   PCOItem
*
* OUTPUT PARAMETERS
*   none
*
* RETURN VALUE
*   returns 0 if successful, 1 if failure
*****************************************************/
(@pmco bCompany, @project bJob, @pcotype bDocType, @pco bPCO, @pcoitem bPCOItem)
as
set nocount on

declare @pendingamt bDollar, @curfixedamountyn bYN, @curunitprice bUnitCost,
		@curunits bUnits, @curum bUM, @curaco bACO, @amount bDollar, @pct numeric(12,6), 
		@oldamount bDollar, @rcode int, @cycle int, @pendingcostonly bDollar,
		@mpct numeric(12,6), @opencursor int, @contract bContract, @addon int,
		@item bContractItem, @retcode int, @errmsg varchar(255),
		@phasegroup bGroup, @phase bPhase, @costtype bJCCType


select @rcode = 0, @pendingamt = 0, @cycle = 0, @pendingcostonly = 0,
		@opencursor = 0, @retcode = 0

---- check if item is approved
if exists(select top 1 1 from bPMOI with (nolock) where PMCo=@pmco and Project=@project
		and PCOType=@pcotype and PCO=@pco and PCOItem=@pcoitem and isnull(ACOItem,'') <> '')
	begin
	goto bspexit
	end


---- get the pending Amount with markups and cost only
select @pendingamt = isnull(Round(IsNull(sum(a.EstCost),0)
----#134534
    	+ case when c.RoundAmount = 'Y' then round(isnull(sum(a.EstCost*b.IntMarkUp),0),0) else round(isnull(sum(a.EstCost*b.IntMarkUp),0),2) end
    	+ case when c.RoundAmount = 'Y' then round(isnull(sum((a.EstCost + IsNull((a.EstCost*b.IntMarkUp),0))*b.ConMarkUp),0),0) else round(isnull(sum((a.EstCost + IsNull((a.EstCost*b.IntMarkUp),0))*b.ConMarkUp),0),2) end, 2), 0),
----#134534   
		@pendingcostonly = isnull(sum(a.EstCost),0)
from dbo.bPMOL a with (nolock) 
left Join dbo.bPMOM b with (nolock) on a.PMCo=b.PMCo and a.Project=b.Project and a.PCOType=b.PCOType
and a.PCO=b.PCO and a.PCOItem=b.PCOItem and a.PhaseGroup=b.PhaseGroup and a.CostType=b.CostType
left join dbo.bPMPC c on c.PMCo=a.PMCo and c.Project=a.Project and c.PhaseGroup=a.PhaseGroup and c.CostType=a.CostType
where a.PMCo=@pmco and a.Project=@project and a.PCOType=@pcotype and a.PCO=@pco and a.PCOItem=@pcoitem
group by c.RoundAmount
if @pendingamt is null set @pendingamt = 0
if @pendingcostonly is null set @pendingcostonly = 0

---- create table variable with the PMOA records that we will be calculating
declare @pmoatable table
(
	KeyID			bigint not null,
	AddOn			int not null,
	Basis			char(1) not null,
	AddOnPercent	numeric(12,6) null,
	AddOnAmount		numeric(12,2) null,
	TotalType		char(1) not null,
	Include			char(1) not null,
	NetCalcLevel	char(1) not null,
	BasisCostType	tinyint null,
	NetCTAmt		numeric(12,2) null,
	NetMupCTAmt		numeric(12,2) null,
	PhaseGroup		int null,
	Phase			varchar(20) null,
	CostType		int null,
	 ----#134354
	RoundAmtFlag	char(1) not null,
	RoundAmount		numeric(12,2) null
)


---- insert PMOA rows into @pmoatable
insert @pmoatable(KeyID, AddOn, Basis, AddOnPercent, AddOnAmount, TotalType, Include,
		NetCalcLevel, BasisCostType, NetCTAmt, NetMupCTAmt, PhaseGroup, Phase, CostType,
		----#134354
		RoundAmtFlag, RoundAmount)
select a.KeyID, a.AddOn, isnull(a.Basis,'P'),
		----#138436
		CASE WHEN ISNULL(a.Basis,'P') IN ('P','C') then isnull(a.AddOnPercent,0) ELSE 0 end,
		CASE WHEN ISNULL(a.Basis,'P') = 'A' THEN isnull(a.AddOnAmount,0) ELSE 0 end,
		----#138436
		isnull(a.TotalType,'N'), isnull(a.Include,'N'), isnull(a.NetCalcLevel,'C'),
		a.BasisCostType, isnull(sum(isnull(b.EstCost,0)),0),
		isnull(Round(isnull(sum(isnull(b.EstCost,0)),0)
			+ isnull(sum(isnull(b.EstCost,0) * isnull(c.IntMarkUp,0)),0)
			+ isnull(sum((isnull(b.EstCost,0) + isnull((isnull(b.EstCost,0) * isnull(c.IntMarkUp,0)),0)) * isnull(c.ConMarkUp,0)),0),2),0),
		----#134354
		p.PhaseGroup, p.Phase, p.CostType, isnull(p.RoundAmount,'N'), 0
from dbo.bPMOA a with (nolock)
left join dbo.bPMPA p with (nolock) on p.PMCo=a.PMCo and p.Project=a.Project and p.AddOn=a.AddOn
left join dbo.bPMOL b with (nolock) on b.PMCo=a.PMCo and b.Project=a.Project and b.PCOType=a.PCOType
and b.PCO=a.PCO and b.PCOItem=a.PCOItem and b.CostType=a.BasisCostType
left join dbo.bPMOM c with (nolock) on c.PMCo=a.PMCo and c.Project=a.Project and c.PCOType=a.PCOType
and c.PCO=a.PCO and c.PCOItem=a.PCOItem and c.CostType=a.BasisCostType
where a.PMCo=@pmco and a.Project=@project
and a.PCOType=@pcotype and a.PCO=@pco and a.PCOItem=@pcoitem
group by a.AddOn, a.Basis, a.AddOnPercent, a.AddOnAmount, a.TotalType,
a.Include, a.NetCalcLevel, a.BasisCostType, a.KeyID, p.PhaseGroup, p.Phase, p.CostType, p.RoundAmount


---- calculate net add-ons with net calculation level = 'C' cost only and Basis is not 'C' cost type
select @amount = 0, @pct = 0
if exists(select * from @pmoatable where TotalType = 'N' and NetCalcLevel = 'C' and Basis <> 'C')
	begin
	update @pmoatable
			set @amount = case when a.Basis='P' then isnull(a.AddOnPercent,0) * @pendingcostonly else isnull(a.AddOnAmount,0) end,
    			@mpct = case when @pendingcostonly = 0 then isnull(a.AddOnPercent,0) else @amount/@pendingcostonly end,
				@mpct = case when @mpct > 99.9999 then 99.9999 when @mpct < -99.9999 then -99.9999 else @mpct end,
				@pct = @mpct, AddOnPercent = @pct, AddOnAmount = @amount
	from @pmoatable a where a.TotalType = 'N' and a.NetCalcLevel = 'C' and a.Basis <> 'C'
	end

---- calculate net add-ons with net calculation level = 'M' cost plus markup and basis is not 'C' cost type
select @amount = 0, @pct = 0
if exists(select * from @pmoatable where TotalType = 'N' and NetCalcLevel = 'M' and Basis <> 'C')
	begin
	update @pmoatable
    	set @amount = case when a.Basis='P' then isnull(a.AddOnPercent,0) * @pendingamt else isnull(a.AddOnAmount,0) end,
    		@mpct = case when @pendingamt = 0 then isnull(a.AddOnPercent,0) else @amount/@pendingamt end,
			@mpct = case when @mpct > 99.9999 then 99.9999 when @mpct < -99.9999 then -99.9999 else @mpct end,
			@pct = @mpct, AddOnPercent = @pct, AddOnAmount = @amount
	from @pmoatable a where a.TotalType = 'N' and a.NetCalcLevel = 'M' and a.Basis <> 'C'
	end


---- calculate net add-ons with a basis of cost type net amount or net amount plus markup
if exists(select * from @pmoatable where Basis = 'C' and BasisCostType is not NULL AND NetCalcLevel IN ('C','M'))
	begin
	---- calculate add-on amount using net calculation level 'C' cost only
	select @amount = 0, @pct = 0
	update @pmoatable
    	set @amount = isnull(a.AddOnPercent,0) * a.NetCTAmt,
    		@mpct = case when a.NetCTAmt = 0 then isnull(a.AddOnPercent,0) else @amount/a.NetCTAmt end,
			@mpct = case when @mpct > 99.9999 then 99.9999 when @mpct < -99.9999 then -99.9999 else @mpct end,
			@pct = @mpct, AddOnPercent = @pct, AddOnAmount = @amount
	from @pmoatable a where a.Basis = 'C' and a.NetCalcLevel = 'C' and a.BasisCostType is not null
	---- calculate add-on amount using net calculation level 'M' cost plus markup
	select @amount = 0, @pct = 0
	update @pmoatable
    	set @amount = isnull(a.AddOnPercent,0) * a.NetMupCTAmt,
    		@mpct = case when a.NetMupCTAmt = 0 then isnull(a.AddOnPercent,0) else @amount/a.NetMupCTAmt end,
			@mpct = case when @mpct > 99.9999 then 99.9999 when @mpct < -99.9999 then -99.9999 else @mpct end,
			@pct = @mpct, AddOnPercent = @pct, AddOnAmount = @amount
	from @pmoatable a where a.Basis = 'C' and a.NetCalcLevel = 'M' and a.BasisCostType is not null
	end

---- to calculate net totals where calculation level is 'T' and Basis <> 'C' we need to consider
---- the possiblity that the add-on numbers are in a different sequential order. We may have cost type
---- basis add-ons after a net total add-on and we do not want to include in the calculation.
---- if we have a variance then update last row in @pm_phase_addons #135339
----#138436
select @pendingamt = @pendingamt + isnull(sum(AddOnAmount),0)
from @pmoatable where TotalType = 'N' AND NetCalcLevel IN ('C','M')
if @pendingamt is null set @pendingamt = 0
----#138436

select @amount = 0, @pct = 0, @mpct = 0
if exists(select * from @pmoatable where TotalType = 'N' and NetCalcLevel = 'T' and Basis <> 'C')
	BEGIN
	;
	----#138436
	with NetTotal_Calculate(KeyID, AddOn, Basis, TotalType, NetCalcLevel, AddOnPercent, AddOnAmount) AS
	(
		select p.KeyID, p.AddOn,  p.Basis, p.TotalType, p.NetCalcLevel, p.AddOnPercent, p.AddOnAmount
		from @pmoatable p left join @pmoatable x on x.AddOn < p.AddOn
		where p.NetCalcLevel = 'T' and p.TotalType = 'N' and p.Basis <> 'C'
		group by p.AddOn, p.KeyID, p.TotalType, p.NetCalcLevel, p.Basis, p.AddOnPercent, p.AddOnAmount
	)
	----select * from NetTotal_Calculate;
	update @pmoatable
    	set @amount = ISNULL(case when ao.Basis='P' then isnull(ao.AddOnPercent,0) * ISNULL(@pendingamt,0) else isnull(ao.AddOnAmount,0) END,0),
    		@mpct = ISNULL(case when ISNULL(@pendingamt,0) = 0 then isnull(ao.AddOnPercent,0) else ISNULL(@amount,0)/@pendingamt END,0),
    		@pendingamt = @pendingamt + @amount,
			@mpct = ISNULL(case when @mpct > 99.9999 then 99.9999 when @mpct < -99.9999 then -99.9999 else @mpct END,0),
			@pct = ISNULL(@mpct,0), AddOnPercent = ISNULL(@pct,0), AddOnAmount = ISNULL(@amount,0)
	FROM @pmoatable b INNER JOIN (SELECT a.* FROM NetTotal_Calculate a GROUP BY a.AddOn, a.KeyID,
			a.TotalType, a.NetCalcLevel, a.Basis, a.AddOnPercent, a.AddOnAmount) ao
	ON b.AddOn=ao.AddOn
	----#138436
	--from NetTotal_Calculate a
	--INNER JOIN @pmoatable b ON b.KeyID=a.KeyID
	--where a.TotalType = 'N' and a.NetCalcLevel = 'T' and a.Basis <> 'C'
	;
	end

---- update pending amount with calculations just completed for Total Type = 'N'
----select @pendingamt = @pendingamt + isnull(sum(AddOnAmount),0)
----from @pmoatable where TotalType = 'N'
if @pendingamt is null set @pendingamt = 0

---- need to do something special if @pendingamt=0. Need to set to zero all AddOnAmounts for Basis='P'
---- and Basis = 'C' before continuing calculations.
---- If not, and PMOL records have been deleted the routine will not
---- calculate the correct values because we use the old amount to update difference
---- The Total Type may not be net and we do not want to zero out basis - 'A' amount
if @pendingamt = 0
   	begin
   	update @pmoatable set AddOnAmount = 0
   	----#141203
   	where TotalType <> 'N' and Basis <> 'A'
   	----#141203
   	end

----select convert(varchar(20),@pendingamt)

---- calculate subtotal add-ons and grand total add-ons when flagged to include
select @amount = 0, @pct = 0
update @pmoatable
    	set @amount = case when a.Basis='P' then isnull(a.AddOnPercent,0) * @pendingamt else isnull(a.AddOnAmount,0) end,
			@mpct = case when @pendingamt=0 then isnull(a.AddOnPercent,0) else @amount/@pendingamt end,
			@mpct = case when @mpct > 99.9999 then 99.9999 when @mpct < -99.9999 then -99.9999 else @mpct end,
    		@pendingamt = @pendingamt + @amount, @pct = @mpct, AddOnPercent = @pct, AddOnAmount = @amount
from @pmoatable a where a.Basis <> 'C' and (a.TotalType = 'S' or (a.TotalType = 'G' and a.Include = 'Y')) ----a.Include = 'Y' and 
if @pendingamt is null select @pendingamt = 0
----from bPMOA a with (nolock) where a.PMCo=@pmco and a.Project=@project and a.PCOType=@pcotype
----and a.PCO=@pco and a.PCOItem=@pcoitem and (a.TotalType = 'S' or (a.TotalType = 'G' and a.Include = 'Y'))
----select convert(varchar(20),@pendingamt)

---- cycle do loop to specify how many times the sub total addons are calculated - currently 3 times
select @amount=0, @pct=0, @cycle = 0
while @cycle < 3
    BEGIN
    	update @pmoatable
    	set @oldamount = isnull(a.AddOnAmount,0),
    		@amount = case when a.Basis='P' then isnull(a.AddOnPercent,0) * @pendingamt else isnull(a.AddOnAmount,0) end,
			@mpct = case when @pendingamt=0 then isnull(a.AddOnPercent,0) else @amount/@pendingamt end,
			@mpct = case when @mpct > 99.9999 then 99.9999 when @mpct < -99.9999 then -99.9999 else @mpct end,
			@pct = @mpct, @pendingamt = @pendingamt + @amount - @oldamount, AddOnPercent = @pct, AddOnAmount = @amount
    	from @pmoatable a where a.TotalType = 'S' and a.Basis <> 'C'    
   -- next cycle
   select @oldamount=0, @amount=0, @pct=0
   select @cycle = @cycle + 1
   END

----select convert(varchar(20),@pendingamt)

---- now back out the grand total amounts flagged to include in subtotals, so as
---- not to include when calculating final grand total add-on
select @pendingamt = @pendingamt - isnull(sum(a.AddOnAmount),0)
from @pmoatable a where a.TotalType = 'G' and a.Include = 'Y'
if @pendingamt is null select @pendingamt = 0

---- now calculate grand total add-ons
update @pmoatable
    	set @amount = case when a.Basis='P' then isnull(a.AddOnPercent,0) * @pendingamt else isnull(a.AddOnAmount,0) end,
			@mpct = case when @pendingamt=0 then isnull(a.AddOnPercent,0) else @amount/@pendingamt end,
			@mpct = case when @mpct > 99.9999 then 99.9999 when @mpct < -99.9999 then -99.9999 else @mpct end,
    		@pct = @mpct, @pendingamt = @pendingamt + @amount, AddOnPercent = @pct, AddOnAmount = @amount
from @pmoatable a where a.TotalType = 'G' and a.Basis <> 'C'
if @pendingamt is null select @pendingamt = 0


---- we now need to update the table and round the add-on amounts to nearest whole dollar
---- we alse need to update the pending amount value that will write to PMOI #134354
update @pmoatable set @amount = ROUND(ISNULL(a.AddOnAmount,0),0),
					  @pendingamt = @pendingamt - isnull(a.AddOnAmount,0) + isnull(@amount,0),
					  RoundAmount = @amount
from @pmoatable a where a.RoundAmtFlag = 'Y'
if @pendingamt is null set @pendingamt = 0

----select @pendingamt = @pendingamt + sum((a.AddOnAmount - isnull(RoundAmount,0)))
----from @pmoatable a where a.RoundAmtFlag = 'Y'

----select convert(varchar(20),@pendingamt)

---- need to get item information in order to update unit price if needed
select @curfixedamountyn=FixedAmountYN, @curunitprice=UnitPrice, @curunits=Units, @curum=UM
from bPMOI with (nolock) where PMCo=@pmco and Project=@project and PCOType=@pcotype
and PCO=@pco and PCOItem=@pcoitem
if @@rowcount <> 0
    begin
	if @curunitprice is null select @curunitprice=0
    -- set the Unit Price based on the following conditions
    if @curfixedamountyn='Y' select @curunitprice=IsNull(@curunitprice,0)

    if @curfixedamountyn<>'Y' and @curum='LS' select @curunitprice=0

    if @curfixedamountyn<>'Y' and IsNull(@curunits,0)=0 select @curunitprice=0

    -- calculate unit price
    If @curfixedamountyn<>'Y' and @curum<>'LS' and IsNull(@curunits,0) <> 0
		begin
		select @curunitprice = @pendingamt/@curunits
		end
    end

---- double check if item is approved
if exists(select top 1 1 from bPMOI with (nolock) where PMCo=@pmco and Project=@project
		and PCOType=@pcotype and PCO=@pco and PCOItem=@pcoitem and isnull(ACOItem,'') <> '')
	begin
	goto bspexit
	END


---- #134354
---- update PMOA with AddOnPercent or AddOnAmount - no rounding 
update bPMOA set AddOnPercent= case when a.Basis = 'A' 
							   then ISNULL(b.AddOnPercent,0) 
							   else ISNULL(a.AddOnPercent,0)
							   end,
				 AddOnAmount = case when a.Basis <> 'A' 
							   then ISNULL(b.AddOnAmount,0)
							   else ISNULL(a.AddOnAmount,0)
							   end,
				 AmtNotRound = 0
				 
from bPMOA a join @pmoatable b on b.KeyID=a.KeyID
where a.KeyID=b.KeyID and b.RoundAmtFlag = 'N'

---- update PMOA with AddOnPercent or AddOnAmount - with rounding 
update bPMOA set AddOnPercent= case when a.Basis = 'A' 
							   then ISNULL(b.AddOnPercent,0) 
							   else ISNULL(a.AddOnPercent,0)
							   end,
				 AddOnAmount = case when a.Basis <> 'A' 
							   then ROUND(ISNULL(b.AddOnAmount,0),0)
							   else ISNULL(a.AddOnAmount,0)
							   end,
				 AmtNotRound = case when a.Basis <> 'A'
				 			   then ISNULL(b.AddOnAmount,0)
							   else ISNULL(a.AddOnAmount,0)
							   end
				 
from bPMOA a join @pmoatable b on b.KeyID=a.KeyID
where a.KeyID=b.KeyID and b.RoundAmtFlag = 'Y'


----select convert(varchar(20),@pendingamt)

---- update PMOI with pending amount
update bPMOI set PendingAmount = @pendingamt, UnitPrice = IsNull(@curunitprice,0)
where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco and PCOItem=@pcoitem

---- if the item is approved we are done
if exists(select top 1 1 from bPMOI with (nolock) where PMCo=@pmco and Project=@project
		and PCOType=@pcotype and PCO=@pco and PCOItem=@pcoitem and isnull(ACOItem,'') <> '')
	begin
	goto bspexit
	end

----------------------------------------------
---- distribute cost basis addons #129669 ----
----------------------------------------------
---- first delete old distributions from table
delete from bPMOB
where PMCo=@pmco and Project=@project
and PCOType=@pcotype and PCO=@pco and PCOItem=@pcoitem
----from bPMOB b join bPMOI i on i.KeyID = b.PMOIKeyID

---- if we do not have any cost type assigned to the addons we are done
if not exists(select 1 from @pmoatable where CostType is not null) goto bspexit

---- get contract from job master
select @contract=Contract from dbo.bJCJM with (nolock) where JCCo=@pmco and Job=@project

---- create table variable with the PMOL phases that we will
---- calculate distributed cost based add-ons on
declare @pm_phase_addons table
(
	KeyID			bigint			not null,
	AddOn			int				not null,
	Basis			char(1)			not null,
	NetCalcLevel	char(1)			not null,
	PhaseGroup		tinyint			not null,
	Phase			varchar(20)		not null,
	DistCostType	tinyint			not null,
	Cost			numeric(12,2)	not null,
	NetCTAmt		numeric(12,2)	not null,
	NetMupCTAmt		numeric(12,2)	not null,
	AddonAmt		numeric(12,2)	not null,
	PendingAmt		numeric(12,2)	not null,
	AmtToDist		numeric(12,2)	not null,
	CostTypeCount	int				not null
)

---- insert phase cost types to distribute to from PMOL into @pm_phase_addons
---- first step just gets phase and cost types where basis cost type and cost type
---- with no phase
insert @pm_phase_addons(KeyID, AddOn, Basis, NetCalcLevel, PhaseGroup, Phase, DistCostType,
		Cost, NetCTAmt, NetMupCTAmt, AddonAmt, PendingAmt, AmtToDist, CostTypeCount)
select x.KeyID, x.AddOn, x.Basis, x.NetCalcLevel, x.PhaseGroup, l.Phase, x.CostType,
		isnull(l.EstCost,0), isnull(x.NetCTAmt,0), isnull(x.NetMupCTAmt,0),
		isnull(x.AddOnAmount,0), isnull(@pendingamt,0), 0, 0
from @pmoatable x
join bPMOA a on a.KeyID=x.KeyID
join bPMOL l with (nolock) on l.PMCo=a.PMCo and l.Project=a.Project and l.PCOType=a.PCOType
and l.PCO=a.PCO and l.PCOItem=a.PCOItem and x.BasisCostType=l.CostType
where x.Basis = 'C' and a.BasisCostType is not null and x.Phase is null and x.CostType is not null
group by x.KeyID, x.AddOn, x.Basis, x.NetCalcLevel, x.PhaseGroup, l.Phase, x.CostType,
l.EstCost, x.NetCTAmt, x.NetMupCTAmt, x.AddOnAmount

---- next insert any add-ons that have a phase and cost type assigned
insert @pm_phase_addons(KeyID, AddOn, Basis, NetCalcLevel, PhaseGroup, Phase, DistCostType,
		Cost, NetCTAmt, NetMupCTAmt, AddonAmt, PendingAmt, AmtToDist, CostTypeCount)
select x.KeyID, x.AddOn, x.Basis, x.NetCalcLevel, x.PhaseGroup, x.Phase, x.CostType,
		0, isnull(x.NetCTAmt,0), isnull(x.NetMupCTAmt,0),
		isnull(x.AddOnAmount,0), isnull(@pendingamt,0), isnull(x.AddOnAmount,0), 0
from @pmoatable x
where x.Phase is not null and x.CostType is not null
group by x.KeyID, x.AddOn, x.Basis, x.NetCalcLevel, x.PhaseGroup, x.Phase, x.CostType,
x.NetCTAmt, x.NetMupCTAmt, x.AddOnAmount

---- last insert any add-ons that are distributed to a cost type but the basis is not 'C' - Cost type
insert @pm_phase_addons(KeyID, AddOn, Basis, NetCalcLevel, PhaseGroup, Phase, DistCostType,
		Cost, NetCTAmt, NetMupCTAmt, AddonAmt, PendingAmt, AmtToDist, CostTypeCount)
select x.KeyID, x.AddOn, x.Basis, x.NetCalcLevel, x.PhaseGroup, l.Phase, x.CostType,
		isnull(l.EstCost,0), isnull(x.NetCTAmt,0), isnull(x.NetMupCTAmt,0),
		isnull(x.AddOnAmount,0), isnull(@pendingamt,0), 0, 0
from @pmoatable x
join bPMOA a on a.KeyID=x.KeyID
join bPMOL l with (nolock) on l.PMCo=a.PMCo and l.Project=a.Project and l.PCOType=a.PCOType
and l.PCO=a.PCO and l.PCOItem=a.PCOItem
where x.Basis in ('P','A') and x.Phase is null and x.CostType is not null
group by x.KeyID, x.AddOn, x.Basis, x.NetCalcLevel, x.PhaseGroup, l.Phase, x.CostType,
l.EstCost, x.NetCTAmt, x.NetMupCTAmt, x.AddOnAmount

---- update @pm_phase_addons and count the total cost type distributions for each cost type
---- percent
update a set CostTypeCount = (select count(*) from @pm_phase_addons x
			where x.Basis = 'P' and x.DistCostType=a.DistCostType)
from @pm_phase_addons a where a.Basis = 'P' and a.DistCostType is not null
---- amount
update a set CostTypeCount = (select count(*) from @pm_phase_addons x
			where x.Basis = 'A' and x.DistCostType=a.DistCostType)
from @pm_phase_addons a where a.Basis = 'A' and a.DistCostType is not null

---- now calculate cost type based distributed add-ons
---- for each phase in @pm_phase_addons table. When
---- we have a AmtToDist already then that row is 
---- set up to a phase and cost type so calculating
---- distribution is not needed
update @pm_phase_addons
	set AmtToDist = 
		case when p.Basis = 'C' and p.NetCalcLevel = 'C' and p.NetCTAmt <> 0 then
					((p.Cost/p.NetCTAmt) * p.AddonAmt)
			 when p.Basis = 'C' and p.NetCalcLevel = 'C' and p.NetMupCTAmt <> 0 then
					((p.Cost/p.NetMupCTAmt) * p.AddonAmt)
			 when p.Basis = 'P' and p.AmtToDist = 0 and p.PendingAmt <> 0 and p.CostTypeCount = 0 then
					((isnull(p.Cost,0)/isnull(p.PendingAmt,0)) * isnull(p.AddonAmt,0))
					+ ((((isnull(p.Cost,0)/isnull(p.PendingAmt,0)) * isnull(p.AddonAmt,0))
						/ isnull(p.PendingAmt,0)) * isnull(p.AddonAmt,0))
			 when p.Basis = 'P' and p.AmtToDist = 0 and p.PendingAmt <> 0 and p.CostTypeCount > 0 then
					(isnull(p.AddonAmt,0) / p.CostTypeCount)
			 when p.Basis = 'A' and p.AmtToDist = 0 and p.PendingAmt <> 0 and p.CostTypeCount = 0 then
			 		((isnull(p.Cost,0)/isnull(p.PendingAmt,0)) * isnull(p.AddonAmt,0))
					+ ((((isnull(p.Cost,0)/isnull(p.PendingAmt,0)) * isnull(p.AddonAmt,0))
						/ isnull(p.PendingAmt,0)) * isnull(p.AddonAmt,0))
			 when p.Basis = 'A' and p.AmtToDist = 0 and p.PendingAmt <> 0 and p.CostTypeCount > 0 then
					(isnull(p.AddonAmt,0) / p.CostTypeCount)
			 else 0
			 end

from @pm_phase_addons p
where p.AmtToDist = 0

---- if we have a variance then update last row in @pm_phase_addons
;
with Phase_Update(KeyID, Phase, AddOnAmount, AmtToDist) AS
(
	select top 1 p.KeyID, p.Phase, a.AddOnAmount, sum(x.AmtToDist)
	from @pm_phase_addons p
	join @pm_phase_addons x on x.KeyID=p.KeyID
	join @pmoatable a on a.KeyID=p.KeyID
	group by p.KeyID, p.Phase, a.AddOnAmount, p.AmtToDist
	order by p.KeyID, p.Phase desc
)
--	select * from Phase_Update;
	update @pm_phase_addons set AmtToDist = p.AmtToDist + (a.AddOnAmount-a.AmtToDist)
	from Phase_Update a
	join @pm_phase_addons p on p.KeyID=a.KeyID and p.Phase=a.Phase
	where p.AmtToDist <> a.AddOnAmount
;

---- remove rows with no amount to distribute
delete from @pm_phase_addons where isnull(AmtToDist,0) = 0



---- create cursor on @pm_phase_addons for phases and cost types that
---- do not exist in JCJP or JCCH, then try to add
declare bcAddonPhases cursor LOCAL FAST_FORWARD
		for select a.AddOn, a.PhaseGroup, a.Phase, a.DistCostType
from @pm_phase_addons a
where not exists(select 1 from bJCJP p with (nolock) where p.JCCo=@pmco
		and p.Job=@project and p.PhaseGroup=a.PhaseGroup and p.Phase=a.Phase)
or not exists(select 1 from bJCCH c with (nolock) where c.JCCo=@pmco
		and c.Job=@project and c.PhaseGroup=a.PhaseGroup and c.Phase=a.Phase
		and c.CostType=a.DistCostType)

---- open cursor
open bcAddonPhases
set @opencursor = 1

---- loop through @pm_phase_addons
AddonPhases_loop:
fetch next from bcAddonPhases into @addon, @phasegroup, @phase, @costtype
if (@@fetch_status <> 0) goto AddonPhases_end

---- check if phase exists in job phases and try to add
if not exists(select 1 from bJCJP p with (nolock) where p.JCCo=@pmco
		and p.Job=@project and p.PhaseGroup=@phasegroup and p.Phase=@phase)
	begin
	set @item = null
	---- get add-on contract item if exists
	select @item=Item
	from bPMPA with (nolock)
	where PMCo=@pmco and Project=@project and AddOn=@addon
	---- use PCO item contract item
	if isnull(@item,'') = ''
		begin
		select @item=ContractItem from bPMOI with (nolock)
		where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco and PCOItem=@pcoitem
		end
	---- use first contract item in JCCI
	if isnull(@item,'') = ''
		begin
		select @item = min(Item)
		from bJCCI with (nolock) where JCCo=@pmco and Contract=@contract
		end
	---- validate standard phase - if it does not exist in JCJP try to add it
	exec @retcode = dbo.bspJCADDPHASE @pmco, @project, @phasegroup, @phase, 'Y', @item, @errmsg output
	end

---- check if cost type exists in cost header and try to add
if not exists(select 1 from bJCCH c with (nolock) where c.JCCo=@pmco
		and c.Job=@project and c.PhaseGroup=@phasegroup and c.Phase=@phase
		and c.CostType=@costtype)
	begin
	---- validate Cost Type - if JCCH doesnt exist try to add it
	exec @retcode = dbo.bspJCADDCOSTTYPE @jcco=@pmco, @job=@project, @phasegroup=@phasegroup, 
			@phase=@phase, @costtype=@costtype, @um='LS',@override = 'P', @msg=@errmsg output
	end

goto AddonPhases_loop
   
AddonPhases_end:
---- close and deallocate cursor
if @opencursor = 1
	begin
	close bcAddonPhases
	deallocate bcAddonPhases
	set @opencursor = 0
	end



---- insert new records
insert bPMOB (PMCo, Project, PCOType, PCO, PCOItem, PhaseGroup, Phase,
			CostType, AmtToDistribute, PMOIKeyID, AddOn)
select distinct i.PMCo, i.Project, i.PCOType, i.PCO, i.PCOItem, r.PhaseGroup, r.Phase,
			r.DistCostType, sum(r.AmtToDist), i.KeyID, min(r.AddOn)
from @pm_phase_addons r
join bPMOA a with (nolock) on a.KeyID=r.KeyID
join bPMOI i with (nolock) on i.PMCo=a.PMCo and i.Project=a.Project and i.PCOType=a.PCOType
and i.PCO=a.PCO and i.PCOItem=a.PCOItem
group by i.PMCo, i.Project, i.PCOType, i.PCO, i.PCOItem, i.KeyID, r.PhaseGroup, r.Phase, r.DistCostType

--select * from @pmoatable
--select * from @pm_phase_addons



bspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPMOACalcs] TO [public]
GO
