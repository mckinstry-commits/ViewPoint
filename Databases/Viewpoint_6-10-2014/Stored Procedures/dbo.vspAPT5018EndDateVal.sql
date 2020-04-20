SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[vspAPT5018EndDateVal]
   /***************************************************
   * CREATED BY    : MV 06/09/09
   * Usage:
   *   Validates bAPT5 Period End Date. If date is not same as previous Per End Dates used 
   *	return a warning.
   *
   * Input:
   *	@perenddate 
    
   * Output:
   *   @msg          
   *
   * Returns:
   *	0            success
   *   5             warn
   *************************************************/
   	(@apco bCompany, @perenddate bDate, @msg varchar(120) output)
   as
   
   set nocount on
   
   declare @rcode int, @month int, @day int 
   
   select @rcode = 0
	
	select @month = datepart(month,@perenddate)
	
	if exists (select top 1 1 from bAPT5 where APCo=@apco)
	begin
	select top 1 1 from dbo.APT5 (nolock) where APCo=@apco and datepart(month,PeriodEndDate) = @month 
	if @@rowcount = 0
		begin
		select @msg = 'Warning: Period End Date month entered is different from previously set Period End Date month.'
		select @rcode = 5
		end
	
	end
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPT5018EndDateVal] TO [public]
GO
