SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[bspPRDailyBen]
   /********************************************************
   * CREATED BY:   EN 8/18/03 - issue 21186 Benefit based on day of week
   * MODIFIED BY:	
   *
   * USAGE:
   * 	Calculates a Benefit based on day of week liability which is based on 
   *	different rates for time worked on a weekday, time worked on
   *	Saturday, and time worked on Sunday or a Holiday.
   *
   *	Rates are stored in routine master (bPRRM).
   *
   *	Called from bspPRProcessCraft
   *
   * INPUT PARAMETERS:
   *	@prco			PR Company
   *	@prgroup		PR Group
   *	@prenddate		PR End Date
   *	@weekdayrate	liab rate for weekday hours
   *	@satrate	    liab rate for Saturday hours
   *	@sunholrate     liab rate for Sunday & Holiday hours
   *
   * OUTPUT PARAMETERS:
   *	@amt	  calculated liability amount
   *	@errmsg		  error message if failure
   *
   * RETURN VALUE:
   * 	0 	    success
   *	1 		failure
   **********************************************************/
   (@prco bCompany, @prgroup bGroup, @prenddate bDate, @craft bCraft, @weekdayrate bRate, 
   	@satrate bRate, @sunholrate bRate, @amt bDollar output, @errmsg varchar(255) output)
   
   as
   set nocount on
   
   declare @rcode int, @procname varchar(30), @weekdayhrs bHrs, @sathrs bHrs, @sunholhrs bHrs
   
   select @rcode = 0, @procname = 'bspPRDailyBen'
   
   -- get weekday hours, Saturday hours, and Sunday hours
   select @weekdayhrs = isnull(sum(Hours),0) 
   from PRPE 
   where VPUserName = SUSER_SNAME() and datepart(weekday, PostDate) between 2 and 6
   	and PostDate not in (select Holiday from PRCH where PRCo=@prco and Craft=@craft)
   	and PostDate not in (select Holiday from PRHD where PRCo=@prco and PRGroup=@prgroup 
   							and PREndDate=@prenddate and ApplyToCraft='Y')
   select @sathrs = isnull(sum(Hours),0) 
   from PRPE 
   where VPUserName = SUSER_SNAME() and datepart(weekday, PostDate) = 7
   	and PostDate not in (select Holiday from PRCH where PRCo=@prco and Craft=@craft)
   	and PostDate not in (select Holiday from PRHD where PRCo=@prco and PRGroup=@prgroup 
   							and PREndDate=@prenddate and ApplyToCraft='Y')
   select @sunholhrs = isnull(sum(Hours),0) 
   from PRPE where VPUserName = SUSER_SNAME() and datepart(weekday, PostDate) = 1
   	and PostDate not in (select Holiday from PRCH where PRCo=@prco and Craft=@craft)
   	and PostDate not in (select Holiday from PRHD where PRCo=@prco and PRGroup=@prgroup 
   							and PREndDate=@prenddate and ApplyToCraft='Y')
   
   -- get holiday hours for craft
   select @sunholhrs=@sunholhrs+isnull(sum(Hours),0)
   from PRPE a
   join PRCH b on a.PostDate=b.Holiday
   where a.VPUserName = SUSER_SNAME() and b.PRCo=@prco and b.Craft=@craft
   
   -- get holiday hours for pay period if they apply to craft ... make sure it's not a repeat of a holiday set up in PRCH
   select @sunholhrs=@sunholhrs+isnull(sum(Hours),0)
   from PRPE a
   join PRHD b on a.PostDate=b.Holiday
   where a.VPUserName = SUSER_SNAME() and b.PRCo=@prco and b.PRGroup=@prgroup and 
   	b.PREndDate=@prenddate and b.ApplyToCraft = 'Y' and 
   	(select count(*) from PRCH c where c.PRCo=@prco and c.Craft=@craft and c.Holiday=a.PostDate) = 0
   
   -- compute liability
   select @amt = (@weekdayhrs * @weekdayrate) + (@sathrs * @satrate) + (@sunholhrs * @sunholrate)
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRDailyBen] TO [public]
GO
