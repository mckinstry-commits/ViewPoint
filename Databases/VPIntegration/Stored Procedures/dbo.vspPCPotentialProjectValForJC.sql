SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspPCPotentialProjectValForJC]
/***********************************************************
* CREATED BY:	GF 08/31/2009
* MODIFIED BY:
*				
* USAGE:
* Used in JC Contract Master to return descripiton and other values
*
* INPUT PARAMETERS
* JCCo   
* PotentialProject 
*
* OUTPUT PARAMETERS
* @msg				PC Potential Project Description of Department if found.
* @awarded			PC Potential Project Awarded Flag
* @allowforecast	PC Potential Project Allow forecast flag
* @startdate		PC Potential Project start date
* @completiondate	PC Potential Project completion date
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 
(@JCCo bCompany = 0, @PotentialProject varchar(20) = null, 
 @Awarded bYN = 'N' output, @AllowForecast bYN = 'Y' output,
 @startdate bDate = null output, @completiondate bDate = null output,
 @msg varchar(255) output)
as
set nocount on
  
declare @rcode int

set @rcode = 0

if @JCCo is not null and @PotentialProject is not null
	begin
	-- Potential Project Description --
	select @msg = Description, @Awarded = Awarded, @AllowForecast = AllowForecast,
			@startdate = StartDate, @completiondate=CompletionDate
	from dbo.PCPotentialWork with (nolock)
	where JCCo = @JCCo and PotentialProject = @PotentialProject
	if @@rowcount = 0
		begin
		select @msg = 'Potential Project not found.', @rcode = 1
		end
	end


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPCPotentialProjectValForJC] TO [public]
GO
