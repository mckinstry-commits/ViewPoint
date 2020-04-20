SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspPCForecastRevPctVal]
  /***********************************************************
   * CREATED BY:	GP	08/18/2009
   * MODIFIED BY:	
   *				
   * USAGE:
   * Used in PC Forecast Month to validate Rev and Cost Percentages
   *
   * INPUT PARAMETERS
   *   JCCo   
   *   Potential Project
   *   Forecast Month
   *   Revenue/Cost Percent
   *   Type (Revenue or Cost) 
   *
   * OUTPUT PARAMETERS
   *   @msg      Error
   *
   * RETURN VALUE
   *   0         Success
   *   1         Failure
   *****************************************************/ 
(@JCCo bCompany = 0, @PotentialProject varchar(20) = null, @ForecastMth bMonth = null,
 @RevPct bPct = null, @Type varchar(10) = null, @msg varchar(255) output)
as
set nocount on
  
	declare @rcode int, @PrevMonth bDate, @PrevPct bPct

	select @rcode = 0, @msg = ''

	--Get Previous Month
	set @PrevMonth = dateadd(month, -1, @ForecastMth)

	--Check Revenue % against Previous %
	if @Type = 'Revenue'
	begin
		select @PrevPct = RevenuePct from dbo.PCForecastMonth with (nolock) where JCCo=@JCCo
				and PotentialProject=@PotentialProject and ForecastMonth=@PrevMonth
		if @PrevPct is not null and @RevPct is not null
		begin
			if @PrevPct > @RevPct
			begin
				select @msg = 'Revenue Forecast % cannot be less than previous month.', @rcode = 1
				goto bspexit
			end
		end	
	end
	
	--Check Cost % against Previous %
	if @Type = 'Cost'
	begin
		select @PrevPct = CostPct from dbo.PCForecastMonth with (nolock) where JCCo=@JCCo
				and PotentialProject=@PotentialProject and ForecastMonth=@PrevMonth
		if @PrevPct is not null and @RevPct is not null
		begin
			if @PrevPct > @RevPct
			begin
				select @msg = 'Cost Forecast % cannot be less than previous month.', @rcode = 1
				goto bspexit
			end
		end	
	end


	bspexit:
		return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPCForecastRevPctVal] TO [public]
GO
