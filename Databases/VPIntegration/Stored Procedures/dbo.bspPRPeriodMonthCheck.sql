SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRPeriodMonthCheck    Script Date: 8/28/99 9:33:33 AM ******/
   CREATE    proc [dbo].[bspPRPeriodMonthCheck]
   
   /***********************************************************
    * CREATED BY: EN 9/22/00
    * MODIFIED BY:	EN 10/9/02 - issue 18877 change double quotes to single
    *				EN 9/29/03 - issue 20054 allow batch month to be either beginning or ending month in pay period
    *				EN 3/11/05 - issue 26342 check for period already posted to different month or when delete option not selected to warn about possible double posting
    *
    * Usage:
    *	Used by PRAutoLeave to find out if 1st month in bPRPC
    *  for a range of pay periods matches the batch month.
    *  If either pd in the range is blank then it only checks
    *  the one period.  If both are blank then nothing is checked.
    *  Also checks to see if one of the months in the range has already been 
    *	used to auto post leave and if so, was it posted to a different month
    *	than the batch month passed into this routine.
    *
    * Input params:
    *	@prco		PR company
    *  @mth        Batch month
    *	@prgroup 	PR Group
    * 	@beginpaypd First PR Ending Date to check
    *	@endpaypd	Last PR Ending Date to check
    *	@deleteyn	*optional* Delete option selected for usage/rate based accruals
    *
    * Output params:
    *	@msg		Employee Name or error message
    *
    * Return code:
    *	0 = success, 1 = failure
    ************************************************************/
   (@prco bCompany, @mth bMonth, @prgroup bGroup, @beginpaypd bDate = null,
    @endpaypd bDate = null, @deleteyn bYN, @msg varchar(200) output)
   as
   set nocount on
   
   declare @rcode int
   
   declare @postedpd bDate, @postedmth bMonth --26342
   
   select @rcode = 0
   
   /* check required input params */
   
   if @prco is null
   	begin
   	select @msg = 'Missing PR Company.', @rcode = 1
   	goto bspexit
   	end
   if @mth is null
   	begin
   	select @msg = 'Missing batch month.', @rcode = 1
   	goto bspexit
   	end
   if @prgroup is null
   	begin
   	select @msg = 'Missing PR Group.', @rcode = 1
   	goto bspexit
   	end
   
   -- check pay pd range
   if exists(select * from PRPC
             where PRCo = @prco and PRGroup = @prgroup and PREndDate >= @beginpaypd and PREndDate <= @endpaypd
               and BeginMth <> @mth and isnull(EndMth, BeginMth) <> @mth) --issue 20054
       begin
       select @msg = 'Not all pay periods in this range are valid for the batch month.', @rcode = 1
       goto bspexit
       end
   
   -- 26342 Has leave already been posted to a different month for any of the selected months?
   select @postedpd = PREndDate, @postedmth = Mth from PRLH
   where PRCo = @prco and PRGroup = @prgroup and PREndDate >= @beginpaypd and PREndDate <= @endpaypd
   	and Mth <> @mth
   if @@rowcount > 0
   	begin
   	select @msg = 'Warning.  Pay Period '+convert(varchar,@postedpd,1)+' has already been posted to month '+substring(convert(varchar,@postedmth,3),4,5)+'.' + char(13) + 'Even if delete option is used, it cannot affect entries made to a different month other than the batch month.', @rcode = 5
   	goto bspexit
   	end
   
   -- 26342 warn if leave has already been posted for any of the selected periods and delete option not selected
   if @deleteyn is not null
   begin
   	if (
   		select count(*) from PRLH 
   		where PRCo = @prco and PRGroup = @prgroup and PREndDate >= @beginpaypd and PREndDate <= @endpaypd
   		) > 0 and @deleteyn = 'N'
   		begin
   		select @msg='Leave has already been posted for one or more of these pay periods yet delete option was not selected.' + char(13) + 'This could result in duplicate postings.', @rcode=5
   		goto bspexit
   		end
   end
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRPeriodMonthCheck] TO [public]
GO
