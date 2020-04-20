SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*********************************************/
CREATE proc [dbo].[bspJCProjRefreshCosts]
/****************************************************************************
* Created By:	GF  02/20/2004
* Modified By:	TV - 23061 added isnulls
*				DANF 01/10/2007 Updateed for 6.x
*				GF 09/30/2008 - issue #126236 added DisplayedCO and CalculatedCO to JCPB
*				GF 12/22/2008 - issue #129669 include future addon costs
*				GF 07/26/2009 - issue #134971 added displayed co's to populate
*				GF 10/15/2010 - issue #141731 added future actual cost to populate
*				TRL 04/01/2011 - TK-03650 added column ouput for Uncommitted Costs
*				TRL 08/09/2011 - TK-07850  modified uncommitted costs formula from TK-03650 at end of formula
*
* USAGE:
*  Refreshs original, current, actual units hours anc costs for an existing
*  Month, BatchId, JCCo and Job in the projections table (bJCPB)
*
* INPUT PARAMETERS:
*	User Name, Company, Job, Phase Group, Mth, BatchId
*
* OUTPUT PARAMETERS:
*  0=success, 1=error
*
*****************************************************************************/
(@username bVPUserName, @co bCompany, @job bJob, @phasegroup tinyint, @mth bMonth,
 @batchid bBatchID, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @opencursor int, @phase bPhase, @costtype bJCCType,
		@actualhours bHrs, @actualunits bUnits, @actualcosts bDollar, @curresthours bHrs,
		@currestunits bUnits, @currestcosts bDollar, @totalcmtdunits bUnits,
		@totalcmtdcosts bDollar, @remaincmtdunits bUnits, @remaincmtdcosts bDollar,
		@origesthours bHrs, @origestunits bUnits, @origestcosts bDollar,
		@actualcmtdunits bUnits, @actualcmtdcosts bDollar,
		@cincludeco bDollar, @cfuturecohours bHrs, @cfuturecounits bUnits,
		@cfuturecocosts bDollar, @pmolcount int, @cincludecounits bUnits,
		@cincludecohours bHrs, @cdisplaycounits bUnits, @cdisplaycohours bHrs,
		@cdisplayco bDollar, @FutureActualCost bDollar, ----#141731
		--TK-03650
		@cuncmtdcosts bDollar,@PCOuncommittedcosts bDollar,@BuyOutYN bYN
		
select @rcode = 0, @opencursor = 0, @pmolcount = 0

---- create cursor on bJCPT for refresh
declare bcJCPB cursor LOCAL FAST_FORWARD for select Phase, CostType
from bJCPB 
where Mth=@mth and BatchId=@batchid and Co=@co and Job=@job

---- open bcJCPT cursor
open bcJCPB
select @opencursor = 1

---- process through all entries in cursor
bcJCPB_loop:
fetch next from bcJCPB into @phase, @costtype

if @@fetch_status = -1 goto bcJCPB_end
if @@fetch_status <> 0 goto bcJCPB_loop

-- reset values
select @actualhours=0, @actualunits=0, @actualcosts=0, @origesthours=0, @origestunits=0,
		@origestcosts=0, @curresthours=0, @currestunits=0, @currestcosts=0, 
		@totalcmtdunits=0, @totalcmtdcosts=0, @remaincmtdunits=0, @remaincmtdcosts=0, 
		@actualcmtdunits=0, @actualcmtdcosts=0, @cincludeco = 0,
		@cfuturecohours = 0, @cfuturecounits = 0, @cfuturecocosts = 0,
		@cincludecounits = 0, @cincludecohours = 0, @cdisplaycounits = 0,
		@cdisplaycohours = 0, @cdisplayco = 0,
		--TK-03650
		@cuncmtdcosts=0,@PCOuncommittedcosts=0

---- get new values from JCCP
select @actualhours=isnull(sum(ActualHours),0), @actualunits=isnull(sum(ActualUnits),0),
		@actualcosts=isnull(sum(ActualCost),0), @origesthours=isnull(sum(OrigEstHours),0),
		@origestunits=isnull(sum(OrigEstUnits),0), @origestcosts=isnull(sum(OrigEstCost),0),
		@curresthours=isnull(sum(CurrEstHours),0), @currestunits=isnull(sum(CurrEstUnits),0),
		@currestcosts=isnull(sum(CurrEstCost),0), @totalcmtdunits=isnull(sum(TotalCmtdUnits),0),
		@totalcmtdcosts=isnull(sum(TotalCmtdCost),0), @remaincmtdunits=isnull(sum(RemainCmtdUnits),0),
		@remaincmtdcosts=isnull(sum(RemainCmtdCost),0)
from bJCCP with (nolock) where JCCo=@co and Job=@job and PhaseGroup=@phasegroup
and Phase=@phase and CostType=@costtype and Mth<=@mth

---- set actual+committed
select @actualcmtdunits = @actualunits + @remaincmtdunits, @actualcmtdcosts = @actualcosts + @remaincmtdcosts

---- #141731 get future detail cost from JCCP where Month > @mth
SET @FutureActualCost = 0
SELECT @FutureActualCost = ISNULL(SUM(ActualCost),0)
FROM dbo.bJCCP WITH (NOLOCK) where JCCo=@co and Job=@job
and PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtype
and Mth>@mth

select @BuyOutYN = IsNull(h.BuyOutYN,'N')
from bJCCH h with (nolock)
join bJCJP p with (nolock) on p.JCCo=h.JCCo and p.Job=h.Job and p.PhaseGroup=h.PhaseGroup and p.Phase=h.Phase
join bJCCT c with (nolock) on c.PhaseGroup=h.PhaseGroup and c.CostType=h.CostType
where h.JCCo=@co and h.Job=@job and h.PhaseGroup=@phasegroup and h.Phase=@phase and h.CostType=@costtype

--TK-03650
--get Subcontract Detail not assigned to a PCO
select @PCOuncommittedcosts=isnull(sum(l.Amount),0) 
from dbo.PMSL l
inner join bJCCH h with (nolock) on h.JCCo=l.PMCo and h.Job=l.Project and h.PhaseGroup=l.PhaseGroup
and h.Phase=l.Phase and h.CostType=l.CostType
where l.PMCo=@co and l.Project=@job and l.PhaseGroup=@phasegroup and l.Phase=@phase
and l.CostType=@costtype and l.InterfaceDate is null
and l.PCOType is null and l.PCO is null and l.PCOItem is null

--get Material detail not assigned to a PCO
select @PCOuncommittedcosts = @PCOuncommittedcosts + isnull(sum(l.Amount),0) from dbo.PMMF l
inner join bJCCH h with (nolock) on h.JCCo=l.PMCo and h.Job=l.Project and h.PhaseGroup=l.PhaseGroup
and h.Phase=l.Phase and h.CostType=l.CostType
where l.PMCo=@co and l.Project=@job and l.PhaseGroup=@phasegroup and l.Phase=@phase
and l.CostType=@costtype and l.InterfaceDate is null
and l.PCOType is null and l.PCO is null and l.PCOItem is null

---- get future change order values
---- only when future change order costs are requested
---- per issue #127212 always get PM future change orders
select @pmolcount=Count(*)
from bPMOL WITH (NOLOCK) where PMCo=@co and Project=@job and PhaseGroup=@phasegroup and Phase=@phase
and CostType=@costtype and InterfacedDate is null
if @pmolcount > 0
	begin
	select @cfuturecohours=isnull(sum(l.EstHours),0),
			@cfuturecounits=isnull(sum(l.EstUnits),0),
			@cfuturecocosts=isnull(sum(l.EstCost),0)
	from bPMOL as l with (nolock)
	join bPMOI i with (nolock) on i.PMCo=l.PMCo and i.Project=l.Project and isnull(i.PCOType,'')=isnull(l.PCOType,'')
	and isnull(i.PCO,'')=isnull(l.PCO,'') and isnull(i.PCOItem,'')=isnull(l.PCOItem,'')
	and isnull(i.ACO,'')=isnull(l.ACO,'') and isnull(i.ACOItem,'')=isnull(l.ACOItem,'')
	join bPMSC s with (nolock) on s.Status=i.Status
	left join bPMDT t with (nolock) on t.DocType=i.PCOType
	where l.PMCo=@co and l.Project=@job and l.PhaseGroup=@phasegroup and l.Phase=@phase
	and l.CostType=@costtype and l.InterfacedDate is null
	and isnull(s.IncludeInProj,'N') in ('Y','C') and isnull(t.IncludeInProj,'Y')='Y'
	
	/*TK-03650 Include all items that haven't been interfaced and/or assigned a SubCO and POCONum
	Form code in PM Pending Change Orders should prevent a SUBCO or POCONum from having a value
	if or when the SL or PO is cleared from the detail record.*/
	select @PCOuncommittedcosts= @PCOuncommittedcosts + isnull(sum(l.PurchaseAmt),0)
	from bPMOL as l with (nolock)
	join bPMOI i with (nolock) on i.PMCo=l.PMCo and i.Project=l.Project and isnull(i.PCOType,'')=isnull(l.PCOType,'')
	and isnull(i.PCO,'')=isnull(l.PCO,'') and isnull(i.PCOItem,'')=isnull(l.PCOItem,'')
	and isnull(i.ACO,'')=isnull(l.ACO,'') and isnull(i.ACOItem,'')=isnull(l.ACOItem,'')
	join bPMSC s with (nolock) on s.Status=i.Status
	left join bPMDT t with (nolock) on t.DocType=i.PCOType
	where l.PMCo=@co and l.Project=@job and l.PhaseGroup=@phasegroup and l.Phase=@phase
	and l.CostType=@costtype and l.InterfacedDate is null and l.SubCO is null and l.POCONum is null
	and isnull(s.IncludeInProj,'N') in ('Y','C') and isnull(t.IncludeInProj,'Y')='Y'
	

	---- get future change order calculated value
	select @cincludecounits=isnull(sum(l.EstUnits),0),
			@cincludecohours=isnull(sum(l.EstHours),0),
			@cincludeco=isnull(sum(l.EstCost),0)
	from bPMOL as l with (nolock)
	join bPMOI i with (nolock) on i.PMCo=l.PMCo and i.Project=l.Project and isnull(i.PCOType,'')=isnull(l.PCOType,'')
	and isnull(i.PCO,'')=isnull(l.PCO,'') and isnull(i.PCOItem,'')=isnull(l.PCOItem,'')
	and isnull(i.ACO,'')=isnull(l.ACO,'') and isnull(i.ACOItem,'')=isnull(l.ACOItem,'')
	join bPMSC s with (nolock) on s.Status=i.Status
	left join bPMDT t with (nolock) on t.DocType=i.PCOType
	where l.PMCo=@co and l.Project=@job and l.PhaseGroup=@phasegroup and l.Phase=@phase
	and l.CostType=@costtype and l.InterfacedDate is null
	and isnull(s.IncludeInProj,'N') = 'C' and isnull(t.IncludeInProj,'Y')='Y'
	
	---- get future change order displayed value
	select @cdisplaycounits=isnull(sum(l.EstUnits),0),
			@cdisplaycohours=isnull(sum(l.EstHours),0),
			@cdisplayco=isnull(sum(l.EstCost),0)
	from bPMOL as l with (nolock)
	join bPMOI i with (nolock) on i.PMCo=l.PMCo and i.Project=l.Project and isnull(i.PCOType,'')=isnull(l.PCOType,'')
	and isnull(i.PCO,'')=isnull(l.PCO,'') and isnull(i.PCOItem,'')=isnull(l.PCOItem,'')
	and isnull(i.ACO,'')=isnull(l.ACO,'') and isnull(i.ACOItem,'')=isnull(l.ACOItem,'')
	join bPMSC s with (nolock) on s.Status=i.Status
	left join bPMDT t with (nolock) on t.DocType=i.PCOType
	where l.PMCo=@co and l.Project=@job and l.PhaseGroup=@phasegroup and l.Phase=@phase
	and l.CostType=@costtype and l.InterfacedDate is null
	and isnull(s.IncludeInProj,'N') = 'Y' and isnull(t.IncludeInProj,'Y')='Y'
	end

---- get any future change order add-on costs. these will
---- come from bPMOB for a PMCo and Project - #129669
if exists(select top 1 1 from bPMOB with (nolock) where PMCo=@co and Project=@job)
	begin
	---- get future change order cost for display
	select @cfuturecocosts = @cfuturecocosts + isnull(sum(f.AmtToDistribute),0)
	from bPMOB as f with (nolock)
	join bPMOI i with (nolock) on i.PMCo=f.PMCo and i.Project=f.Project and i.PCOType=f.PCOType
	and i.PCO=f.PCO and i.PCOItem=f.PCOItem
	join bPMSC s with (nolock) on s.Status=i.Status
	left join bPMDT t with (nolock) on t.DocType=i.PCOType
	where f.PMCo=@co and f.Project=@job and f.PhaseGroup=@phasegroup and f.Phase=@phase
	and i.ACOItem is null and f.CostType=@costtype
	and isnull(s.IncludeInProj,'N') in ('Y','C') and isnull(t.IncludeInProj,'Y')='Y'

	---- get future change order cost to include
	select @cincludeco = @cincludeco + isnull(sum(f.AmtToDistribute),0)
		from bPMOB as f with (nolock)
	join bPMOI i with (nolock) on i.PMCo=f.PMCo and i.Project=f.Project and i.PCOType=f.PCOType
	and i.PCO=f.PCO and i.PCOItem=f.PCOItem
	join bPMSC s with (nolock) on s.Status=i.Status
	left join bPMDT t with (nolock) on t.DocType=i.PCOType
	where f.PMCo=@co and f.Project=@job and f.PhaseGroup=@phasegroup and f.Phase=@phase
	and i.ACOItem is null and f.CostType=@costtype
	and isnull(s.IncludeInProj,'N') = 'C' and isnull(t.IncludeInProj,'Y')='Y'
	end

--TK-03650
If @BuyOutYN = 'N'
	begin
			If  @totalcmtdcosts = 0
				begin
						select @cuncmtdcosts = @PCOuncommittedcosts
				end
			else
				begin
					If  @currestcosts > @totalcmtdcosts
						begin
							select @cuncmtdcosts =  (@currestcosts - @totalcmtdcosts) + @PCOuncommittedcosts
						end
					else
						begin
							select @cuncmtdcosts =  @PCOuncommittedcosts
						end
				end
      end

--Uncommittedcosts cannot be less than zero		
If @cuncmtdcosts < 0
begin
	select @cuncmtdcosts = 0
end
	
	
---- update JCPB row
update JCPB set ActualHours = @actualhours, ActualUnits = @actualunits, ActualCost = @actualcosts,
		CurrEstHours = @curresthours, CurrEstUnits = @currestunits, CurrEstCost = @currestcosts,
		RemainCmtdUnits = @remaincmtdunits, RemainCmtdCost = @remaincmtdcosts, 
		TotalCmtdUnits = @totalcmtdunits, TotalCmtdCost = @totalcmtdcosts, OrigEstHours = @origesthours,
		OrigEstUnits = @origestunits, OrigEstCost = @origestcosts, ActualCmtdUnits = @actualcmtdunits,
		ActualCmtdCost = @actualcmtdcosts, IncludedCOs = isnull(@cincludeco,0),
		FutureCOHours = isnull(@cfuturecohours,0), FutureCOUnits = isnull(@cfuturecounits,0),
		FutureCOCost = isnull(@cfuturecocosts,0), IncludedHours = isnull(@cincludecohours,0),
		IncludedUnits = isnull(@cincludecounits,0), DisplayedCOs = isnull(@cdisplayco,0),
		----#141731
		FutureActualCost = ISNULL(@FutureActualCost,0),
		--TK-03650
		UncommittedCosts=IsNull(@cuncmtdcosts,0)
where Mth=@mth and BatchId=@batchid and Co=@co and Job=@job and Phase=@phase and CostType=@costtype

---- next row
goto bcJCPB_loop


bcJCPB_end:
	if @opencursor = 1
		begin
		close bcJCPB
		deallocate bcJCPB
		set @opencursor = 0
		end


set @rcode = 0



bspexit:
	if @opencursor = 1
		begin
		close bcJCPT
		deallocate bcJCPT
		set @opencursor = 0
		end

	if @rcode<>0 select @msg=isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCProjRefreshCosts] TO [public]
GO
