SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[bspPROTInfoGet]
   /***********************************************************
   * CREATED: kb 3/26/98
   * MODIFIED: GG 4/30/99
   * 			EN 6/1/01 - issue 11870 (return level 2 & 3 hours and earncodes and check for shift overrides)
   *           EN 6/1/01 - issue 11871 (check for craft holidays in bPRCH)
   *           EN 8/14/01 - issue 14318 (@byshift s/b 'Y' whenever any shift ovrides exist for an ot sched)
   *			EN 10/8/02 - issue 18877 change double quotes to single
   *			EN 11/13/02 - issue 19188 make craft holiday check optional
   *			GG 01/24/03 - #18703 - fix Shift logic, all daily hours processed under max shift OT schedule
   *			EN 8/18/03 - issue 19763 check if holiday applies to crafts
   
   *
   * USAGE:
   * Called by PR Auto Overtime procedures to get daily overtime earnings codes
   * and limits.
   *
   * INPUT PARAMETERS
   *  @co         PR Company
   *  @prgroup    PR Group
   *  @prenddate  Pay Period Ending Date
   *  @otsched    Daily overtime schedule
   *  @shift      Hightest shift employee worked on posted date
   *  @craft      Craft (optional - only passed when OT based on Craft)
   *  @postdate   Posting Date from timecard
   *
   * OUTPUT PARAMETERS
   *  @lvl1hrs         Max # of regular time hours for the day
   *  @lvl1earncode    Overtime earnings code for the day
   *  @lvl2hrs        	Second level of regular time hours
   *  @lvl2earncode   	Second level overtime earnings code
   *  @lvl3hrs        	Third level of regular time hours
   *  @lvl3earncode   	Third level overtime earnings code
   *  @msg            	Error message if error occurs
   *
   * RETURN VALUE
   *   0         success
   *   1         Failure
   *****************************************************/
   	(@co bCompany = null, @prgroup bGroup = null, @prenddate bDate = null, @otsched tinyint = null,
   	 @shift tinyint = null, @craft bCraft = null, @postdate bDate = null, @lvl1hrs bHrs output,
   	 @lvl1earncode bEDLCode output, @lvl2hrs bHrs output, @lvl2earncode bEDLCode output,
   	 @lvl3hrs bHrs output, @lvl3earncode bEDLCode output, @byshift char(1) output, @msg varchar(255) output)
   as
   
   set nocount on
   
   declare @rcode int, @dayofweek tinyint
   
   select @rcode = 0
   
   -- get day of the week, 1 = Sunday, 7 = Saturday
   select @dayofweek = Datepart(weekday,@postdate)
   
   -- issue 19763 check if holiday applies to Crafts
   -- check for Holidays in bPRHD 
   if exists(select 1 from bPRHD (nolock) where PRCo=@co and PRGroup=@prgroup and
    	PREndDate=@prenddate and Holiday = @postdate and (@craft is null or (@craft is not null and ApplyToCraft = 'Y')) ) select @dayofweek = 8
   
   -- check for Craft Holidays in bPRCH (#11871)
   if @craft is not null
   	begin
    	if exists(select 1 from bPRCH (nolock) where PRCo=@co and Craft=@craft and Holiday=@postdate) 
   		select @dayofweek = 8
   	end
   
   -- get Overtime levels and earnings codes - check Shift override first
   select @lvl1hrs = case @dayofweek when 1 then Lvl1SunHrs when 2 then Lvl1MonHrs
   			when 3 then Lvl1TuesHrs	when 4 then Lvl1WedHrs when 5 then Lvl1ThursHrs
   			when 6 then Lvl1FriHrs when 7 then Lvl1SatHrs when 8 then Lvl1HolHrs end,
   		@lvl1earncode = case @dayofweek when 1 then Lvl1SunEarnCode	when 2 then Lvl1MonEarnCode
   			when 3 then Lvl1TuesEarnCode when 4 then Lvl1WedEarnCode when 5 then Lvl1ThursEarnCode
   			when 6 then Lvl1FriEarnCode	when 7 then Lvl1SatEarnCode	when 8 then Lvl1HolEarnCode end,
   		@lvl2hrs = case @dayofweek when 1 then Lvl2SunHrs when 2 then Lvl2MonHrs
   			when 3 then Lvl2TuesHrs	when 4 then Lvl2WedHrs when 5 then Lvl2ThursHrs
   			when 6 then Lvl2FriHrs when 7 then Lvl2SatHrs when 8 then Lvl2HolHrs end,
   		@lvl2earncode = case @dayofweek when 1 then Lvl2SunEarnCode	when 2 then Lvl2MonEarnCode
   			when 3 then Lvl2TuesEarnCode when 4 then Lvl2WedEarnCode when 5 then Lvl2ThursEarnCode
   			when 6 then Lvl2FriEarnCode	when 7 then Lvl2SatEarnCode	when 8 then Lvl2HolEarnCode end,
   		@lvl3hrs = case @dayofweek when 1 then Lvl3SunHrs when 2 then Lvl3MonHrs
   			when 3 then Lvl3TuesHrs	when 4 then Lvl3WedHrs when 5 then Lvl3ThursHrs
   			when 6 then Lvl3FriHrs when 7 then Lvl3SatHrs when 8 then Lvl3HolHrs end,
   		@lvl3earncode = case @dayofweek when 1 then Lvl3SunEarnCode	when 2 then Lvl3MonEarnCode
   			when 3 then Lvl3TuesEarnCode when 4 then Lvl3WedEarnCode when 5 then Lvl3ThursEarnCode
   			when 6 then Lvl3FriEarnCode	when 7 then Lvl3SatEarnCode	when 8 then Lvl3HolEarnCode end
   from bPROS (nolock)
   where PRCo = @co and OTSched = @otsched and Shift = @shift
   if @@rowcount = 0 
   	begin
   	-- get Overtime levels and earnings codes from standard OT schedule
   	select @lvl1hrs = case @dayofweek when 1 then SunHrs when 2 then MonHrs
   			when 3 then TuesHrs	when 4 then WedHrs when 5 then ThursHrs	when 6 then FriHrs
   			when 7 then SatHrs when 8 then HolHrs end,
   		@lvl1earncode = case @dayofweek when 1 then SunEarnCode	when 2 then MonEarnCode
   			when 3 then TuesEarnCode when 4 then WedEarnCode when 5 then ThursEarnCode
   			when 6 then FriEarnCode	when 7 then SatEarnCode	when 8 then HolEarnCode end,
   		@lvl2hrs = case @dayofweek when 1 then Lvl2SunHrs when 2 then Lvl2MonHrs
   			when 3 then Lvl2TuesHrs	when 4 then Lvl2WedHrs when 5 then Lvl2ThursHrs
   			when 6 then Lvl2FriHrs when 7 then Lvl2SatHrs when 8 then Lvl2HolHrs end,
   		@lvl2earncode = case @dayofweek when 1 then Lvl2SunEarnCode	when 2 then Lvl2MonEarnCode
   			when 3 then Lvl2TuesEarnCode when 4 then Lvl2WedEarnCode when 5 then Lvl2ThursEarnCode
   			when 6 then Lvl2FriEarnCode	when 7 then Lvl2SatEarnCode	when 8 then Lvl2HolEarnCode end,
   		@lvl3hrs = case @dayofweek when 1 then Lvl3SunHrs when 2 then Lvl3MonHrs
   			when 3 then Lvl3TuesHrs	when 4 then Lvl3WedHrs when 5 then Lvl3ThursHrs
   			when 6 then Lvl3FriHrs when 7 then Lvl3SatHrs when 8 then Lvl3HolHrs end,
   		@lvl3earncode = case @dayofweek when 1 then Lvl3SunEarnCode	when 2 then Lvl3MonEarnCode
   			when 3 then Lvl3TuesEarnCode when 4 then Lvl3WedEarnCode when 5 then Lvl3ThursEarnCode
   			when 6 then Lvl3FriEarnCode	when 7 then Lvl3SatEarnCode	when 8 then Lvl3HolEarnCode end
   	from bPROT (nolock)
       where PRCo = @co and OTSched = @otsched
       if @@rowcount = 0
            begin
            select @msg = 'Invalid Overtime Schedule: ' + convert(varchar,@otsched), @rcode = 1
            goto bspexit
            end
       end
   
   bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPROTInfoGet] TO [public]
GO
