SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[vspJCOITotalsGet]

/*************************************
* CREATED BY:		GP 11/6/2008
* Modified By:		GF 06/30/2009 - issue #134603 problem with @ItemMarkup needed to be bDollar
*
*
*		Gets JC Change Order Item Totals.
*
*		Input Parameters:
*			JCCo - JC Company
*			Job	- Current Job
*			ACO	- Change Order
*			ACOItem	- Change Order Item
*    
*		Output Parameters:
*			ItemRevenue
*			ItemCost
*			ItemProfit
*			ItemMarkup
*
*			rcode - 0 Success
*					1 Failure
*			msg - Return Message
*		
**************************************/
(@JCCo tinyint = null,  @Job varchar(10) = null, @ACO varchar(10) = null, @ACOItem varchar(10) = null, 
 @ItemRevenue bDollar = 0 output, @ItemCost bDollar = 0 output, @ItemProfit bDollar = 0 output, 
 @ItemMarkup bDollar = 0 output, @msg varchar(255) output)

as
set nocount on

declare @rcode int
set @rcode = 0

----------------
-- Validation --
----------------
if @JCCo is null
begin
	select @msg = 'Missing JCCo!', @rcode = 1
	goto vspexit
end

if @Job is null
begin
	select @msg = 'Missing Job!', @rcode = 1
	goto vspexit
end

if @ACO is null
begin
	select @msg = 'Missing ACO!', @rcode = 1
	goto vspexit
end

if @ACOItem is null
begin
	select @msg = 'Missing ACOItem!', @rcode = 1
	goto vspexit
end

---------------------
-- Get JCOI Totals --
---------------------
select @ItemRevenue = Revenue, @ItemCost = EstimatedCost, @ItemProfit = Profit, @ItemMarkup = Markup
from JCOITotals with(nolock)
where JCCo = @JCCo and Job = @Job and ACO = @ACO and ACOItem = @ACOItem


vspexit:
select @msg = 'Cannot return item totals. ' + @msg
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCOITotalsGet] TO [public]
GO
