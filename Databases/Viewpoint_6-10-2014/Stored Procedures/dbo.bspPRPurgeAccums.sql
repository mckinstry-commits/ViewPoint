SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRPurgeAccums    Script Date: 8/28/99 9:35:38 AM ******/
   CREATE     procedure [dbo].[bspPRPurgeAccums]
   /***********************************************************
    * CREATED BY: EN 5/28/98
    * MODIFIED By : EN 3/10/00 - fixed to make sure @DLCode defaults to null and that where clause doesn't fail if @DLCode does equal null
    *               EN 4/20/00 - not purging earnings correctly
    *				EN 10/9/02 - issue 18877 change double quotes to single
    *				EN 10/11/02 - issue 17918 add ability to specify single employee to purge
    *				EN 1/10/03 - issue 17918  return message if there is nothing to purge
    *				mh 02/19/2010 #137971 - modified to allow date compares to use other then calendar year.
    *				MV 02/16/11 - #143362 - corrected where clause for delete
    *				MV 02/22/11	- #143362 - added validation of current payroll year begin month against through month.
    *
    * USAGE:
    * Purges entries from PREA through a specified month.  Optionally
    * will purge only for a specified dedn/liab code.
    *
    * INPUT PARAMETERS
    *   @PRCo		PR Company
    *   @Month		Month to purge through
    *   @DLCode		DL code to restrict by (optional)
    *	 @Empl		Employee to purge (null for all)
    *
    * OUTPUT PARAMETERS
    *   @errmsg     if something went wrong
    * RETURN VALUE
    *   0   success
    *   1   fail
    *****************************************************/
   
   	(@PRCo bCompany, @Month bMonth, @DLCode bEDLCode = null, @Empl bEmployee = null,
   	 @errmsg varchar(100) output)
   as
   set nocount on
   declare @rcode int
   
   select @rcode = 0

--137971
	declare @yearendmth tinyint, @accumbeginmth bMonth, @accumendmth bMonth, @CurrentPayrollEndDate bDate,
	@CurrMth bDate,@DefaultCountry varchar(3), @CurrYearBeginMth bDate

	SELECT @DefaultCountry = DefaultCountry
	FROM dbo.bHQCO
	WHERE HQCo= @PRCo

	SELECT @yearendmth = CASE @DefaultCountry WHEN 'AU' THEN 6 ELSE 12 END
	--select @yearendmth = case h.DefaultCountry when 'AU' then 6 else 12 end
	--from bHQCO h with (nolock) 
	--where h.HQCo = @PRCo

	exec vspPRGetMthsForAnnualCalcs @yearendmth, @Month, @accumbeginmth output, @accumendmth output, @errmsg output
-- end  137971

-- #143362
	-- validate through month against current payroll year's begin month.
	SELECT @CurrMth = dbo.vfDateOnlyMonth ()
	EXEC vspPRGetMthsForAnnualCalcs @yearendmth, @CurrMth, @CurrYearBeginMth output, NULL, @errmsg output
	
	IF (
			@Month > @CurrYearBeginMth
		)
	BEGIN
		SELECT @errmsg = 'Through Month is greater or equal to current payroll year.', @rcode = 1
		GOTO bspexit	
	END
-- End #143362 
	
   
	if @DLCode is null
	begin
	
/*137971
       delete from bPREA
       where PRCo = @PRCo and Mth <= @Month and datepart(year,Mth) <> datepart(year,getdate())
           and (EDLType = 'E' or (EDLType <> 'E' and exists(select * from PRDL where PRCo=@PRCo and DLCode=EDLCode and SelectPurge='N')))
   		and Employee = isnull(@Empl, Employee)
*/	
		delete from bPREA
		where PRCo = @PRCo and Mth /*not between @accumbeginmth #143362 */  BETWEEN @accumbeginmth AND @Month 
		and (EDLType = 'E' or (EDLType <> 'E' and exists(select 1 from PRDL where PRCo=@PRCo and DLCode=EDLCode and SelectPurge='N')))
		and Employee = isnull(@Empl, Employee)
--end 137971		

		if @@rowcount = 0 select @errmsg = 'Nothing to purge.', @rcode = 1
		goto bspexit
	end
   
	if @DLCode is not null
	begin
/*137971	
		delete from bPREA
		where PRCo = @PRCo and Mth <= @Month and (EDLType='D' or EDLType='L') and EDLCode = @DLCode
		and datepart(year,Mth) <> datepart(year,getdate())
		and Employee = isnull(@Empl, Employee)
*/

		delete from bPREA
		where PRCo = @PRCo and Mth <= @Month and (EDLType='D' or EDLType='L') and EDLCode = @DLCode
		and Mth /*not between @accumbeginmth #143362 */  BETWEEN @accumbeginmth AND @Month 
		and Employee = isnull(@Empl, Employee)
--137971		
		if @@rowcount = 0 select @errmsg = 'Nothing to purge.', @rcode = 1
	end
   
   
   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRPurgeAccums] TO [public]
GO
