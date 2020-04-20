SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspJCJPRecalcAmounts    Script Date: 05/23/2005 ******/
CREATE   procedure [dbo].[vspJCJPRecalcAmounts]
/***********************************************************
 * Created By:	DANF 06/09/2005
 * Modified By:
 *
 * USAGE:
 * Recalculates unitprice or amount checks UM and returns new values
 * 
 *
 *
 * INPUT PARAMETERS
 * JCCo
 * Job
 * Phase
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
(@jcco bCompany, @job bJob, @phase bPhase,
 @field char(1), @um bUM, 
 @units bUnits, @unitprice bUnitCost, @amount bDollar, 
 @newunits bUnits output, @newunitprice bUnitCost output, @newamount bDollar output, 
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @sum bUM, @mum bUM, @oldum bUM, @oldunits bUnits, @oldunitprice bUnitCost,
		@oldamount bDollar

select @rcode = 0, @newunits=isnull(@units,0), @newunitprice=isnull(@unitprice,0),
		@newamount=isnull(@amount,0), @msg=''

-- -- -- do nothing if missing key fields
if @jcco is null or @job is null or @phase is null goto bspexit

		if @field = 'U' -- -- -- if units change, calculate amount
			select @newamount = @newunits * @newunitprice
		if @field = 'P' -- -- -- if unit price changes, calculate amount
			select @newamount = @newunits * @newunitprice
		if @field = 'A' -- -- -- if amount changes, and unit price is zero calculate unit price if units <> 0
			begin
			if @newunits <> 0
				begin
				select @newunitprice = @newamount/@newunits
				end
          	end


bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCJPRecalcAmounts] TO [public]
GO
