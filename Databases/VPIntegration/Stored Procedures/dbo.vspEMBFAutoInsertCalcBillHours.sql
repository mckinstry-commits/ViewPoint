SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE procedure [dbo].[vspEMBFAutoInsertCalcBillHours]
/***********************************************************
* CREATED BY: 	TRL 08/06/09 Issue 129345
* MODIFIED BY:	GF 07/13/2012 TK-16363 RE-APPLY FROM 6.2.1 FORWARD EACH FIX. remmed out 143145 FOR NOW
*				GF 07/23/2012 TK-16429 break start/stop begin or end of day
*
*
*				
* USAGE:  Calculates total billable hours from Period Beginning Date to  Period Ending Date/Est Out Date 
* Returns Total billable hours to vspEMBFAutoInsert
*
* INPUT PARAMETERS
*   EMCo        EM Co
*   AutoTemplate      
*   Equipment     
*   Category (Equipment Category EMEM)
*   ToJCCo
*   ToJob
*   Beginning Date (Beginning of billable period)
*   Ending Date (Ending Period Date or Est OutDate
*   Date/Time In
*   Date/Time Out  or Est Date Out
*   Exclude Date 1-6
*   Bill saturdays & sundays
*   
* OUTPUT PARAMETERS
*   @useestoutdate
*	@billablehours
*   @errmsg     if something went wrong
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/
(@emco bCompany = null, @autotemplate varchar(10), @equip bEquip = null,  @catgy bCat = null,
@tojcco bCompany=null,   @tojob bJob = Null, @begindate bDate=Null, @enddate bDate=Null,
@datein bDate=null, @timein smalldatetime=null, @dateout bDate=null,@timeout smalldatetime=null,
@date1 bDate, @date2 bDate, @date3 bDate, @date4 bDate, @date5 bDate, @date6 bDate, 
@billsats bYN, @billsuns bYN, @equip_catgy_templt_type varchar(5) output,@startbillingintrnsfrindate bYN output, @useestoutdate bYN output, 
@rulestable varchar(10) output, @phase bPhase output, @maxperpd bDollar output, @maxpermth bDollar output, 
@maxperjob bDollar output, @minperpd bDollar output, @billablehours bHrs output, @errmsg varchar(255) output)

as

set nocount on

declare @rcode int, 
/*Auto Template variables*/
@daystart smalldatetime, @daystop smalldatetime, @hrsperday bHrs,@br1start smalldatetime, @br1stop smalldatetime, 
@br2start smalldatetime, @br2stop smalldatetime,@br3start smalldatetime, @br3stop smalldatetime, @equip_catgy char(5),
/*Equipment/Job hour calulation variables*/
@firstday bDate, @lastday bDate, @days int, @breakstart smalldatetime, @breakstop smalldatetime, 
/*127253 ->*/ @IsDayStopMidnight	char(1),	@DateInMidNightMins bHrs,	 @DateOutMidNightMins bHrs, /*<-127253*/
@nonworkday bDate, @everyday bDate, @inhour bHrs, @inminute bHrs,@outhour bHrs, @outminute bHrs,
/*Variables that change (mostly) when Equipment/JCCo/Job change*/
@hours bHrs,@cnt int, @indayflag char(7), @outdayflag char(7)

----TK-16429 
DECLARE @BreakEndDay CHAR(1), @BreakBegDay CHAR(1), @BreakStopMidnightMins NUMERIC(10,2)
SET @BreakEndDay = 'N'
SET @BreakBegDay = 'N'

select @rcode = 0, @startbillingintrnsfrindate = 'N', @useestoutdate ='N', @billablehours =0,
		@IsDayStopMidnight = 'N'

/* 7.  Look up usage template data for equipment then category if neccessary */
IF exists(select 1 from dbo.EMUE with(nolock) where EMCo = @emco and AUTemplate = @autotemplate and Equipment = @equip)
	Begin
		select @rulestable = RulesTable, @phase = JCPhase, @maxperpd = MaxPerPD, @maxpermth = MaxPerMonth,
		@maxperjob = MaxPerJob,@minperpd = MinPerPd, @daystart = DayStartTime, @daystop = DayStopTime,
		@hrsperday = HrsPerDay,@br1start = Br1StartTime, @br1stop = Br1StopTime, @br2start = Br2StartTime,
		@br2stop = Br2StopTime,@br3start = Br3StartTime, @br3stop = Br3StopTime, @equip_catgy_templt_type = 'equip',
		/*129345->*/@startbillingintrnsfrindate=BillingStartsOnTrnsfrInDateYN , @useestoutdate= UseEstDateOutYN/*<- 129345*/
		from dbo.EMUE with(nolock)
		where EMCo = @emco and AUTemplate = @autotemplate and Equipment = @equip
	End
ELSE
	Begin
		if exists(select 1 from dbo.EMUC with(nolock) where EMCo = @emco and AUTemplate = @autotemplate and isnull(Category,'') = isnull(@catgy,''))
			begin
				select @rulestable = RulesTable, @phase = JCPhase, @maxperpd = MaxPerPD, @maxpermth = MaxPerMonth,
				@maxperjob = MaxPerJob,	@minperpd = MinPerPd, @daystart = DayStartTime, @daystop = DayStopTime,
				@hrsperday = HrsPerDay,	@br1start = Br1StartTime, @br1stop = Br1StopTime, @br2start = Br2StartTime,
				@br2stop = Br2StopTime,@br3start = Br3StartTime, @br3stop = Br3StopTime, @equip_catgy_templt_type = 'catgy',
				/*129345->*/@startbillingintrnsfrindate=BillingStartsOnTrnsfrInDateYN , @useestoutdate= UseEstDateOutYN/*<- 129345*/
				from dbo.EMUC with(nolock)
				where EMCo = @emco and AUTemplate = @autotemplate and isnull(Category,'') = isnull(@catgy,'')
			end
		else 
			begin
				goto vspexit
			end
	End

----TK-16363 check parameters and set to null if '' for readability
IF ISNULL(@timein, '') = ''  SET @timein = NULL
IF ISNULL(@timeout, '') = '' SET @timeout = NULL
IF ISNULL(@dateout, '') = '' SET @dateout = NULL



if @daystart is null or @daystop is null or @hrsperday is null
begin
	select @errmsg = 'Missing DayStartTime, DayStopTime or HrsPerDay in Auto Template ' + isnull(@autotemplate,'') + ', Category ' + isnull(@catgy,'') + '.', @rcode = 1
	goto vspexit
end

/* 8. Start calculate hours on job */
/* ISSUE: #127253 --  CHECK TO SEE IF DAY STOP IS AT MIDNIGHT*/
IF (datepart(hh,@daystop) +  datepart(mi,@daystop)) = 0
BEGIN
		Select @IsDayStopMidnight = 'Y'
END

/* calculate hours on job */
select @firstday = @begindate, @lastday = @enddate
if @datein > @begindate 
begin
	select @firstday = @datein
end

if @dateout is not null and @dateout <@enddate 
begin
	select @lastday = @dateout
end
select @days = datediff(dd,@firstday,@lastday) + 1

if @datein >= @begindate 
begin
	select @days = @days - 1
end

if @dateout is not null and @dateout <= @enddate 
begin
	select @days = @days - 1
end

if @days = -1 
begin 
	select @days = 0
End

/* back out non-work days */
select @cnt = 1
WHILE @cnt <= 6
BEGIN
	if @cnt = 1
	begin
		if @date1 is not null
			begin
				select @nonworkday = @date1
			end
		else
			begin
				goto increment
			end
	end
	if @cnt = 2
	begin
		if @date2 is not null
			begin
				select @nonworkday = @date2
			end
		else
			begin
				goto increment
			end
	end
	if @cnt = 3
	begin
		if @date3 is not null 
			begin
				select @nonworkday = @date3
			end
		else
			begin
				goto increment
			end
	end
	if @cnt = 4
	begin
		if @date4 is not null
			begin
				select @nonworkday = @date4
			end
		else
			begin
				goto increment
			end
	end
	if @cnt = 5
	begin
		if @date5 is not null
			begin
				select @nonworkday = @date5
			end
		else
			begin
				goto increment
			end
	end
	if @cnt = 6
	begin
		if @date6 is not null 
			begin
				select @nonworkday = @date6
			end
		else
			begin
				goto increment
			end
	end
     
	if @billsuns = 'N' and datepart(weekday,@nonworkday) = 1 goto increment
	if @billsats = 'N' and datepart(weekday,@nonworkday) = 7 goto increment
     
	/* non-workday */
	if @nonworkday >= @firstday and @nonworkday <= @lastday select @days = @days - 1

	/* transferred in on a weekend */
	if @datein = @nonworkday select @indayflag = 'nonwork', @days = @days + 1

	/* transderred out on a non-work day */
	if @dateout is not null and @dateout = @nonworkday select @outdayflag = 'nonwork', @days = @days + 1

	increment:
	select @cnt = @cnt + 1
END
select @cnt = 0
     
/* back out weekends */
select @everyday = @firstday
WHILE @everyday <= @lastday
BEGIN
	if @billsuns = 'N' and datepart(weekday,@everyday) = 1 select @days = @days - 1
	if @billsuns = 'N' and datepart(weekday,@everyday) = 1 and @datein = @everyday select @indayflag = 'nonwork', @days = @days + 1
	if @billsuns = 'N' and datepart(weekday,@everyday) = 1 and @dateout = @everyday select @outdayflag = 'nonwork', @days = @days + 1
	if @billsats = 'N' and datepart(weekday,@everyday) = 7 select @days = @days - 1
	if @billsats = 'N' and datepart(weekday,@everyday) = 7 and @datein = @everyday select @indayflag = 'nonwork', @days = @days + 1
	if @billsats = 'N' and datepart(weekday,@everyday) = 7 and @dateout = @everyday select @outdayflag = 'nonwork', @days = @days + 1
	select @everyday = dateadd(dd,1,@everyday)
END
     
/* total hours */
select @hours = @days * @hrsperday


/* Date In Section; calculate a full or partial day if the equipment was transferred on to the job on or prior to the beginning date */
IF @datein >= @begindate and  isnull(@indayflag,'') <> 'nonwork'
BEGIN
	if @timein is not null 
		begin
			select @inhour = datepart(hh,@timein), @inminute = datepart(mi,@timein)
		end
	else
		begin
			/* set time in as the start of day  */
			select @inhour = datepart(hh,@daystart), @inminute = datepart(mi,@daystart)
		end

	/* reset inhour and inminute if the equipment was transferred in before the start of the day to prevent inflated hours */
	if @inhour < datepart(hh,@daystart) select @inhour = datepart(hh,@daystart), @inminute = datepart(mi,@daystart)
	if @inhour = datepart(hh,@daystart) and @inminute < datepart(mi,@daystart) select @inminute = datepart(mi,@daystart)

	/*ISSUE: #127253 	-- CALCULATE HOURS --*/
	IF @IsDayStopMidnight <> 'Y'
		BEGIN
			/* reset inhour and inminute if the equipment was transferred in after the end of the day to prevent negative hours */
			if @inhour > datepart(hh,@daystop) select @inhour = datepart(hh,@daystop), @inminute = datepart(mi,@daystop)
			if @inhour = datepart(hh,@daystop) and @inminute > datepart(mi,@daystop) select @inminute = datepart(mi,@daystop)

			/* add in the hours that it was on the job the first day */
			select @hours = @hours + ((datepart(hh,@daystop) - @inhour) 
				+ ((cast(datepart(mi,@daystop) as numeric(10,2)) - cast(@inminute as numeric(10,2))) / cast(60 as numeric(10,2))))	--Does Work w/out Cast since @inminute already cast bHrs
		END
	ELSE
		BEGIN
			-- DETERMINE NUMBER OF MINUTES FOR CALCULATION --
			SELECT	@DateInMidNightMins = 
				CASE 
					WHEN @inminute = 0 THEN 0
					ELSE ((0 - cast(@inminute as numeric(10,2))) / cast(60 as numeric(10,2)))	--Does Work w/out Cast since @inminute already cast bHrs
				END
			-- UPDATE HOURS --
			SET @hours = @hours + (24 - @inhour) + @DateInMidNightMins
		END

	/**** proccess break times on partial day transfers ****/
	select @cnt = 1
	While @cnt <=3
	Begin
		if @cnt = 1
		begin
			if @br1start is not null and @br1stop is not null
				begin
					 select @breakstart = @br1start, @breakstop = @br1stop
				end
			 else 
				begin
					goto BreakIn
				end
		end
		if @cnt = 2
		begin
			if @br2start is not null and @br2stop is not null
				begin
					select @breakstart = @br2start, @breakstop = @br2stop
				end
			else 
				begin 
					goto BreakIn
				end
		end
		if @cnt = 3
		begin
			if @br3start is not null and @br3stop is not null
				begin
					select @breakstart = @br3start, @breakstop = @br3stop
				end
			else
				begin
					goto BreakIn
				end
		END
		
		----TK-16429
		IF @breakstart IS NULL OR @breakstop IS NULL GOTO BreakIn
		SET @BreakEndDay = 'N'
		SET @BreakBegDay = 'N'
		SET @BreakStopMidnightMins = 0
		IF (DATEPART(hh,@breakstart) +  DATEPART(mi,@breakstart)) = 0 SET @BreakBegDay = 'Y'
		IF (DATEPART(hh,@breakstop)  +  DATEPART(mi,@breakstop))  = 0
			BEGIN
			SET @BreakEndDay = 'Y'
			SET @BreakStopMidnightMins =
					CASE WHEN @inminute = 0 THEN 0
						 ELSE ((0 - cast(@inminute as numeric(10,2))) / cast(60 as numeric(10,2)))
						 END
			END
		
 		---- TK-16429 if transferred in before a break, subtract out the break time */
		if ((@inhour < datepart(hh,@breakstart))
			OR (@inhour = datepart(hh,@breakstart) AND @inminute < datepart(mi,@breakstart)))
			BEGIN
			IF @BreakEndDay = 'N'
				BEGIN
				select @hours = @hours - (datepart(hh,@breakstop) - datepart(hh,@breakstart)
					+ ((cast(datepart(mi,@breakstop) as numeric(10,2)) - cast(datepart(mi,@breakstart) as numeric(10,2)))	--Does need to be Cast because of datepart(mi,@breakstart)
					/ cast(60 as numeric(10,2))))
				END
			ELSE
				BEGIN
				SET @hours = @hours - (24 - DATEPART(hh,@breakstart) + @BreakStopMidnightMins)
				END
			END
			
		---- TK-14629 if transferred in during a break, subtract out portion of the break
		---- could be end of day (00:00:00)
		if ((@inhour > datepart(hh,@breakstart))
				or (@inhour = datepart(hh,@breakstart) and @inminute > datepart(mi,@breakstart)))
			and ((@inhour < datepart(hh,@breakstop))
				OR (@inhour = DATEPART(hh,@breakstop) and @inminute <= datepart(mi,@breakstop))
				OR (@BreakEndDay = 'Y'))
			BEGIN
			IF @BreakEndDay = 'N'
				BEGIN
				select @hours = @hours - ((datepart(hh,@breakstop) - @inhour) 
					+ ((cast(datepart(mi,@breakstop) as numeric(10,2)) - cast(@inminute as numeric(10,2))) 	--Does Work w/out Cast since @inminute already cast bHrs
					/ cast(60 as numeric(10,2))))
				END
			ELSE
				BEGIN
				SELECT @hours = @hours - (24 - @inhour + @BreakStopMidnightMins)
				END
			END
						
		BreakIn:
		select @cnt = @cnt + 1
	End
END


/* Date Out Section; calculate a full or partial day if the equipment was transferred off the job on or after the ending date */
IF (@dateout is not null and @dateout <= @enddate) and isnull(@outdayflag,'') <> 'nonwork'
BEGIN
	if @timeout is not null 
		begin
			select @outhour = datepart(hh,@timeout), @outminute = datepart(mi,@timeout)
		end
	else
		begin
			/* set time out as the  end of day */
			select @outhour = datepart(hh,@daystop), @outminute = datepart(mi,@daystop)
		end

	/* reset outhour and outminute if the equipment was transferred out before the start of the day to prevent deflated hours */
	if @outhour < datepart(hh,@daystart) select @outhour = datepart(hh,@daystart), @outminute = datepart(mi,@daystart)
	if @outhour = datepart(hh,@daystart) and @outminute < datepart(mi,@daystart) select @outminute = datepart(mi,@daystart)
 
	/*ISSUE: #127253*/
	IF @IsDayStopMidnight <> 'Y'
		BEGIN
			/* reset outhour and outminute if the equipment was transferred out after the end of the day */
			if @outhour > datepart(hh,@daystop) select @outhour = datepart(hh,@daystop), @outminute = datepart(mi,@daystop)
			if @outhour = datepart(hh,@daystop) and @outminute > datepart(mi,@daystop) select @outminute = datepart(mi,@daystop)
		 
			/* add in the hours that it was on the job the last day */
			select @hours = @hours + ((@outhour - datepart(hh,@daystart)) 
				+ ((cast(@outminute as numeric(10,2)) - cast(datepart(mi,@daystart) as numeric(10,2))) / cast(60 as numeric(10,2))))	--Does Work w/out Cast since @outminute already cast bHrs
		END
	ELSE
		BEGIN
			-- DETERMINE NUMBER OF MINUTES FOR CALCULATION --
			SELECT	@DateOutMidNightMins = 
				CASE 
					WHEN @outminute = 0 THEN 0
					ELSE ((cast(@outminute as numeric(10,2)) - cast(datepart(mi,@daystart) as numeric(10,2))) / cast(60 as numeric(10,2)))	--Does Work w/out Cast since @inminute already cast bHrs
				END

			-- UPDATE HOURS --
			SET @hours = @hours + (@outhour - datepart(hh,@daystart)) + @DateOutMidNightMins
		END

	/**** proccess break times on partial day transfers ****/
	select @cnt = 1
	While @cnt <=3
	Begin
		if @cnt = 1
		begin
			if @br1start is not null and @br1stop is not null 
				begin
					select @breakstart = @br1start, @breakstop = @br1stop
				end
			else
				begin
					goto BreakOut
				end
		end
		if @cnt = 2
		begin
			if @br2start is not null and @br2stop is not null 
				begin
					select @breakstart = @br2start, @breakstop = @br2stop
				end
			else 
				begin
					goto BreakOut
				end
		end
		if @cnt = 3
		begin
			if @br3start is not null and @br3stop is not null 
				begin
					select @breakstart = @br3start, @breakstop = @br3stop 
				end
			else 
				begin
					goto BreakOut
				end
		END
		
		----TK-16429
		IF @breakstart IS NULL OR @breakstop IS NULL GOTO BreakIn
		SET @BreakEndDay = 'N'
		SET @BreakBegDay = 'N'
		IF (DATEPART(hh,@breakstart) +  DATEPART(mi,@breakstart)) = 0 SET @BreakBegDay = 'Y'
		IF (DATEPART(hh,@breakstop)  +  DATEPART(mi,@breakstop))  = 0 SET @BreakEndDay = 'Y'
				
		---- TK-14629 if transferred out after a break, subtract out the break time
		---- if break is end of day, cannot transfer out after
		if (@BreakEndDay = 'N'
			AND ((@outhour > DATEPART(hh,@breakstop))
			OR (@outhour = DATEPART(hh,@breakstop) AND @outminute > DATEPART(mi,@breakstop))))
			BEGIN
			select @hours = @hours - (DATEPART(hh,@breakstop) - DATEPART(hh,@breakstart)
				+ ((cast(DATEPART(mi,@breakstop) as numeric(10,2)) - cast(DATEPART(mi,@breakstart) as numeric(10,2))) 	--Does need to be Cast because of datepart(mi,@breakstart)
				/ cast(60 as numeric(10,2))))
			END

		---- TK-16429 if transferred out during a break, subtract out portion of the break
		if ((@outhour > DATEPART(hh,@breakstart))
			OR (@outhour = DATEPART(hh,@breakstart) AND @outminute > DATEPART(mi,@breakstart)))
			AND ((@outhour < DATEPART(hh,@breakstop))
			OR (@outhour = DATEPART(hh,@breakstop) AND @outminute <= datepart(mi,@breakstop))
			OR (@BreakEndDay = 'Y' AND @outhour < 24))
			BEGIN
			select @hours = @hours - ((@outhour - DATEPART(hh,@breakstart)) 
				+ ((cast(@outminute as numeric(10,2)) - cast(DATEPART(mi,@breakstart) as numeric(10,2))) 		--Does Work w/out Cast since @outminute already cast bHrs
				/ cast(60 as numeric(10,2))))
			END
 
		BreakOut:
		select @cnt = @cnt + 1
	End
END

---- if in/out is on the same day then subtract 1 day
IF @dateout = @datein 
	BEGIN
	----TK-16429
	IF @hrsperday IS NULL SET @hrsperday = 0
	IF @BreakStopMidnightMins IS NULL SET @BreakStopMidnightMins = 0
	SET @hours = @hours - @hrsperday + @BreakStopMidnightMins
end
--End Start Hours calculation 

--Return Total Billable hours
select @billablehours = isnull(@hours,0)

vspexit:

	return @rcode






GO
GRANT EXECUTE ON  [dbo].[vspEMBFAutoInsertCalcBillHours] TO [public]
GO
