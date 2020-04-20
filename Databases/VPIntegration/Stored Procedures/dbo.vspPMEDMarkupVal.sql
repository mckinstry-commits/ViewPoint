SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspPMEDMarkupVal]
/***********************************************************
 * Created By:	GF 05/23/2007 6.x
 * Modified By:
 *
 * USAGE:
 * Re-calculates amount based on the group and cost type selected.
 * 
 *
 *
 * INPUT PARAMETERS
 * PMCo
 * Project
 * BudgetNo
 * CostLevel
 * Seq
 * Group
 * CostType
 * Markup
 * Amount
 *
 * OUTPUT PARAMETERS
 * New Amount
 *
 * RETURN VALUE
 * 0 = success, 1 = failure
 *****************************************************/ 
(@pmco bCompany = null, @project bJob = null, @budgetno varchar(10) = null,
 @costlevel varchar(1) = 'T', @seq int = null, @groupno int = null,
 @line int = null, @costtype bJCCType = null, @markup bPct = 0, @amount bDollar = 0,
 @newamount bDollar = 0 output, @total bDollar = 0 output, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @basis bDollar

select @rcode = 0, @msg = '', @basis = 0, @newamount = isnull(@amount,0)

if @seq is null select @seq = -1

if @markup is null select @markup = 0

---- do nothing if missing key fields or cost level is 'D'
if @pmco is null or @project is null or @budgetno is null or @costlevel = 'D' goto bspexit

---- if the cost level = 'T' - total, then no cost type but there may be a groupno
if @costlevel = 'T'
	begin
	select @basis = isnull(sum(Amount),0)
	from PMED where PMCo=@pmco and Project=@project and BudgetNo=@budgetno
	and Line <= isnull(@line,Line) and Seq <> @seq
	goto CalcNewAmount
	end

---- for cost level = 'S' - subtotal, groupno required but costtype is nullable
---- only cost type 'D' - detail is included
if @costtype is not null
	begin
	select @basis = isnull(sum(Amount),0)
	from PMED where PMCo=@pmco and Project=@project and BudgetNo=@budgetno
	and GroupNo=@groupno and CostType=@costtype and CostLevel = 'D'
	and Seq <> @seq	and Line <= isnull(@line,Line)
	goto CalcNewAmount
	end

if @costtype is null
	begin
	select @basis = isnull(sum(Amount),0)
	from PMED where PMCo=@pmco and Project=@project and BudgetNo=@budgetno
	and GroupNo=@groupno and CostLevel = 'D' and Seq <> @seq and Line <= isnull(@line,Line)
	goto CalcNewAmount
	end


CalcNewAmount:
---- calculate new amount using basis
if @basis is null select @basis = 0
select @newamount = @basis * @markup


---- call function to return running total
exec @total = dbo.vfPMEDTotal @pmco, @project, @budgetno, @groupno, @line, @costlevel, @seq, @newamount
if @total is null select @total = 0





bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMEDMarkupVal] TO [public]
GO
