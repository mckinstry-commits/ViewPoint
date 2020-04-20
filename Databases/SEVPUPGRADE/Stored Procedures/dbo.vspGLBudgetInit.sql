SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[vspGLBudgetInit]
/****************************************************************************************
* Created: GG 09/14/06 - written for VP6.0, replaces bspGLBudgetInit, bspGLBudgetAdjustAnnually,
*				bspGLBudgetAdjustMonthly, bspGLBudgetAdjustQuarterly
* Modified:	GP 05/06/09 - 126199 Added option to include source budget notes.
*           FT 03/23/11 - 140921/D-01069 Modified per Eric Anderson's notes
*
* Used by GL Budget Initialization form to create budget amounts.  Replaces
* or addes entries in GL Budget Revision (bGLBR) and GL Budget Detail (bGLBD)
* 
* Input Params:
*   @glco				GL Company
*   @tofyemo			Fiscal year we are initializing
*   @tobudgetcode		Budget code we are initializing
*   @glacctmask			GL Account mask formatted like a GL Account
*   @basedon			1 = actuals, 2 = budgets, 3 = monthly, 4 = quarterly, 5 = annual amounts
*   @sourcefyemo		Fiscal Year ending month to initialize budgets from
*   @sourcebudgetcode	Budget Code to initialize from if based on budget amts
*   @modifyby			'P' = modify by percent, 'A' = modify by amount
*   @modifyvalue		Percent or fixed amount to increase the budget by
*	@mthlyamt			Monthly budget amount (credit < 0)
*	@qtr1amt			1st Qtr budget amount (credit < 0)
*	@qtr2amt			2nd Qtr budget amount (credit < 0)
*	@qtr3amt			3rd Qtr budget amount (credit < 0)
*	@qtr4amt			4th Qtr budget amount (credit < 0)
*	@annualamt			Annual budget amount (credit < 0)
*
* Output Params:
*	@msg				if successful, message reporting # of GL Accounts initialized 
*						or if failure, error message
* Return code:
*	0 = success
*	1 = failure
*************************************************************************************/
   	(@glco bCompany = null, @tofyemo bMonth = null, @tobudgetcode bBudgetCode = null, @glacctmask bGLAcct = null,
	 @basedon tinyint = 0, @sourcefyemo bMonth = null, @sourcebudgetcode bBudgetCode = null, @modifyby char(1) = null,
	 @modifyvalue real = 0, @mthlyamt bDollar = 0, @qtr1amt bDollar = 0, @qtr2amt bDollar = 0, @qtr3amt bDollar = 0,
	 @qtr4amt bDollar = 0, @annualamt bDollar = 0, @InitNotes bYN, @msg varchar(255) output)
   
as
set nocount on

declare @datediff smallint, @rcode tinyint, @rows integer, @i int, @a char(1),
	@masklen int, @sourcemask varchar(20), @amt bDollar, @pct bPct, @mth bMonth,
	@bmth bMonth, @mths tinyint, @tablecreated tinyint, @lastmthamt bDollar

select @rcode = 0, @rows = 0, @tablecreated = 0

--validate GL company 
if not exists(select 1 from dbo.bGLCO with (nolock) where GLCo = @glco)
	begin
 	select @msg = 'Invalid GL Company!', @rcode = 1
	goto vspexit
	end
--validate Fiscal Year to initialize
select @bmth = BeginMth
from dbo.bGLFY with (nolock)
where GLCo = @glco and FYEMO = @tofyemo
if @@rowcount = 0
	begin
 	select @msg = 'Invalid Fiscal Year to initialize!', @rcode = 1
	goto vspexit
	end
select @mths = datediff(month, @bmth, @tofyemo) + 1	-- # of months in fiscal year

--validate Budget Code to initialize
if not exists(select 1 from dbo.bGLBC with (nolock) where GLCo = @glco and BudgetCode = @tobudgetcode)
	begin
	select @msg = 'Invalid Budget Code to initialize!', @rcode = 1
	goto vspexit
	end

--check Beginning and Ending GL Accounts masks
if @glacctmask is null
	begin
	select @msg = 'Must provide a GL Account or mask!', @rcode = 1
	goto vspexit
	end

--validate initialization option
if @basedon not in(1,2,3,4,5)
	begin
	select @msg = 'Initialization must be based on a valid option!', @rcode = 1
	goto vspexit
	end

--validate source FYEMO
if @basedon in (1,2)		-- based on actuals or budgets
	begin
	if not exists(select 1 from dbo.bGLFY with (nolock) where GLCo = @glco and FYEMO = @sourcefyemo)
		begin
		select @msg = 'Not based on a valid Fiscal Year!', @rcode = 1
		goto vspexit
		end
	end

if @basedon = 2	-- make sure Budget Revision exists if based on existing budgets
   	begin
   	if not exists(select 1 from dbo.bGLBR with (nolock) where GLCo = @glco and FYEMO = @sourcefyemo
   		and BudgetCode = @sourcebudgetcode)
   		begin
   		select @msg = 'No Revisions exist for this Fiscal Year and Budget Code!', @rcode = 1
   		goto vspexit
   		end
   	end

if @basedon = 4 and @mths <> 12
	begin
	select @msg = 'Quarterly budgeting requires a 12 month fiscal year!', @rcode = 1
	goto vspexit
	end
   
--get # of months between fiscal year ends 
if @sourcefyemo is not null select @datediff = datediff(month, @sourcefyemo, @tofyemo)
  	
--create a temp table with the months we need to initialize
create table #Mths(Co tinyint NOT NULL, Mth smalldatetime NOT NULL)
--set temp table creation flag
select @tablecreated = 1
--insert all months in 'to' fiscal year into temp table 
select @mth = @bmth
while @mth <= @tofyemo
	begin
   	insert #Mths(Co, Mth) values (@glco, @mth) 
    select @mth = dateadd(mm,1,@mth)
 	end

--convert GL Account Mask
select @masklen = datalength(@glacctmask), @i = 1
while @i <= @masklen
	begin
	select @a = substring(@glacctmask,@i,1)
	/* replace ? with _ */
	if @a = '?' select @glacctmask = stuff(@glacctmask,@i,1,'_')
	select @i = @i + 1
	end

-- initialization replaces existing budget info so remove any existing Monthly Budget Detail entries
delete dbo.bGLBD
from dbo.bGLBD b
join #Mths m on m.Co = b.GLCo and m.Mth = b.Mth
where b.GLCo = @glco and b.GLAcct like @glacctmask and b.BudgetCode = @tobudgetcode


/************ start budget initialization ***************/

if @basedon in (1,2)	-- based on Actuals or Budgets
	begin
	--set modify by amount and percent values 
	if @modifyby = 'P' select @amt = 0, @pct = @modifyvalue
	if @modifyby = 'A'  select @amt = @modifyvalue, @pct = 0
  
	-- remove existing Fiscal Year Budget Revision entries (only done when initializing based on Actuals or Budgets)
	delete dbo.bGLBR
	where GLCo = @glco and FYEMO = @tofyemo and BudgetCode = @tobudgetcode and GLAcct like @glacctmask
  
	if @basedon = 1	-- initializing from Actuals 
		begin
		-- add Fiscal Year Budget Revision entries, set Budget Begin Balance to zero
   		insert dbo.bGLBR (GLCo, FYEMO, BudgetCode, GLAcct, Notes, BeginBalance)	
   		select @glco, @tofyemo, @tobudgetcode, GLAcct, null, 0
   		from dbo.bGLAC 	-- init all accounts
   		where GLCo = @glco and GLAcct like @glacctmask and Active = 'Y' and AcctType <> 'H'  -- skip inactive and heading accounts
	   	
   		select @rows = @@rowcount	-- save number of accounts initialized	

		-- add Mthly Budget Detail, set Budget Amount based on Net Activity
		insert dbo.bGLBD (GLCo, GLAcct, BudgetCode, Mth, BudgetAmt)
		select @glco, a.GLAcct, @tobudgetcode, m.Mth,
       	case sign(isnull(l.NetActivity,0))
           	when  1 then (l.NetActivity + @amt + (l.NetActivity * @pct))	-- debit balance
               when -1 then (l.NetActivity - @amt + (l.NetActivity * @pct))	-- credit balance
               when  0 then (@amt * (case a.NormBal when 'C' then -1 else 1 end))  -- add or subtract amount based on normal balance
   			else 0 end
   		from dbo.bGLAC a (nolock)
   		join #Mths m on a.GLCo = m.Co
   		left join dbo.bGLBL l on a.GLCo = l.GLCo and a.GLAcct = l.GLAcct	-- use outer join to init all accounts
   			and	dateadd(month,@datediff,l.Mth) = m.Mth
		where a.GLCo = @glco and a.GLAcct like @glacctmask and a.Active='Y' and a.AcctType <> 'H' -- exclude inactive and heading accounts
   		end
   
	if @basedon = 2	-- initializing from Budgets
   		begin
		-- add Fiscal Year Budget Revision entries, set Budget Begin Balance based source year and budget code
   		insert dbo.bGLBR (GLCo, FYEMO, BudgetCode, GLAcct, Notes, BeginBalance)	
   		select @glco, @tofyemo, @tobudgetcode, a.GLAcct, null,
   			case sign(isnull(b.BeginBalance,0))
   				when 1 then (b.BeginBalance + @amt + (b.BeginBalance * @pct))	-- debit balance
   				when -1 then (b.BeginBalance - @amt + (b.BeginBalance * @pct))	-- credit balance		
   				when 0 then (@amt * (case a.NormBal when 'C' then -1 else 1 end)) -- add or subtract amount based on normal balance
   				else 0
   				end
   		from dbo.bGLAC a (nolock)
   		join dbo.bGLBR b on b.GLCo = a.GLCo and b.GLAcct = a.GLAcct	-- use equal join to only init accounts with source budgets
   		where a.GLCo = @glco and a.GLAcct like @glacctmask and a.Active = 'Y' and a.AcctType <> 'H'  -- skip inactive and heading accounts
   			and b.FYEMO = @sourcefyemo and b.BudgetCode = @sourcebudgetcode
   
   		select @rows = @@rowcount	-- save number of Accounts initialized

		-- add Mthly Budget Detail, set Budget Amount based on existing Budgets
   		insert dbo.bGLBD (GLCo, GLAcct, BudgetCode, Mth, BudgetAmt)
   		select @glco, a.GLAcct, @tobudgetcode, m.Mth,
   		case sign(isnull(b.BudgetAmt,0))
   			when 1 then (b.BudgetAmt + @amt + (b.BudgetAmt * @pct))	-- debit balance
   			when -1 then (b.BudgetAmt - @amt + (b.BudgetAmt * @pct)) -- credit balance
   			when 0 then (@amt * (case a.NormBal when 'C' then -1 else 1 end)) -- add or subtract amount based on normal balance
   			else 0
   			end
   		from dbo.bGLAC a
   		join #Mths m on a.GLCo = m.Co
   		join dbo.bGLBD b on a.GLCo = b.GLCo and a.GLAcct = b.GLAcct -- use equal join to only init accounts with source budgets
   			and b.BudgetCode = @sourcebudgetcode and dateadd(month,@datediff,b.Mth) = m.Mth
		where a.GLCo = @glco and a.GLAcct like @glacctmask and a.Active='Y' and a.AcctType <> 'H' -- exclude inactive and heading accounts
   		end
   		
		--126199 Add option to include source budget notes.
		if @InitNotes = 'Y'
		begin
			--update dbo.bGLBR
			--set Notes = (select Notes from dbo.bGLBR with (nolock) where GLCo = @glco and FYEMO = @sourcefyemo
				--and BudgetCode = @sourcebudgetcode and GLAcct like @glacctmask)
			--where GLCo = @glco and FYEMO = @tofyemo and BudgetCode = @tobudgetcode and GLAcct like @glacctmask
			
			-- Start of VP Support temp fix (written by Eric Anderson)
			declare @glacct bGLAcct
			declare cGLAcct cursor for
			select GLAcct from bGLBR where GLCo = @glco and FYEMO = @tofyemo and BudgetCode = @tobudgetcode and GLAcct like @glacctmask
			open cGLAcct
			fetch next from cGLAcct into @glacct
			while @@fetch_status = 0
			begin
			  update dbo.bGLBR set Notes = (select Notes from dbo.bGLBR with (nolock) where GLCo = @glco and FYEMO = @sourcefyemo and
			  BudgetCode = @sourcebudgetcode and GLAcct = @glacct) where GLCo = @glco and FYEMO = @tofyemo and BudgetCode = @tobudgetcode and
			  GLAcct = @glacct
			  fetch next from cGLAcct into @glacct
			end
			close cGLAcct
			deallocate cGLAcct
			-- End of VP Support temp fix         

		end   		 		
	end

if @basedon in (3,4,5)	-- based on Mthly, Quarterly, or Annual amounts
	begin
	-- add Budget Revision entries only as needed
	insert dbo.bGLBR (GLCo, FYEMO, BudgetCode, GLAcct, Notes, BeginBalance)	
   	select @glco, @tofyemo, @tobudgetcode, a.GLAcct, null, 0
   	from dbo.bGLAC a 	
   	where a.GLCo = @glco and a.GLAcct like @glacctmask and a.Active = 'Y' and a.AcctType <> 'H'  -- skip inactive and heading accounts
		and not exists(select 1 from dbo.bGLBR b where b.GLCo = a.GLCo and b.GLAcct = a.GLAcct and b.FYEMO = @tofyemo 
						and b.BudgetCode = @tobudgetcode)
	
	if @basedon = 3		-- initialize using a fixed Monthly Amount
		begin
		-- add Monthly Budget Detail
		insert dbo.bGLBD (GLCo, GLAcct, BudgetCode, Mth, BudgetAmt)
		select @glco, a.GLAcct, @tobudgetcode, m.Mth, @mthlyamt
		from dbo.bGLAC a
		join #Mths m on a.GLCo = m.Co
		where a.GLCo = @glco and a.GLAcct like @glacctmask and a.Active = 'Y' and a.AcctType <> 'H' -- exclude inactive and heading accounts
		end

	if @basedon = 4		-- initialized using Quartely Amounts
		begin
		-- calculate 1st Quarter amounts
		select @amt = @qtr1amt / 3
		select @lastmthamt = @qtr1amt - (@amt * 2)

		-- add Budget Detail for 1st Quarter
		insert dbo.bGLBD (GLCo, GLAcct, BudgetCode, Mth, BudgetAmt)
		select @glco, a.GLAcct, @tobudgetcode, m.Mth, @amt
		from dbo.bGLAC a
		join #Mths m on a.GLCo = m.Co
		where a.GLCo = @glco and a.GLAcct like @glacctmask and a.Active = 'Y' and a.AcctType <> 'H' -- exclude inactive and heading accounts
			and (m.Mth >= @bmth and m.Mth <= (dateadd(mm, 2, @bmth)))
		
		-- update last month of 1st Quarter with rounding error
		if @lastmthamt <> @amt
			begin
			update dbo.bGLBD set BudgetAmt = @lastmthamt
			where GLCo = @glco and GLAcct like @glacctmask and BudgetCode = @tobudgetcode and Mth = dateadd(mm, 2, @bmth)
			end

		-- calculate 2nd Quarter amounts
		select @amt = @qtr2amt / 3
		select @lastmthamt = @qtr2amt - (@amt * 2)

		-- add Budget Detail for 2nd Quarter
		insert dbo.bGLBD (GLCo, GLAcct, BudgetCode, Mth, BudgetAmt)
		select @glco, a.GLAcct, @tobudgetcode, m.Mth, @amt
		from dbo.bGLAC a
		join #Mths m on a.GLCo = m.Co
		where a.GLCo = @glco and a.GLAcct like @glacctmask and a.Active = 'Y' and a.AcctType <> 'H' -- exclude inactive and heading accounts
			and (m.Mth >= dateadd(mm,3,@bmth) and m.Mth <= dateadd(mm, 5, @bmth))
		
		-- update last month of 2nd Quarter with rounding error
		if @lastmthamt <> @amt
			begin
			update dbo.bGLBD set BudgetAmt = @lastmthamt
			where GLCo = @glco and GLAcct like @glacctmask and BudgetCode = @tobudgetcode and Mth = dateadd(mm, 5, @bmth)
			end

		-- calculate 3rd Quarter amounts
		select @amt = @qtr3amt / 3
		select @lastmthamt = @qtr3amt - (@amt * 2)

		-- add Budget Detail for 3rd Quarter
		insert dbo.bGLBD (GLCo, GLAcct, BudgetCode, Mth, BudgetAmt)
		select @glco, a.GLAcct, @tobudgetcode, m.Mth, @amt
		from dbo.bGLAC a
		join #Mths m on a.GLCo = m.Co
		where a.GLCo = @glco and a.GLAcct like @glacctmask and a.Active = 'Y' and a.AcctType <> 'H' -- exclude inactive and heading accounts
			and (m.Mth >= dateadd(mm,6,@bmth) and m.Mth <= dateadd(mm, 8, @bmth))
		
		-- update last month of 3rd Quarter with rounding error
		if @lastmthamt <> @amt
			begin
			update dbo.bGLBD set BudgetAmt = @lastmthamt
			where GLCo = @glco and GLAcct like @glacctmask and BudgetCode = @tobudgetcode and Mth = dateadd(mm, 8, @bmth)
			end

		-- calculate 4th Quarter amounts
		select @amt = @qtr4amt / 3
		select @lastmthamt = @qtr4amt - (@amt * 2)

		-- add Budget Detail for 4th Quarter
		insert dbo.bGLBD (GLCo, GLAcct, BudgetCode, Mth, BudgetAmt)
		select @glco, a.GLAcct, @tobudgetcode, m.Mth, @amt
		from dbo.bGLAC a
		join #Mths m on a.GLCo = m.Co
		where a.GLCo = @glco and a.GLAcct like @glacctmask and a.Active = 'Y' and a.AcctType <> 'H' -- exclude inactive and heading accounts
			and (m.Mth >= dateadd(mm,9,@bmth) and m.Mth <= @tofyemo)
		
		-- update last month of 4th Quarter with rounding error
		if @lastmthamt <> @amt
			begin
			update dbo.bGLBD set BudgetAmt = @lastmthamt
			where GLCo = @glco and GLAcct like @glacctmask and BudgetCode = @tobudgetcode and Mth = @tofyemo
			end
		end

	if @basedon = 5		-- initialize using an Annual Amount
		begin
		select @mths = count(*) from #Mths where Co = @glco
		select @amt = @annualamt / @mths, @lastmthamt = @amt
		if @mths > 1 select @lastmthamt = @annualamt - (@amt * (@mths - 1))	-- rounding error saved for last month

		-- add Monthly Budget Detail, all months
		insert dbo.bGLBD (GLCo, GLAcct, BudgetCode, Mth, BudgetAmt)
		select @glco, a.GLAcct, @tobudgetcode, m.Mth, @amt
		from dbo.bGLAC a
		join #Mths m on a.GLCo = m.Co
		where a.GLCo = @glco and a.GLAcct like @glacctmask and a.Active = 'Y' and a.AcctType <> 'H' -- exclude inactive and heading accounts

		-- update rounding error into fiscal year ending month
		if @lastmthamt <> @amt 
			begin
			update dbo.bGLBD set BudgetAmt = @lastmthamt
			where GLCo = @glco and GLAcct like @glacctmask and BudgetCode = @tobudgetcode and Mth = @tofyemo
			end
		end


	-- get # of Accounts initialized
	select @rows = count(*) from dbo.bGLBR (nolock) where GLCo = @glco and FYEMO = @tofyemo and BudgetCode = @tobudgetcode
					and GLAcct like @glacctmask
	end
	
vspexit:
   	if @tablecreated = 1 drop table #Mths
   	if @rcode = 0 and isnull(@rows,0) = 0 select @msg = 'No GL Accounts initialized.' 
   	if @rcode = 0 and isnull(@rows,0) > 0 select @msg = convert(varchar(8),@rows) + ' GL Accounts successfully initialized.' 	 
   	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspGLBudgetInit] TO [public]
GO
