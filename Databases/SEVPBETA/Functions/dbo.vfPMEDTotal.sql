SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE function [dbo].[vfPMEDTotal]
(@pmco bCompany = null, @project bJob = null, @budgetno varchar(50) = null, @groupno int = null,
 @line int = null, @level varchar(1) = null, @seq int = null, @amount bDollar = 0)
returns bDollar
/***********************************************************
* Created By:	GF 05/29/2007
* Modified By:	
*
* calculates running total amount for subtotal markup (S) and total markup (T) rows
*
* Pass:
* @pmco	
* @project
* @budgetno
* @groupno
* @level
* @seq
* @amount
*
* OUTPUT PARAMETERS:
* Total
*
*****************************************************/
as
begin

declare @total bDollar, @accumamt bDollar, @format_total bDesc

select @total = null, @accumamt = 0, @format_total = null

---- exit function if missing key values
if @pmco is null goto exitfunction
if @project is null goto exitfunction
if @budgetno is null goto exitfunction
if @groupno is null goto exitfunction
if @line is null goto exitfunction
if @level is null goto exitfunction

---- if cost level = 'D' detail no total needed 
if @level = 'D' goto exitfunction


---- if @seq is null then new row set to highest value
if @seq is null select @seq = 99999999

---- get a running total for level 'S' - subtotal row
if @level = 'S'
	begin
	---- this is a running subtotal accumulate for group and any line < current line
	select @accumamt = isnull(sum(Amount),0)
	from PMED with (nolock) where PMCo=@pmco and Project=@project and BudgetNo=@budgetno
	and GroupNo=@groupno and CostLevel = 'D' and Line <= @line and Seq <> @seq 
	---- set total
	select @total = @accumamt + @amount
	goto exitfunction
	end

---- get a running total for level 'T' - total row
if @level = 'T'
	begin
	---- get sum 
	select @accumamt = isnull(sum(Amount),0)
	from PMED with (nolock) where PMCo=@pmco and Project=@project and BudgetNo=@budgetno
	and Line <= @line and Seq <> @seq
	---- set total
	select @total = @accumamt + @amount
	goto exitfunction
	end
	


exitfunction:
	return @total
end

GO
GRANT EXECUTE ON  [dbo].[vfPMEDTotal] TO [public]
GO
