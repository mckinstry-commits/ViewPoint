SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspJCForecastInitialize]
/***********************************************************
* CREATED BY:	GP	09/03/2009	- Issue #129897
* MODIFIED BY:	GP	09/21/2009	- removed half of the code, merged contract and project manager
*				CHS 11/11/2009	- Changed the way months in part is calculated in Curve method
*				GF 09/10/2010 - issue #141031 change to use vfDateOnly
*				GF 04/25/2011 - issue #143875 D-01713
*				
* USAGE:
* Used in JC Contract master to initialize Forecast by Month tab.
*
* INPUT PARAMETERS
*   JCCo   
*   Inititalize By (C-Contract, M-Manager) 
*	Re-initialize
*	InitPending
*	InitOpen
*	InitSoft
*	InitHard
*	Begin Contract
*	End Contract
*	Project Manager
*
* OUTPUT PARAMETERS
*   @msg      Description of Department if found.
*
* RETURN VALUE
*   0         Success
*   1         Failure
*****************************************************/ 
(@JCCo bCompany = null, @InitializeBy char(1) = null, @ReInit bYN = null, @FutureMonths tinyint = null,
	@InitPending char(1) = null, @InitOpen char(2) = null, @InitSoft char(1) = null, @InitHard char(1) = null,
	@BeginContract bContract = null, @EndContract bContract = null, @ProjectMgr bProjectMgr = null,
	@msg varchar(255) output)
as
set nocount on

declare @rcode int, @RevMethod char(1), @RevInterval tinyint, @RevParts varchar(30), @CostMethod char(1),
	@CostInterval tinyint, @CostParts varchar(30), @OrigRevMethod char(1), @OrigCostMethod char(1), @i int, @x int, @j int,
	@CurrContract bContract, @CurrStartDate bDate, @CurrEndDate bDate, @CurrRevPct float, @CurrMonth bDate,
	@TotalMonths int, @MonthsInPart float, @RevMonth bDate, @TotalRevPct float, @MonthsInPartEdit int,
	@CurrCostPct float, @TotalCostPct float, @PrevRevPct float, @PrevCostPct float, @PartNo int, @MonthCounter int,
	@EndMonth smalldatetime
	
select @rcode = 0, @msg = ''

set @EndMonth = null
----#141031
if isnull(@FutureMonths, '') <> '' set @EndMonth = dateadd(month, @FutureMonths, dbo.vfDateOnly())



-- Table Variables --
declare @ContractInit table(Seq int identity(1,1), JCCo bCompany, Contract bContract, StartDate bDate, EndDate bDate, Status tinyint)
declare @Forecast table(Seq int identity(1,1), JCCo bCompany, Contract bContract, Month bMonth, RevPct bPct null, CostPct bPct null)
declare @RevPartsTable table(Part tinyint, Pct float)
declare @CostPartsTable table(Part tinyint, Pct float)

-- Get Forecast Method Details --
select @OrigRevMethod = CFRevMethod, @RevInterval = CFRevInterval, @RevParts = CFRevParts,
@OrigCostMethod = CFCostMethod, @CostInterval = CFCostInterval, @CostParts = CFCostParts
from dbo.JCCO with (nolock) where JCCo=@JCCo
if @@rowcount = 0 goto vspexit

if @OrigRevMethod = 'N' and @OrigCostMethod = 'N' goto vspexit

---- check (C)urve method and if no parts defined assume linear
if @OrigRevMethod = 'C' and isnull(@RevParts,'') = '' set @OrigRevMethod = 'L'
if @OrigCostMethod = 'C' and isnull(@CostParts,'') = '' set @OrigCostMethod = 'L'

-- Convert ContractStatus from bYN to tinyint
if @InitPending = 'Y' set @InitPending = 0 else set @InitPending = 9
if @InitOpen = 'Y' set @InitOpen = 1 else set @InitOpen = 9
if @InitSoft = 'Y' set @InitSoft = 2 else set @InitSoft = 9
if @InitHard = 'Y' set @InitHard = 3 else set @InitHard = 9

-- Populate Revenue Parts Table
if substring(@RevParts, 1, 1) = ':' set @RevParts = '0' + @RevParts
if substring(@RevParts, len(@RevParts), 1) <> ':' set @RevParts = @RevParts + ':'
set @x = 1
while @x <= @RevInterval
begin
	if @RevParts <> ''
	begin
		insert into @RevPartsTable(Part, Pct)
		select @x, substring(@RevParts, 0, patindex('%:%',@RevParts))
	end
	else
	begin
		insert into @RevPartsTable(Part, Pct)
		select @x, 100
	end
	
	select @RevParts = substring(@RevParts, patindex('%:%', @RevParts)+1, len(@RevParts))

	set @x = @x + 1
end

-- Populate Cost Parts Table
if substring(@CostParts, 1, 1) = ':' set @CostParts = '0' + @CostParts
if substring(@CostParts, len(@CostParts), 1) <> ':' set @CostParts = @CostParts + ':'
set @x = 1
while @x <= @CostInterval
begin
	if @CostParts <> ''
	begin
		insert into @CostPartsTable(Part, Pct)
		select @x, substring(@CostParts, 0, patindex('%:%',@CostParts))
	end
	else
	begin
		insert into @CostPartsTable(Part, Pct)
		select @x, 100
	end
	
	select @CostParts = substring(@CostParts, patindex('%:%', @CostParts)+1, len(@CostParts))

	set @x = @x + 1
end

-- Fill @Forecast by Contract Range
if @InitializeBy = 'C'
begin
	if @ReInit = 'Y'
	begin
		insert into @ContractInit(JCCo, Contract, StartDate, EndDate, Status)
		select JCCo, Contract, StartMonth, isnull(ProjCloseDate, (isnull(@EndMonth, StartMonth))), ContractStatus
		from dbo.JCCM with (nolock)
		where JCCo = @JCCo and Contract >= @BeginContract and Contract <= @EndContract
		AND MonthClosed IS NULL and ContractStatus in (@InitPending, @InitOpen, @InitSoft, @InitHard)
	end
	else
	begin
		insert into @ContractInit(JCCo, Contract, StartDate, EndDate, Status)
		select m.JCCo, m.Contract, m.StartMonth, isnull(m.ProjCloseDate, (isnull(@EndMonth, StartMonth))), 
			m.ContractStatus
		from dbo.JCCM m with (nolock) 
		where m.JCCo = @JCCo and m.Contract >= @BeginContract and m.Contract <= @EndContract
		AND MonthClosed IS NULL and m.ContractStatus in (@InitPending, @InitOpen, @InitSoft, @InitHard)
		and not exists(select top 1 1 from dbo.JCForecastMonth f with (nolock) where f.JCCo = m.JCCo and f.Contract = m.Contract)
	end
end			

-- Fill @Forecast by Project Manager
if @InitializeBy = 'P'
begin
	if @ReInit = 'Y'
	begin
		insert into @ContractInit(JCCo, Contract, StartDate, EndDate, Status)
		select distinct c.JCCo, c.Contract, c.StartMonth, isnull(c.ProjCloseDate, (isnull(@EndMonth, StartMonth))), c.ContractStatus
		from dbo.JCJM j with (nolock)	
		join dbo.JCCM c with (nolock) on c.JCCo=j.JCCo and c.Contract=j.Contract
		where j.JCCo = @JCCo and j.ProjectMgr = @ProjectMgr
		AND MonthClosed IS NULL and ContractStatus in (@InitPending, @InitOpen, @InitSoft, @InitHard)
	end
	else
	begin
		insert into @ContractInit(JCCo, Contract, StartDate, EndDate, Status)
		select distinct c.JCCo, c.Contract, c.StartMonth, isnull(c.ProjCloseDate, (isnull(@EndMonth, StartMonth))), c.ContractStatus
		from dbo.JCJM j with (nolock)	
		join dbo.JCCM c with (nolock) on c.JCCo=j.JCCo and c.Contract=j.Contract
		where j.JCCo = @JCCo and j.ProjectMgr = @ProjectMgr
		AND MonthClosed IS NULL and ContractStatus in (@InitPending, @InitOpen, @InitSoft, @InitHard)
			and not exists(select top 1 1 from dbo.JCForecastMonth f with (nolock) where f.JCCo = c.JCCo and f.Contract = c.Contract)
	end
end			
			
-- Clean up EndDate where day is not 1		
update @ContractInit
set EndDate = cast(month(EndDate) as varchar) + '/1/' + cast(year(EndDate) as varchar)
where day(EndDate) <> 1

-- Loop through each Contract
set @i = 1
while @i <= (select max(Seq) from @ContractInit)
begin	
	select @CurrContract=Contract, @CurrStartDate=StartDate, @CurrEndDate=EndDate from @ContractInit where Seq = @i
	select @TotalMonths = datediff(month, @CurrStartDate, @CurrEndDate)
	select @TotalMonths = isnull(@TotalMonths, 0) + 1	
	
	-- make linear if intervals is greater than months
	if @RevInterval > @TotalMonths select @RevMethod = 'L', @CostMethod = 'L'
	else select @RevMethod = @OrigRevMethod, @CostMethod = @OrigCostMethod

	if @RevMethod = 'C'
	begin	
		-- set counters
		set @PartNo = 1
		
		set @MonthCounter = 1
		set @CurrRevPct = 0
		set @PrevRevPct = 0
		set @x = 0
		
			
		-- set the number of months in the first part
		select @MonthsInPart = cast(@TotalMonths as float)  /  cast(@RevInterval as float)
		
		while(@TotalMonths > @x)
		begin
			select @PrevRevPct = isnull(Pct, 0) from @RevPartsTable where Part = @PartNo - 1

			select @CurrRevPct = (@CurrRevPct + ((Pct - @PrevRevPct) / ceiling(@MonthsInPart)) * .01) from @RevPartsTable where Part = @PartNo

			insert into @Forecast(JCCo, Contract, Month, RevPct, CostPct)
			select @JCCo, @CurrContract, dateadd(month, @x, @CurrStartDate), @CurrRevPct, 0

			-- increment @x - next month
			set @x = @x + 1
			
			-- increment MonthCounter
			set @MonthCounter = @MonthCounter + 1

			if @MonthCounter > ceiling(@MonthsInPart)
				begin	
			
				-- don't do anything if we are in the last
				if @TotalMonths > @x
					begin
					
					select @MonthsInPart = cast((@TotalMonths - @x) as float)  /  cast((@RevInterval - @PartNo) as float)
							
					-- force it to round to the designated percentage
					update @Forecast set RevPct = (select (Pct * .01) from @RevPartsTable where Part = @PartNo)
					where JCCo = @JCCo and Contract = @CurrContract and Month = dateadd(month, @x - 1, @CurrStartDate)

					-- increment to next part
					if (@RevInterval > @PartNo) set @PartNo = @PartNo + 1

					set @MonthCounter = 1		
					set @PrevRevPct = 0	
										
					end	
	
				end	
					
		end		
		
		-- should be at the last record - so set it 100% 
		update @Forecast set RevPct = 1
		where JCCo = @JCCo and Contract = @CurrContract and Month = dateadd(month, @x - 1, @CurrStartDate)
		
		select @CurrRevPct = 0		
	end

	if @RevMethod = 'L'
	begin
		select @CurrContract=Contract, @CurrStartDate=StartDate, @CurrEndDate=EndDate from @ContractInit where Seq = @i
		select @TotalMonths = datediff(month, @CurrStartDate, @CurrEndDate)
		select @TotalMonths = isnull(@TotalMonths, 0) + 1	
		
		set @x = 0
		set @TotalRevPct = 0
		while @x < @TotalMonths
		begin
			set @CurrRevPct = 1 / cast(@TotalMonths as float)
			set @TotalRevPct = @TotalRevPct + @CurrRevPct
			set @CurrMonth = dateadd(month, @x, @CurrStartDate)

			insert into @Forecast(JCCo, Contract, Month, RevPct, CostPct)
			select @JCCo, @CurrContract, @CurrMonth, @TotalRevPct, null
			
			set @x = @x + 1
		end
	end	

	if @CostMethod = 'C'
	begin
		set @PartNo = 1
		
		set @MonthCounter = 1
		set @CurrCostPct = 0
		set @PrevCostPct = 0
		set @x = 0
		
		-- set the number of months in the first part
		select @MonthsInPart = cast(@TotalMonths as float)  /  cast(@CostInterval as float)
		
		while(@TotalMonths > @x)
		begin
			select @PrevCostPct = isnull(Pct, 0) from @CostPartsTable where Part = @PartNo - 1
			
			select @CurrCostPct = (@CurrCostPct + ((Pct - @PrevCostPct) / ceiling(@MonthsInPart)) * .01) from @CostPartsTable where Part = @PartNo

			update @Forecast set CostPct = @CurrCostPct
			where JCCo = @JCCo and Contract = @CurrContract and Month = dateadd(month, @x, @CurrStartDate)

			-- increment @x - next month
			set @x = @x + 1
			
			-- increment MonthCounter
			set @MonthCounter = @MonthCounter + 1

			if @MonthCounter > ceiling(@MonthsInPart)
				begin	
							
				-- don't do anything if we are in the last
				if @TotalMonths > @x
					begin
					
					select @MonthsInPart = cast((@TotalMonths - @x) as float)  /  cast((@CostInterval - @PartNo) as float)
										
					-- force it to round to the designated percentage
					update @Forecast set CostPct = (select (Pct * .01) from @CostPartsTable where Part = @PartNo)
					where JCCo = @JCCo and Contract = @CurrContract and Month = dateadd(month, @x - 1, @CurrStartDate)

					-- increment to next part
					if (@CostInterval > @PartNo) set @PartNo = @PartNo + 1

					set @MonthCounter = 1
					set @PrevCostPct = 0					
					end
					
				end			
				
		end		
		
		-- should be at the last record - so set it 100% 
		update @Forecast set CostPct = 1
		where JCCo = @JCCo and Contract = @CurrContract and Month = dateadd(month, @x - 1, @CurrStartDate)
		
		select @CurrCostPct = 0
	end

	if @CostMethod = 'L'
	begin
		select @CurrContract=Contract, @CurrStartDate=StartDate, @CurrEndDate=EndDate from @ContractInit where Seq = @i
		select @TotalMonths = datediff(month, @CurrStartDate, @CurrEndDate)
		select @TotalMonths = isnull(@TotalMonths, 0) + 1	
		
		set @x = 0
		set @TotalCostPct = 0
		while @x < @TotalMonths
		begin
			set @CurrCostPct = 1 / cast(@TotalMonths as float)
			set @TotalCostPct = @TotalCostPct + @CurrCostPct
			set @CurrMonth = dateadd(month, @x, @CurrStartDate)

			update @Forecast
			set CostPct = @TotalCostPct
			where Month = @CurrMonth and Contract = @CurrContract
			
			set @x = @x + 1
		end
	end	

	set @i = @i + 1 --contract counter
end --end contract loop


--------------------
-- INSERT RECORDS --
--------------------
set @i = 1
while @i <= (select max(Seq) from @ContractInit)
begin	
	select @CurrContract = Contract from @ContractInit where Seq = @i

	-- make sure records exist to insert before delete/insert
	if exists(select top 1 1 from @Forecast where Contract = @CurrContract)
	begin
		-- Delete vJCForecastMonth
		delete vJCForecastMonth
		where Contract = @CurrContract
	
		-- Insert vJCForecastMonth
		insert into vJCForecastMonth(JCCo, Contract, ForecastMonth, RevenuePct, CostPct)
		----D-01713 ISSUE #143875
		select JCCo, Contract, Month, ISNULL(RevPct,0), ISNULL(CostPct,0) 
		from @Forecast where Contract = @CurrContract
	end
	
	set @i = @i + 1 --contract counter
end

-- Set success message
set @msg = 'Forecast successfully initialized!'


vspexit:
	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspJCForecastInitialize] TO [public]
GO
