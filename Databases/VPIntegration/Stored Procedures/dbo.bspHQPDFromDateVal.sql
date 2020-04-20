SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspHQPDFromDateVal ******/
CREATE  Procedure [dbo].[bspHQPDFromDateVal]
/*************************************
* Created By:	GF 03/14/2009 - issue #129409 price escalation
* Modified By:
*
* validates from date and verifies not in an existing date range in HQPD
* used in HQ Price escalation index adjustments
*
*
* Pass:
* Country
* State
* Price Index
* FromDate
* HQPD Sequence
*
* Success returns:
* 0 - success
*
* Error returns:
* 1 and error message
**************************************/
(@country varchar(2), @state varchar(4) = null, @priceindex varchar(20) = null,
 @hqpd_seq bigint = null, @fromdate bDate = null, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0

if @fromdate is null goto bspexit

if @country is null
	begin
   	select @msg = 'Missing Country', @rcode = 1
   	goto bspexit
   	end

if @state is null
	begin
	select @msg = 'Missing State', @rcode = 1
	goto bspexit
	end

if @priceindex is null
	begin
	select @msg = 'Missing Price Index', @rcode = 1
	goto bspexit
	end


---- check if @fromdate already exist in HQPD within a existing date range
if exists(select top 1 1 from bHQPD with (nolock) where Country=@country
		and State=@state and PriceIndex=@priceindex and Seq <> isnull(@hqpd_seq,-1)
		and @fromdate between FromDate and ToDate)
	begin
	select @msg = 'From Date: ' + isnull(convert(varchar(12),@fromdate),'') + ' is invalid. Already exists in a date range.', @rcode = 1
	end


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQPDFromDateVal] TO [public]
GO
