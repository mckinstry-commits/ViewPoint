SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspPCPotentialProjectInit]
/***********************************************************
* CREATED BY:	CHS	08/25/2009
* MODIFIED BY:	GP	09/14/2009	- Fixed linear code to handle smaller decimals by using floats.
*				CHS 11/02/2009	- fixed problem with @revenueparts and @costparts they were too short and truncating.
*				CHS 11/11/2009	- Changed the way months in part is calculated in Curve method
*				
* USAGE:
* Used in PM Potential Projects to initialize form.
*
* INPUT PARAMETERS
*   JCCo   
*   PotentialProject 
*	beginpotentialproject
*	endpotentialproject
*
* OUTPUT PARAMETERS
*   @msg      Description of Department if found.
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 
(@jcco bCompany = 0, @initializeby char(1) = 'P', @beginpotentialproject varchar(20) = null, 
 @endpotentialproject varchar(20) = null, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @revenuemethod char(1), @revenueinterval varchar(10), @revenueparts varchar(60),
		@costmethod char(1), @costinterval varchar(10), @costparts varchar(60), 
		@numberofmonths int, @i int, @j int, @x int, @partnumber int, @maxseq int, @project varchar(20), 
		@startdate bDate, @enddate bDate, @revenueest bDollar, @costest bDollar, 
		@revenuepct float, @costpct float, @monthsinpart float, @nullparts int, 
		@remainpct numeric(12,2), @prevrevpct numeric(12,2), @prevcostpct numeric(12,2), 
		@mthinpartcounter float, @monthsinpartfloat float
			

-- holds the input data from vPCPotentialWork
declare @revenuetable table(Seq int identity(1,1), Co bCompany, Project varchar(20), StartDate bDate, EndDate bDate, RevenueAmount bDollar, CostAmount bDollar)
-- holds the output of calculated data to be inserted into vPCForecastMonth
declare @forecastmonth table(Co bCompany, Project varchar(20), Mth bDate, RevenuePct bPct, CostPct bPct)
-- for parsing the revenue parts
declare @parserevparttable table(Seq int identity(1,1), PartPct numeric(12,2))
-- for parsing the revenue parts
declare @parsecostparttable table(Seq int identity(1,1), PartPct numeric(12,2))

select @rcode = 0, @msg = ''

---- get revenue method, interval, and parts from JC Company Parameters
select @revenuemethod = CFRevMethod, @revenueinterval = CFRevInterval, @revenueparts = CFRevParts,
@costmethod = CFCostMethod, @costinterval = CFCostInterval, @costparts = CFCostParts
from dbo.bJCCO with (nolock) where JCCo=@jcco
---- validate company
if @@rowcount = 0
	begin
	select @msg = 'Company ' + @jcco + ' is not set up in JC Company file!', @rcode = 1
	goto bspexit
	end
	
---- validate that the initialize by flag has been supplied
if @initializeby is null
	begin	
	select @msg = 'Initialize by flag is not set!', @rcode = 1
	goto bspexit
	end	

---- validate beginning project value has been supplied
if @initializeby = 'P' and @beginpotentialproject is null
	begin	
	select @msg = 'Beginning project value is null!', @rcode = 1
	goto bspexit
	end	


---- if revenue method and cost method are both none exit
if @revenuemethod = 'N' and @costmethod = 'N' goto bspexit

---- check (C)urve method and if no parts defined assume linear
if @revenuemethod = 'C' and isnull(@revenueparts,'') = '' set @revenuemethod = 'L'
if @costmethod = 'C' and isnull(@costparts,'') = '' set @costmethod = 'L'

------------------------------------------------------------------
-- when initialize by flag is set to P get range based on project
if @initializeby = 'P'
	begin	
	-- validate beginning project
	select top 1 1 from dbo.PCPotentialWork with (nolock) where JCCo = @jcco and PotentialProject = @beginpotentialproject
	if @@rowcount = 0
		begin
		select @msg = 'Project ' + @beginpotentialproject + ' is not set up in PC Potential Work file!', @rcode = 1
		goto bspexit
		end

		insert into @revenuetable(Co, Project, StartDate, EndDate, RevenueAmount, CostAmount)
		select JCCo, PotentialProject, StartDate, CompletionDate, RevenueEst, CostEst
		from PCPotentialWork where JCCo = @jcco and PotentialProject >= @beginpotentialproject and PotentialProject <= @endpotentialproject 

	end

---------------------------------------------------------------------------
-- get project start date and end date
select @project = Project, @startdate = StartDate, @enddate = EndDate /*, @revenueest = RevenueAmount, @costest = CostAmount*/
from @revenuetable --where Seq = @i + 1

---------------------------------------------------------------------------
-- set date to always be the first of the month
select @startdate = cast (month(@startdate) as varchar) + '/1/' + cast (year(@startdate) as varchar)
select @enddate = cast (month(@enddate) as varchar) + '/1/' + cast (year(@enddate) as varchar)

---------------------------------------------------------------------------
-- months can never be less than one month
select @numberofmonths = datediff(month, @startdate, @enddate)
select @numberofmonths = isnull(@numberofmonths,0) + 1
--if @numberofmonths < 1 select @numberofmonths = 1


-- if # of intervals is greater than # of months then it will always be linear
if @revenueinterval > @numberofmonths 	select @revenuemethod = 'L', @costmethod = 'L'


---------------------------------------------------------------------------
--								R E V E N U E
---------------------------------------------------------------------------
-- when revenue method flag is set to L calculate using linear method
---------------------------------------------------------------------------
if @revenuemethod = 'L'
	begin	

		set @revenuepct = 0
		set @x = 0
		while(@numberofmonths > @x)
			begin

			set @revenuepct = @revenuepct + (1 / cast(@numberofmonths as float))

			insert into @forecastmonth(Co, Project, Mth, RevenuePct, CostPct)
			select @jcco, @project, dateadd(month, @x, @startdate), @revenuepct, 0

			set @x = @x + 1
			end	

		-- should be at the last record - so set it 100% 
		update @forecastmonth set RevenuePct = 1
		where Co = @jcco and Project = @project and Mth = dateadd(month, @x-1, @startdate)

		select @revenuepct = 0, @costpct = 0

	end	
	
		print @revenueparts

---------------------------------------------------------------------------
--		when revenue method flag is set to C calculate using curve method
---------------------------------------------------------------------------
if @revenuemethod = 'C'
	begin	

	-- insert first percent if null the then assume 0
	if substring(@revenueparts, 1, 1) = ':'
		begin 
		select @revenueparts = '0' + @revenueparts
		end 
		
	-- insert trailing semicolon
	if (substring(@revenueparts,len(@revenueparts), 1) <> ':') and (substring(@revenueparts,len(@revenueparts)-2, 3) <> '100')
		begin 
		select @revenueparts = @revenueparts + ':'
		end 

	-- parse revenue interval
	set @prevrevpct = 0
	set @j = 0
	while (@j < @revenueinterval)
		begin	

		insert into @parserevparttable(PartPct)
		select isnull(cast(substring(@revenueparts, 0, patindex('%:%',@revenueparts)) as int),0)
		
		select @revenueparts = substring(@revenueparts, patindex('%:%', @revenueparts)+1, len(@revenueparts))

		set @j = @j + 1
		end	

	-- the last entry is always going to be 100%
	update @parserevparttable
	set PartPct = 100
	where Seq = @j

	-- set counters
	set @partnumber = 1
	
	-- set @monthscounter = 1
	set @mthinpartcounter = 1
	
	-- set the number of months in the first part
	select @monthsinpart = cast(@numberofmonths as float)  /  cast(@revenueinterval as float)
	
	-- set loop counters
	set @revenuepct = 0
	set @x = 0
	while(@numberofmonths > @x)
		begin
		select @prevrevpct = isnull(PartPct,0) from @parserevparttable where Seq = @partnumber - 1

		select @revenuepct = @revenuepct + ((PartPct-@prevrevpct) / ceiling(@monthsinpart) ) from @parserevparttable where Seq = @partnumber

		insert into @forecastmonth(Co, Project, Mth, RevenuePct, CostPct )
		select @jcco, @project, dateadd(month, @x, @startdate), (@revenuepct*.01), 0

		-- increment to next month
		set @x = @x + 1
		
		-- increment months counter
		set @mthinpartcounter = @mthinpartcounter + 1

		if @mthinpartcounter > ceiling(@monthsinpart)
			begin	
			
			-- don't do anything if we are in the last
			if @numberofmonths > @x
				begin
				select @monthsinpart = cast((@numberofmonths - @x) as float) / cast((@revenueinterval - @partnumber) as float)
				
				-- force it to round to the designated percentage
				update @forecastmonth set RevenuePct = (select (PartPct *.01) from @parserevparttable where Seq = @partnumber)
				where Co = @jcco and Project = @project and Mth = dateadd(month, @x-1, @startdate)

				-- increment to next part
				if (@revenueinterval > @partnumber) set @partnumber = @partnumber + 1

				-- set @monthscounter = 1		
				set @mthinpartcounter = 1
				set @prevrevpct = 0		
								
				end	

			end		

		end	

	-- should be at the last record - so set it 100% 
	update @forecastmonth set RevenuePct = 1
	where Co = @jcco and Project = @project and Mth = dateadd(month, @x-1, @startdate)

	select @revenuepct = 0, @costpct = 0
	end	

---------------------------------------------------------------------------
--								C O S T
---------------------------------------------------------------------------
--		when cost method flag is set to L calculate using linear method
---------------------------------------------------------------------------
if @costmethod = 'L'
	begin	

	set @costpct = 0
	set @x = 0
	while(@numberofmonths > @x)
		begin
			set @costpct = @costpct + (1 / cast(@numberofmonths as float))

			update @forecastmonth set CostPct = @costpct
			where Co = @jcco and Project = @project and Mth = dateadd(month, @x, @startdate)

			set @x = @x + 1
		end	

	-- should be at the last record - so set it 100% 
	update @forecastmonth set CostPct = 1
	where Co = @jcco and Project = @project and Mth = dateadd(month, @x-1, @startdate)

	select @costpct = 0
	end	


---------------------------------------------------------------------------
--		when revenue method flag is set to C calculate using curve method
---------------------------------------------------------------------------
if @costmethod = 'C'
	begin	

	-- insert first percent if null the then assume 0
	if substring(@costparts, 1, 1) = ':'
		begin 
		select @costparts = '0' + @costparts
		end 

	-- insert trailing semicolon
	if (substring(@costparts,len(@costparts), 1) <> ':') and (substring(@costparts,len(@costparts)-2, 3) <> '100')
		begin 
		select @costparts = @costparts + ':'
		end 

	-- parse cost interval
	set @prevcostpct = 0
	set @j = 0
	while (@j < @costinterval)
		begin	

		insert into @parsecostparttable(PartPct)
		select isnull(cast(substring(@costparts, 0, patindex('%:%',@costparts)) as int),0)

		select @costparts = substring(@costparts, patindex('%:%', @costparts)+1, len(@costparts))

		set @j = @j + 1
		end	

	-- the last entry is always going to be 100%
	update @parsecostparttable
	set PartPct = 100
	where Seq = @j

	-- set counters
	set @partnumber = 1
	set @mthinpartcounter = 1
	
	--set the number of months in the first part
	select @monthsinpart = cast(@numberofmonths as float)  /  cast(@costinterval as float)
	
	--set loop counters
	set @costpct = 0
	set @x = 0
	
	while(@numberofmonths > @x)
		begin	
		select @prevcostpct = isnull(PartPct,0) from @parsecostparttable where Seq = @partnumber -1

		select @costpct = @costpct + ((PartPct-@prevcostpct) / ceiling(@monthsinpart) ) from @parsecostparttable where Seq = @partnumber
			
		update @forecastmonth set CostPct = (@costpct*.01)
		where Co = @jcco and Project = @project and Mth = dateadd(month, @x, @startdate)

		-- increment to next month
		set @x = @x + 1
		
		-- increment months counter		
		set @mthinpartcounter = @mthinpartcounter + 1

		if @mthinpartcounter > ceiling(@monthsinpart)
			begin	
			
			-- don't do anything if we are in the last
			if @numberofmonths > @x
				begin
				select @monthsinpart = cast((@numberofmonths - @x) as float) / cast((@costinterval - @partnumber) as float)
								
				-- force it to round to the designated percentage
				update @forecastmonth set CostPct = (select (PartPct *.01) from @parsecostparttable where Seq = @partnumber)
				where Co = @jcco and Project = @project and Mth = dateadd(month, @x-1, @startdate)

				-- increment to next part
				if (@costinterval > @partnumber) set @partnumber = @partnumber + 1

				--set @monthscounter = 1		
				set @mthinpartcounter = 1
				set @prevcostpct = 0					
				end						
				
			end		

		end	

	-- should be at the last record - so set it 100% 
	update @forecastmonth set CostPct = 1
	where Co = @jcco and Project = @project and Mth = dateadd(month, @x-1, @startdate)

	select @costpct = 0
	end	



/*-------------------------------------------------
	dump table variable to table vPCForecastMonth
--------------------------------------------------*/
-- delete prior entries in the table
delete from vPCForecastMonth where JCCo=@jcco and PotentialProject=@project

-- insert new entries in the table
insert into vPCForecastMonth(JCCo, PotentialProject, ForecastMonth, RevenuePct, CostPct)
select Co, Project, Mth, RevenuePct, CostPct  
	from @forecastmonth
	where Co=@jcco and Project=@project




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPCPotentialProjectInit] TO [public]
GO
