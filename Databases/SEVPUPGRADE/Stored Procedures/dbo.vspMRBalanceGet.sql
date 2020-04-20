SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************/
CREATE PROC [dbo].[vspMRBalanceGet]
/*************************************
* CREATED BY:	GF 01/24/2009
* Modified By:	GF 08/31/2008 - issue #135307 - added code to load GLBD monthly amounts (budget)
*
*
*	Calculates and inserts period
*	and detail balances using parameters
*	defined when report generation is run
*	from Management Reporter
*
*	Input Parameters:
*	Entity - Company
*    
*	Output Parameters:
*		rcode - 0 Success
*				1 Failure
*		msg - Return Message
*
*		dr_cr_flag - 1 Debit
*					 2 Credit
*
*	Start Date of '01/01/1980' is a default and means that the start date does not apply
*	End Date of '01/01/1980' is a default and means that the end date does not apply.
*
*	When the @update_trans flag = 'Y' then we need transaction detail. Otherwise skip.
*		
**************************************/
(@Entity int = null, @startyear smallint = null, @endyear smallint = null,
 @startperiod smallint = null, @endperiod smallint = null,
 @startdate smalldatetime = null, @enddate smalldatetime = null,
 @update_trans varchar(1))
	
with execute as 'viewpointcs'
as
set nocount on

declare @rcode int, @msg varchar(255)

---- must have an entity, start year, and start period
if @Entity is null or @startyear is null or @startperiod is null goto vspexit

set @rcode = 0

if @endyear is null set @endyear = @startyear
if @endperiod is null set @endperiod = @startperiod


declare @LenWithMask tinyint, @LenWithOutMask tinyint, @NaturalSeg tinyint,
		@L1 tinyint, @L2 tinyint, @L3 tinyint, @L4 tinyint, @L5 tinyint, @L6 tinyint,
		@S1 char(1), @S2 char(1), @S3 char(1), @S4 char(1), @S5 char(1), @S6 char(1),
		@SP1 tinyint, @SP2 tinyint, @SP3 tinyint, @SP4 tinyint, @SP5 tinyint, @SP6 tinyint

exec @rcode = dbo.vspFRXGetAcctMask @LenWithMask output, @LenWithOutMask output, @NaturalSeg output,
			@L1 output, @L2 output, @L3 output, @L4 output, @L5 output, @L6 output, @S1 output,
			@S2 output, @S3 output, @S4 output, @S5 output, @S6 output, @SP1 output, @SP2 Output,
			@SP3 output, @SP4 output, @SP5 output, @SP6 output


---------------------------------
---- Insert period balances  ----
---------------------------------
begin try

	----------------------------
	---- Insert frl_per_bal ----
	----------------------------

	---- remove period balances based on range of start, end years and start, end periods
	delete dbo.frl_per_bal
	where entity_num = @Entity and fiscal_year between @startyear and @endyear


	---- insert period balances
	;
	with actual_Balances(GLCo, FiscalYear, FiscalPd, GLAcct, AllParts, Debits, Credits) AS
	(
		select t.GLCo, p.FiscalYr, p.FiscalPd, t.GLAcct, substring(c.AllParts,1,@LenWithOutMask),
					isnull(t.Debits,0), isnull(t.Credits,0)
		from bGLBL t with (nolock)
		join bGLFP p with (nolock) on p.GLCo = t.GLCo and p.Mth = t.Mth
		join bGLFY y with (nolock) on y.GLCo = t.GLCo and y.FiscalYear = p.FiscalYr
		join bGLAC c with (nolock) on c.GLCo = t.GLCo and c.GLAcct = t.GLAcct
		where t.GLCo = @Entity and isnull(c.AllParts,'') <> ''
		and p.FiscalYr >= @startyear and p.FiscalYr <= @endyear
	)
----		 select * from actual_Balances
		insert into dbo.frl_per_bal (entity_num, fiscal_year, per_num, acct_code, curr_code, book_code,
					amt_nat_dr, amt_nat_cr, amt_funct_dr, amt_funct_cr, last_updated)
		select a.GLCo, a.FiscalYear, a.FiscalPd, a.AllParts, 'USD', 'ACTUAL',
				a.Debits, a.Credits, a.Debits, a.Credits, current_timestamp
		from actual_Balances a
		where not exists(select 1 from frl_per_bal b with (nolock) where b.book_code = 'ACTUAL'
				and b.entity_num = a.GLCo and b.fiscal_year = a.FiscalYear and b.per_num = a.FiscalPd
				and b.acct_code = a.AllParts)
	;

	---- insert beginning balances from GLYB
	;
	with begin_Balances(GLCo, FiscalYear, FiscalPd, GLAcct, AllParts, Debits, Credits) AS
	(
		select x.GLCo, p.FiscalYr, 0, x.GLAcct, substring(c.AllParts,1,@LenWithOutMask),
				case when isnull(x.BeginBal,0) > 0 then abs(isnull(x.BeginBal,0)) else 0 end, ---- debit
				case when isnull(x.BeginBal,0) < 0 then abs(isnull(x.BeginBal,0)) else 0 end  ---- credit
		from bGLYB x with (nolock)
		join bGLAC c with (nolock) on c.GLCo = x.GLCo and c.GLAcct = x.GLAcct
		join bGLFP p with (nolock) on p.GLCo = x.GLCo and p.Mth = x.FYEMO
		where x.GLCo = @Entity and isnull(x.BeginBal,0) <> 0 and isnull(c.AllParts,'') <> ''
		and p.FiscalYr between @startyear and @endyear
	)
----		select * from begin_Balances
		insert into dbo.frl_per_bal (entity_num, fiscal_year, per_num, acct_code, curr_code, book_code,
					amt_nat_dr, amt_nat_cr, amt_funct_dr, amt_funct_cr, last_updated)
		select GLCo, FiscalYear, FiscalPd, AllParts, 'USD', 'ACTUAL',
				Debits, Credits, Debits, Credits, current_timestamp
		from begin_Balances a
		where not exists(select 1 from frl_per_bal b with (nolock) where b.book_code = 'ACTUAL'
				and b.entity_num = a.GLCo and b.fiscal_year = a.FiscalYear and b.per_num = a.FiscalPd
				and b.acct_code = a.AllParts)
	;

	---- insert year-end adjustments from GLYB
	;
	with adjust_Balances(GLCo, FiscalYear, FiscalPd, GLAcct, AllParts, Debits, Credits) AS
	(
		select x.GLCo, p.FiscalYr, p.FiscalPd, x.GLAcct, substring(c.AllParts,1,@LenWithOutMask),
				case when isnull(x.NetAdj,0) > 0 then abs(isnull(x.NetAdj,0)) else 0 end, ---- debit
				case when isnull(x.NetAdj,0) < 0 then abs(isnull(x.NetAdj,0)) else 0 end  ---- credit
		from bGLYB x with (nolock)
		join bGLAC c with (nolock) on c.GLCo = x.GLCo and c.GLAcct = x.GLAcct
		join bGLFP p with (nolock) on p.GLCo = x.GLCo and p.Mth = x.FYEMO
		where x.GLCo = @Entity and isnull(x.NetAdj,0) <> 0 and isnull(c.AllParts,'') <> ''
		and p.FiscalYr >= @startyear and p.FiscalYr <= @endyear
	)
----		select * from adjust_Balances
		insert into dbo.frl_per_bal (entity_num, fiscal_year, per_num, acct_code, curr_code, book_code,
					amt_nat_dr, amt_nat_cr, amt_funct_dr, amt_funct_cr, last_updated)
		select a.GLCo, a.FiscalYear, a.FiscalPd, a.AllParts, 'USD', 'ADJUSTMENT',
				a.Debits, a.Credits, a.Debits, a.Credits, current_timestamp
		from adjust_Balances a
		where not exists(select 1 from frl_per_bal b with (nolock) where b.book_code = 'ADJUSTMENT'
				and b.entity_num = a.GLCo and b.fiscal_year = a.FiscalYear and b.per_num = a.FiscalPd
				and b.acct_code = a.AllParts)
	;

	---- insert budget amounts from GLBD
	;
	with budget_Balances(GLCo, FiscalYear, FiscalPd, GLAcct, AllParts, BudgetCode, Debits, Credits) AS
	(
		select t.GLCo, p.FiscalYr, p.FiscalPd, t.GLAcct, substring(c.AllParts,1,@LenWithOutMask), t.BudgetCode,
				case when isnull(t.BudgetAmt,0) > 0 then abs(isnull(t.BudgetAmt,0)) else 0 end, ---- debit
				case when isnull(t.BudgetAmt,0) < 0 then abs(isnull(t.BudgetAmt,0)) else 0 end  ---- credit
		from bGLBD t with (nolock)
		join bGLFP p with (nolock) on p.GLCo = t.GLCo and p.Mth = t.Mth
		join bGLFY y with (nolock) on y.GLCo = t.GLCo and y.FiscalYear = p.FiscalYr
		join bGLAC c with (nolock) on c.GLCo = t.GLCo and c.GLAcct = t.GLAcct
		where t.GLCo = @Entity and isnull(c.AllParts,'') <> ''
		and p.FiscalYr >= @startyear and p.FiscalYr <= @endyear
	)
----		 select * from budget_Balances
		insert into dbo.frl_per_bal (entity_num, fiscal_year, per_num, acct_code, curr_code, book_code,
					amt_nat_dr, amt_nat_cr, amt_funct_dr, amt_funct_cr, last_updated)
		select a.GLCo, a.FiscalYear, a.FiscalPd, a.AllParts, 'USD', a.BudgetCode,
				a.Debits, a.Credits, a.Debits, a.Credits, current_timestamp
		from budget_Balances a
		where not exists(select 1 from frl_per_bal b with (nolock) where b.book_code = a.BudgetCode
				and b.entity_num = a.GLCo and b.fiscal_year = a.FiscalYear and b.per_num = a.FiscalPd
				and b.acct_code = a.AllParts)
	;



end try

begin catch

	--Log errors in vDDAL.
	insert vDDAL(DateTime, HostName, UserName, ErrorNumber, Description, SQLRetCode, UnhandledError, Informational,
		Assembly, Class, [Procedure], AssemblyVersion, StackTrace, FriendlyMessage, LineNumber, Event, Company,
		Object, CrystalErrorID, ErrorProcedure)
	values(current_timestamp, host_name(), suser_name(), error_number(), error_message(), null, 0, 1, 
		'VF', null, 'vspMREntityUpdate', null, null, 'Error getting MR period balances.', 
		error_line(), null, @Entity, null, null, null)

end catch


-----------------------------------------
-------- Insert detail transactions  ----
-----------------------------------------

if @update_trans <> 'Y' goto vspexit

begin try

	--------------------------
	-- Insert frl_trx_dtl --
	--------------------------

	---- remove period balances based on range of start, end years and start, end periods
	delete dbo.frl_trx_dtl where entity_num = @Entity
	and fiscal_year between @startyear and @endyear
	and per_num between @startperiod and @endperiod


	---- insert detail tranasctions
	insert frl_trx_dtl (entity_num, fiscal_year, per_num, acct_code,
			curr_code, book_code, dr_cr_flag,
			amt_nat, amt_funct, adj_trx, trx_desc, date_applied, last_updated,
			amt_rpt01, attr01, attr02, attr03)
	select @Entity, p.FiscalYr, p.FiscalPd, substring(c.AllParts,1,@LenWithOutMask),
			'USD', 'ACTUAL', case when t.Amount > 0 then 1 else 2 end,
			abs(t.Amount), abs(t.Amount), 0, isnull(t.Description,' '), isnull(t.ActDate,current_timestamp),
			current_timestamp, null, null, null, t.Jrnl
	from bGLDT t with(nolock)
	join bGLFP p with (nolock) on p.GLCo = t.GLCo and p.Mth = t.Mth
	join bGLAC c with (nolock) on c.GLCo = t.GLCo and c.GLAcct = t.GLAcct
	where t.GLCo = @Entity and t.Mth = p.Mth and isnull(c.AllParts,'') <> '' ----and year(t.Mth) = year(current_timestamp)
	and p.FiscalYr between @startyear and @endyear
	and p.FiscalPd between @startperiod and @endperiod
	order by t.GLCo, p.FiscalYr, p.FiscalPd, substring(c.AllParts,1,@LenWithOutMask)


end try


begin catch

	--Log errors in vDDAL.
	insert vDDAL(DateTime, HostName, UserName, ErrorNumber, Description, SQLRetCode, UnhandledError, Informational,
		Assembly, Class, [Procedure], AssemblyVersion, StackTrace, FriendlyMessage, LineNumber, Event, Company,
		Object, CrystalErrorID, ErrorProcedure)
	values(current_timestamp, host_name(), suser_name(), error_number(), error_message(), null, 0, 1, 
		'VF', null, 'vspMREntityUpdate', null, null, 'Error getting MR Transaction detail.', 
		error_line(), null, @Entity, null, null, null)

end catch



vspexit:
	return @rcode



GO
GRANT EXECUTE ON  [dbo].[vspMRBalanceGet] TO [public]
GO
