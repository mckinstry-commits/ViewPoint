SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspPMEDRecalculate]
/***********************************************************
 * Created By:	GF 05/24/2007 6.x
 * Modified By:
 *
 * USAGE:
 * Re-calculates amounts for costing levels 'S' and 'T' when
 * PMED records are added, changed, or deleted.
 * Currently only called from PMED triggers
 * 
 *
 *
 * INPUT PARAMETERS
 * PMCo
 * Project
 * Estimate
 *
 *
 * RETURN VALUE
 * 0 = success, 1 = failure
 *****************************************************/ 
(@pmco bCompany = null, @project bJob = null, @budgetno varchar(10) = null,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0

---- do nothing if missing key fields
if @pmco is null or @project is null or @budgetno is null goto bspexit


---- calculate costlevel 'S' with CostType not null
if exists(select PMCo from PMED where PMCo=@pmco and Project=@project and BudgetNo=@budgetno
			and CostLevel='S' and CostType is not null)
	begin
	update PMED set Amount = isnull(a.Markup,0) * 
			(select isnull(sum(b.Amount),0) from PMED b where b.PMCo=a.PMCo and b.Project=a.Project
					and b.BudgetNo=a.BudgetNo and b.GroupNo=a.GroupNo and b.CostLevel = 'D'
					and b.CostType=a.CostType and b.Line<=a.Line and b.Seq <> a.Seq)
	from PMED a
	where a.PMCo=@pmco and a.Project=@project and a.BudgetNo=@budgetno and a.CostLevel = 'S' and a.CostType is not null
	end


---- calculate costlevel 'S' with CostType is null
if exists(select PMCo from PMED where PMCo=@pmco and Project=@project and BudgetNo=@budgetno
			and CostLevel='S' and CostType is null)
	begin
	update PMED set Amount = isnull(a.Markup,0) * 
			(select isnull(sum(b.Amount),0) from PMED b where b.PMCo=a.PMCo and b.Project=a.Project
					and b.BudgetNo=a.BudgetNo and b.GroupNo=a.GroupNo and b.CostLevel = 'D'
					and b.Line<=a.Line and b.Seq<>a.Seq)
	from PMED a
	where a.PMCo=@pmco and a.Project=@project and a.BudgetNo=@budgetno and a.CostLevel = 'S' and a.CostType is null
	end

---- calculate costlevel 'T'
if exists(select PMCo from PMED where PMCo=@pmco and Project=@project and BudgetNo=@budgetno and CostLevel='T')
	begin
	update PMED set Amount = isnull(a.Markup,0) * 
			(select isnull(sum(b.Amount),0) from PMED b where b.PMCo=a.PMCo and b.Project=a.Project
					and b.BudgetNo=a.BudgetNo and b.Line<=a.Line and b.Seq <> a.Seq) ---- and GroupNo=a.GroupNo)
	from PMED a
	where a.PMCo=@pmco and a.Project=@project and a.BudgetNo=@budgetno and a.CostLevel = 'T'
	end





bspexit:
	if @rcode <> 0 select @msg = isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMEDRecalculate] TO [public]
GO
