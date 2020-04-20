SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspJCCIRecalcAmounts    Script Date: 05/23/2005 ******/
CREATE  procedure [dbo].[vspJCCIRecalcAmounts]
/***********************************************************
 * Created By:	GF 05/23/2005 6.x
 * Modified By:
 *
 * USAGE:
 * Recalculates unitprice or amount checks UM and returns new values
 * All this was done in the front-end for 5.x, Called from PMContractItem.
 * 
 *
 *
 * INPUT PARAMETERS
 * JCCo
 * Contract
 * Item
 * Field		field that is changed: U=Units, P=UnitPrice, A=Amount
 * UM
 * Units
 * UnitPrice
 * Amount
 *
 * OUTPUT PARAMETERS
 * NewUnits
 * NewUnitPrice
 * NewAmount
 *
 * RETURN VALUE
 * 0 = success, 1 = failure
 *****************************************************/ 
(@jcco bCompany, @contract bContract, @item bContractItem,
 @field char(1), @um bUM, @units bUnits, @unitprice bUnitCost,
 @amount bDollar, @newunits bUnits output, @newunitprice bUnitCost output, 
 @newamount bDollar output, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @sum bUM, @mum bUM, @oldum bUM, @oldunits bUnits, @oldunitprice bUnitCost,
		@oldamount bDollar

select @rcode = 0, @newunits=isnull(@units,0), @newunitprice=isnull(@unitprice,0),
		@newamount=isnull(@amount,0), @msg=''

-- -- -- do nothing if missing key fields
if @jcco is null or @contract is null or @item is null goto bspexit

-- -- -- if item does not exist, then adding new item
-- -- -- if not exists(select top 1 1 from bJCCI with (nolock) where JCCo=@jcco and Contract=@contract and Item=@item)
-- -- -- 	begin
	if @um ='LS'
		select @newunits = 0, @newunitprice = 0
	else
		begin
		if @field = 'U' -- -- -- if units change, calculate amount
			select @newamount = @newunits * @newunitprice
		if @field = 'P' -- -- -- if unit price changes, calculate amount
			select @newamount = @newunits * @newunitprice
		if @field = 'A' -- -- -- if amount changes, and unit price is zero calculate unit price if units <> 0
			begin
			if @newunits <> 0
				begin
				if @newunitprice = 0 select @newunitprice = @newamount/@newunits
				-- -- -- if unit price <> 0 and unit price <> amount/units give warning
				-- -- -- if @newunitprice <> convert(numeric(16,5),(@newamount / @newunits))
				if convert(numeric(16,3),@newunitprice) <> convert(numeric(16,3), @newamount/@newunits)
					select @msg = 'Units and/or Unit Price may be incorrect!', @rcode = 1
				end
			end
		end
-- -- -- 	end


bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCCIRecalcAmounts] TO [public]
GO
