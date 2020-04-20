SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     procedure [dbo].[bspGLBudgetInit]
   /****************************************************************************************
    * Created: ??????
    * Last Modified: 08/19/97 GDG
    *                09/22/97 SE    Took out feature to initialize budgets to 0 if based on budget and prior budget doesn't exist
    *                02/26/02 DANF  Changed insert to use values...
    *				  01/31/03 MV	 #20246 dbl quote cleanup.
    *				  03/23/04 DF    24141 Corrected insert statement	
    *				  09/30/05 GG - #28485 remove restrictions on Memo accounts, initialize budget beginning balance
    *
    * Used by GL Budget Initialization form to create budget amounts.  Replaces
    * or addes entries in GL Budget Revision (bGLBR) and GL Budget Detail (bGLBD)
    * 
    * Input Params:
    *   @glco = GL company
    *   @sourcefyemo = fiscal year to initialize budgets from
    *   @sourcebudgetcode = Budget Code to initialize from if based on budget amts
    *   @tofyemo = fiscal year we are initializing
    *   @tobudgetcode = Budget code we are initializing
    *   @basedon
    *        1 = actual amounts
    *        2 = budget amounts
    *        3 = set budget amounts to  0 for all months
    *   @glacctmask = mask formatted like a GL Account
    *	 use ? for single charater pattern matching.
    *	 all '?' chars are converted to '_' for SQL.
    *   @amtpct
    *	1 = initialize based on a fixed amount
    *	2 = initialize baed on a percentage
    *   @value = The value or % to increase the budget by.                    
    *
    * Output Params:
    *	@msg = if successful, message reporting # of GL Accounts initialized 
    *		or if failure, error message
    * Return code:
    *	0 = success
    *	1 = failure
    *************************************************************************************/
   	(@glco bCompany = 0, @sourcefyemo bMonth = null, @sourcebudgetcode bBudgetCode = null,
    	@tofyemo bMonth = null, @tobudgetcode bBudgetCode = null, @basedon tinyint = 0,
   	@glacctmask bGLAcct = null,  @amtpct tinyint, @value real, @msg varchar(255) output)
   
   as
   set nocount on
   
   declare @datediff tinyint, @rcode tinyint, @rows integer, @i int, @a char(1)
   declare @masklen int, @sourcemask varchar(20), @amt bDollar, @pct bPct
   declare @bmth bMonth, @emth bMonth, @tablecreated tinyint
   
   select @rcode = 0, @rows = 0, @tablecreated = 0
   
   /* validate GL company */
   if not exists(select 1 from dbo.bGLCO with (nolock) where GLCo = @glco)
   	begin
     	select @msg = 'Invalid GL Company!', @rcode = 1
   	goto bspexit
   	end
   
   /*validate Fiscal Year to initialize */
   select @bmth = BeginMth, @emth = FYEMO
   from dbo.bGLFY with (nolock)
   where GLCo = @glco and FYEMO = @tofyemo
   if @@rowcount = 0
   	begin
     	select @msg = 'Invalid Fiscal Year to initialize!', @rcode = 1
   	goto bspexit
   	end
   
   /* validate Budget Code to initialize */
   if not exists(select 1 from dbo.bGLBC with (nolock) where GLCo = @glco and BudgetCode = @tobudgetcode)
       begin
   	select @msg = 'Invalid Budget Code to initialize!', @rcode = 1
   	goto bspexit
   	end
   
   /* check Beginning and Ending GL Accounts masks */
   if @glacctmask is null
   	begin
   	select @msg = 'Must provide a GL Account mask!', @rcode = 1
   	goto bspexit
   	end
   
   /*validate initialization option */
   if @basedon not in(1,2,3)
   	begin
   	select @msg = 'Initialization must be based on a valid option!', @rcode = 1
   	goto bspexit
   	end
   
   /* validate 'based on' information */
   if @basedon = 1 or @basedon = 2
   	begin
   	if not exists(select 1 from dbo.bGLFY with (nolock) where GLCo = @glco and FYEMO = @sourcefyemo)
   		begin
   		select @msg = 'Not based on a valid Fiscal Year!', @rcode = 1
   		goto bspexit
   		end
   	end
   if @basedon = 2
   	begin
   	if not exists(select 1 from dbo.bGLBR with (nolock) where GLCo = @glco and FYEMO = @sourcefyemo
   		and BudgetCode = @sourcebudgetcode)
   		begin
   		select @msg = 'No Revisions exist for this Fiscal Year and Budget Code!', @rcode = 1
   		goto bspexit
   		end
   	end
   
   /* set amount and percent values */
    if @amtpct = 1
    	select @amt = @value, @pct = 0
    else
    	select @amt = 0, @pct= @value
   
   /* get # of months between fiscal year ends */
   if @sourcefyemo is not null select @datediff = datediff(month, @sourcefyemo, @tofyemo)
      	
   /*create a temp table with the months we need to initialize*/
   create table #Mths(Co tinyint NOT NULL, Mth smalldatetime NOT NULL)
   
   /* set temp table creation flag */
   select @tablecreated = 1
   
   --insert all months in 'to' fiscal year into temp table 
   while @bmth <= @emth 
   	begin
       	insert into #Mths(Co, Mth) values (@glco, @bmth) 
        	select @bmth = dateadd(mm,1,@bmth)
     	end
   
   /* convert GL Account Mask */
   select @masklen = datalength(@glacctmask), @i = 1
   while @i <= @masklen
   	begin
   	select @a = substring(@glacctmask,@i,1)
   	/* replace ? with _ */
   	if @a = '?' select @glacctmask = stuff(@glacctmask,@i,1,'_')
   	select @i = @i + 1
   	end
   
   /************ start budget initialization ***************/
   -- #28485 remove restriction on memo accounts, initialize budget beginning balance
   -- initialization overwrites existing budgets so remove all Fiscal Year and Detail Budget entries
   delete dbo.bGLBR
   where GLCo = @glco and FYEMO = @tofyemo and BudgetCode = @tobudgetcode
   	and GLAcct like @glacctmask
   -- remove Monthly Budget entries
   delete dbo.bGLBD
   from dbo.bGLBD b
   join #Mths m on m.Co = b.GLCo and m.Mth = b.Mth
   where b.GLCo = @glco and b.GLAcct like @glacctmask and b.BudgetCode = @tobudgetcode
   
   -- add Fiscal Year Budget entries
   if @basedon = 2	-- budget
   	begin
   	insert dbo.bGLBR (GLCo, FYEMO, BudgetCode, GLAcct, Notes, BeginBalance)	
   	select @glco, @tofyemo, @tobudgetcode, a.GLAcct, null,
   		case sign(isnull(b.BeginBalance,0))
   			when 1 then (b.BeginBalance + @amt + (b.BeginBalance * @pct))	-- debit balance
   			when -1 then (b.BeginBalance - @amt + (b.BeginBalance * @pct))	-- credit balance		
   			when 0 then (@amt * (case a.NormBal when 'C' then -1 else 1 end)) -- add or subtract amount based on normal balance
   			else 0
   			end
   	from dbo.bGLAC a
   	join dbo.bGLBR b on b.GLCo = a.GLCo and b.GLAcct = a.GLAcct	-- use equal join to only init accounts with source budgets
   	where a.GLCo = @glco and a.GLAcct like @glacctmask and a.Active = 'Y' and a.AcctType <> 'H'  -- skip inactive and heading accounts
   		and b.FYEMO = @sourcefyemo and b.BudgetCode = @sourcebudgetcode
   
   	select @rows = @@rowcount	-- save number of accounts initialized
   	end
   if @basedon in (1,3)	-- whether initializing from Actuals or Zero set Begin Balance to zero 
   	begin
   	insert dbo.bGLBR (GLCo, FYEMO, BudgetCode, GLAcct, Notes, BeginBalance)	
   	select @glco, @tofyemo, @tobudgetcode, GLAcct, null, 0
   	from dbo.bGLAC 	-- init all accounts
   	where GLCo = @glco and GLAcct like @glacctmask and Active = 'Y' and AcctType <> 'H'  -- skip inactive and heading accounts
   	
   	select @rows = @@rowcount	-- save number of accounts initialized	
   	end
   
   -- add Monthly Budget Detail 
   if @basedon = 1		-- actuals
   	begin		
   	insert dbo.bGLBD (GLCo, GLAcct, BudgetCode, Mth, BudgetAmt)
       select @glco, a.GLAcct, @tobudgetcode, m.Mth,
       	case sign(isnull(l.NetActivity,0))
           	when  1 then (l.NetActivity + @amt + (l.NetActivity * @pct))	-- debit balance
               when -1 then (l.NetActivity - @amt + (l.NetActivity * @pct))	-- credit balance
               when  0 then (@amt * (case a.NormBal when 'C' then -1 else 1 end))  -- add or subtract amount based on normal balance
   			else 0
               end
   	from dbo.bGLAC a
   	join #Mths m on a.GLCo = m.Co
   	left join dbo.bGLBL l on a.GLCo = l.GLCo and a.GLAcct = l.GLAcct	-- use outer join to init all accounts
   		and	dateadd(month,@datediff,l.Mth) = m.Mth
       where a.GLCo = @glco and a.GLAcct like @glacctmask and a.Active='Y' and a.AcctType <> 'H' -- exclude inactive and heading accounts
   	end
   if @basedon = 2 	-- budgets
   	begin
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
   if @basedon = 3		-- init to zero
   	begin		
       insert dbo.bGLBD (GLCo, GLAcct, BudgetCode, Mth, BudgetAmt)
       select @glco, a.GLAcct, @tobudgetcode, m.Mth, 0
       from dbo.bGLAC a	-- init all accounts
   	join #Mths m on a.GLCo = m.Co
       where a.GLCo = @glco and a.GLAcct like @glacctmask and a.Active = 'Y' and a.AcctType <> 'H' -- exclude inactive and heading accounts
   	end
   
   bspexit:
   	if @tablecreated = 1 drop table #Mths
   	if @rcode = 0 and isnull(@rows,0) = 0 select @msg = 'No GL Accounts initialized.' 
   	if @rcode = 0 and isnull(@rows,0) > 0 select @msg = convert(varchar(8),@rows) + ' GL Accounts successfully initialized.' 	 
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLBudgetInit] TO [public]
GO
