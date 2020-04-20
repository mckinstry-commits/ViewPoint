SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRW2InitSL    Script Date: 1/9/2004 12:29:32 PM ******/

/****** Object:  Stored Procedure dbo.bspPRW2InitSL    Script Date: 8/28/99 9:35:42 AM ******/
CREATE                procedure [dbo].[bspPRW2InitSL]
/************************************************************
* CREATED:		EN	12/03/1998
* MODIFIED:		EN	01/28/1999
*				EN	08/04/2000 - initialize local info into bPRWL rather than bPRWS
*				GG	08/09/2000 - fixed bPRWS and bPRWL inserts
*				EN	12/26/2000 - fixed to ignore YEARLY neg amts rather than by month (issue #11686)
*				GF	03/04/2002 - issue #16424 - state local codes exist with no state in PRWS
*				GG	07/19/2002 - #16595 - pull local dedns where bPRDL.IncldW2 = 'Y'				
*				EN	10/09/2002 - issue 18877 change double quotes to single
*				GH	12/10/2002 - cannot insert duplicate into PRWS (Issue 19611) added distinct
*				EN	01/17/2003 - issue 20036 for Misc Amts 1 & 2 get abs of sum rather than sum of abs (similar to issue 15746)
*				DC	05/02/2003 - issue 19615  - Need to expand error message regarding duplicate entries
*				DC	01/09/2004 - #23440  - Local code with more than 1 deduction code not calculating correctly.
*				DC	02/18/2004 - 23472 - Getting 'duplicate key' error
*				EN	09/28/2004 - issue 23818  remove any W-2 with 0 amounts ... checks PRWA_Amount, PRWS_Tax, PRWS_Misc1Amt, PRWS_Misc2Amt, and PRWL_Tax
*				EN	08/30/2005 - issue 29707  clarify which dedn codes are set up to include on W-2 when add to bPRWL as per issue 16595
*				EN	09/07/2005 - issue 26938  fixed to properly set the Misc Amounts ... added Misc lines 3 & 4
*				MH	12/13/2007 - issue 119827 - Do not include Accums that have 0 Amount/SubjAmt
*				EN	03/07/2008 - #127081  in declare statements change State declarations to varchar(4)
*				EN	09/10/2009 - #131112 populate bPRWL TaxEntity field using new field in bPRLI
*				EN	09/02/2010 - #138393 Do not include state with local if no state tax
*				CHS	09/03/2010 - #137687 Add additional box 14 lines (items)
*				EN  09/09/2010 - #137687 Additional change to remove mention of bPRWM table and correctly reference sm.State in pass 2 of inserting #PRW2Empls
*				CHS	09/03/2010 - #137687 purge prior entries and insert only if not zero
*				Dan So 07/24/2012 - D-02774 - deleted references to PRWM
*				CHS	11/16/2012	- D-04527 #143427
*
* USAGE:
* Initialize state/local W-2 information.
*
* INPUT PARAMETERS
*   @PRCo      PR Co
*   @TaxYear   Tax Year
*
* OUTPUT PARAMETERS
*   @errmsg     if something went wrong
* RETURN VALUE
*   0   success
*   1   fail
************************************************************/
   	@PRCo bCompany, @TaxYear char(4), @errmsg varchar(255) output
   as
   set nocount on
   
   declare @rcode int, @firstdayinyear char(10), @lastdayinyear char(10),
   	@rmsg varchar(255)  --DC Issue #19615
   
   declare @employee bEmployee, @state varchar(4), @taxid varchar(20), @taxdedncode bEDLCode, 
   	@wages bDollar, @tax bDollar, 
   	@amount bDollar, @edltype char(1), @edlcode bEDLCode, @linenumber int, @description varchar(30), @loopnumber int,--#137387
   	@openPRW2Empls tinyint --#26938

   
   -- make sure temp table doesn't already exist
   if object_id('#PRW2Empls') is not null drop table #PRW2Empls
   
   -- create temp table to hold employees/tax dedn/misc amounts info
   create table #PRW2Empls
   	(Employee int not null,	-- allow null to report jobs with missing OT schedules
   	State varchar(2) not null ,
   	TaxID varchar(20) null ,
   	TaxDednCode smallint null)
   
   select @rcode = 0, @errmsg = null
   
   /* verify Tax Year Ending Month */
   if @TaxYear is null
   	begin
   	select @errmsg = 'Tax Year has not been selected.', @rcode = 1
   	goto bspexit
   	end
   
   --DC Issue #19615 /  Call sp to check for duplicate deduction codes
   exec @rcode = bspPRW2InitSLDup @PRCo, @TaxYear, @rmsg output
   if @rcode <> 0
   	BEGIN
   	select @errmsg = @rmsg
   	goto bspexit
   	END
   	
   /* Initialize State/Local W-2 Information */
   
   /* set variables for first and last day in tax year */
   select @firstdayinyear = '01/01/' + @TaxYear
   select @lastdayinyear = '12/31/' + @TaxYear
   
   /* 23472 - Delete previous bPRWS and bPRWL records */
   delete bPRWS
   where PRCo = @PRCo and TaxYear = @TaxYear 
   delete bPRWL
   where PRCo = @PRCo and TaxYear = @TaxYear
   -- #137687
   delete bPRW2MiscDetail
   where PRCo = @PRCo and TaxYear = @TaxYear
   
   /* the following section of code thru the loop inserts bPRWS entries for state tax based on bPRWT */
   --fill temp table variable based on PRWT entries
   insert #PRW2Empls (Employee, State, TaxID, TaxDednCode) 
   select e.Employee, t.State, s.TaxID, t.DednCode
   from dbo.bPRWE e with (nolock)
   join dbo.bPRWT t with (nolock) on t.PRCo=e.PRCo and t.TaxYear=e.TaxYear
   join dbo.bPRSI s with (nolock) on s.PRCo=e.PRCo and s.State=t.State
   where e.PRCo=@PRCo and e.TaxYear=@TaxYear and t.LocalCode <= '          ' and t.Initialize='Y'
   
   --fill temp table variable based on bPRW2MiscHeader entries with no matching PRWT entries
   insert #PRW2Empls (Employee, State, TaxID, TaxDednCode) 
   select e.Employee, sm.State, s.TaxID, null
   from dbo.bPRWE e with (nolock)
   join dbo.bPRW2MiscHeader sm with (nolock) on sm.PRCo=e.PRCo and sm.TaxYear=e.TaxYear --#137687
   join dbo.bPRSI s with (nolock) on s.PRCo=e.PRCo and s.State=sm.State --#26938 after orig. coding added this join in order to get Tax ID
   where e.PRCo=@PRCo and e.TaxYear=@TaxYear and sm.State not in (select State from #PRW2Empls where Employee=e.Employee)
   
   --create cursor to loop thru temp table variable, gather amts, and write to PRWS
   declare bcPRW2Empls cursor for
   	select Employee, State, TaxID, TaxDednCode
   	from #PRW2Empls
     
   open bcPRW2Empls
   select @openPRW2Empls = 1
     
   -- start of loop
   next_PRW2Empl:
   	fetch next from bcPRW2Empls into @employee, @state, @taxid, @taxdedncode
   	
   	if @@fetch_status <> 0 goto end_PRW2Empl


   	--#137687
   	--compute box 14 state amounts for table bPRW2MiscDetail
   	--look for all applicable entries in bPRW2MiscHeader   	    	
   	
	-- create temp table to hold a sequential listing of line numbers   	
	IF object_id('tempdb..#PRW2MiscHeaderLines') IS NOT NULL DROP TABLE #PRW2MiscHeaderLines
	CREATE TABLE #PRW2MiscHeaderLines(IDNumber int IDENTITY (1, 1), LineNumber int not null)

	-- populate temp table with a sequential listing of line numbers   
	INSERT #PRW2MiscHeaderLines(LineNumber)
	SELECT LineNumber
	FROM bPRW2MiscHeader
	WHERE PRCo = @PRCo and TaxYear = @TaxYear and State = @state
	
	select @loopnumber = 1, @linenumber = 0
	   	
   	WHILE(EXISTS(SELECT top 1 1 FROM #PRW2MiscHeaderLines WHERE @loopnumber = IDNumber))
		BEGIN

		SET @amount = 0
		
		SELECT @linenumber = LineNumber FROM #PRW2MiscHeaderLines WHERE @loopnumber = IDNumber
		
		SELECT @edltype = EDLType, @edlcode = EDLCode, @description = Description
			FROM dbo.bPRW2MiscHeader with (nolock)
			WHERE PRCo = @PRCo and TaxYear = @TaxYear and State = @state and LineNumber = @linenumber

		-- get the ammount value from PREA
		SELECT @amount=isnull(abs(sum(a.Amount)), 0)
			FROM dbo.bPREA a with (nolock)
			WHERE a.PRCo=@PRCo and a.Employee=@employee and a.Mth>=@firstdayinyear and a.Mth<=@lastdayinyear
				and a.EDLType=@edltype and a.EDLCode=@edlcode	

		IF @amount <> 0
			BEGIN
			-- insert new lines and amounts.
			INSERT dbo.bPRW2MiscDetail (PRCo, TaxYear, State, Employee, LineNumber, Amount)
			VALUES (@PRCo, @TaxYear, @state, @employee, @linenumber, @amount)			
			END
		
		-- limit to only 2000 iterations
		IF @loopnumber >= 2000
			BEGIN
				SELECT @errmsg = 'Infinite looping error - breaking at 2000 lines.', @rcode = 1
				RETURN @rcode
			END

		SET @loopnumber = @loopnumber + 1
		
		END
   	   
   	--compute wages/tax/misc amts
   	select @wages=sum(a.SubjectAmt), @tax=sum(a.Amount)
   	from dbo.bPREA a with (nolock)
   	where a.PRCo=@PRCo and a.Employee=@employee and a.Mth>=@firstdayinyear and a.Mth<=@lastdayinyear
   		and a.EDLType='D' and a.EDLCode=@taxdedncode

   	DECLARE @StateControl VARCHAR(7)
   	
   	SELECT 	@StateControl = ControlId FROM dbo.bPRSI WHERE PRCo = @PRCo and State = @state
    
   	--add record to bPRWS if any of the amounts are non-zero
   	if isnull(@wages,0)<>0 or isnull(@tax,0)<>0 
   		begin
   		insert dbo.bPRWS (PRCo, TaxYear, Employee, State, TaxID, TaxEntity, Wages, Tax, 
   			OtherStateData, TaxType, StateControl, OptionCode1, OptionCode2) --#137687
   		values (@PRCo, @TaxYear, @employee, @state, @taxid, null, isnull(@wages,0), isnull(@tax,0), 
   			null, 'F', @StateControl, null, null) --#137687
   		end
   
   	goto next_PRW2Empl
   
   end_PRW2Empl:
   --clean up
   close bcPRW2Empls
   deallocate bcPRW2Empls
   select @openPRW2Empls = 0
   drop table #PRW2Empls
   
   -- /* warn user if any negative state accums exist */
   delete from bPRWS
   where PRCo = @PRCo and TaxYear = @TaxYear and (Wages < 0 or Tax < 0)
   if @@rowcount <> 0
   	select @errmsg = 'Warning: Negative State amounts were found and will not be included on W-2.', @rcode = 5
   
   /* add unemployment information for Georgia */
   update bPRWE
   set SUIWages = (select sum(a.SubjectAmt)
                   from bPREA a
                   join bPRSI s on s.PRCo = a.PRCo
                   where a.PRCo = @PRCo and a.Mth >= @firstdayinyear and a.Mth <= @lastdayinyear and a.EDLType = 'L'
                       and s.State = 'GA' and a.EDLCode = s.SUTALiab and a.Employee = e.Employee),
       SUITaxableWages = (select sum(a.EligibleAmt)
                   from bPREA a
                   join bPRSI s on s.PRCo = a.PRCo
                   where a.PRCo = @PRCo and a.Mth >= @firstdayinyear and a.Mth <= @lastdayinyear and a.EDLType = 'L'
                       and s.State = 'GA' and a.EDLCode = s.SUTALiab and a.Employee = e.Employee),
       WeeksWorked = (select sum(a.Hours)
                   from bPREA a
                   join bPRSI s on s.PRCo = a.PRCo
                   where a.PRCo = @PRCo and a.Mth >= @firstdayinyear and a.Mth <= @lastdayinyear and a.EDLType = 'L'
                       and s.State = 'GA' and a.EDLCode = s.SUTALiab and a.Employee = e.Employee)
   from bPRWE e
   where e.PRCo = @PRCo and TaxYear = @TaxYear
   
   /* add PRWL local information */
   --DC #23440
	--119827 - Do not include Accums that have 0 Amount/SubjAmt
   insert bPRWL (PRCo, TaxYear, Employee, State, LocalCode, TaxID, TaxEntity,
       Wages, Tax, TaxType)
   select e.PRCo, @TaxYear, e.Employee, t.State, t.LocalCode, l.TaxID, l.TaxEntity,
   	sum(a.SubjectAmt), sum(a.Amount), l.TaxType	
   from bPRWE e
   join bPRWT t on t.PRCo = e.PRCo and t.TaxYear = e.TaxYear
   join bPRLI l on l.PRCo = e.PRCo and l.LocalCode = t.LocalCode and l.TaxDedn = t.DednCode
   join bPREA a on a.PRCo = e.PRCo and a.Employee = e.Employee and a.EDLCode = l.TaxDedn
	and (a.Amount <> 0 or a.SubjectAmt <> 0) --mark
   where e.PRCo = @PRCo and e.TaxYear = @TaxYear and t.Initialize = 'Y'
   	and a.Mth >= @firstdayinyear and a.Mth <= @lastdayinyear
   	and a.EDLType = 'D' --and a.EDLCode = l.TaxDedn
   group by e.PRCo, e.Employee, t.State, t.LocalCode, l.TaxID, l.TaxEntity, l.TaxType
   
   -- add information for employee based dedns flagged to be reported as local - #16595
   insert bPRWL (PRCo, TaxYear, Employee, State, LocalCode, TaxID, TaxEntity,
       Wages, Tax, TaxType)
   select e.PRCo, @TaxYear, e.Employee, t.State, t.LocalCode, null, null,
   	sum(a.SubjectAmt), sum(a.Amount), l.TaxType
   from bPRWE e
   join bPRWT t on t.PRCo = e.PRCo and t.TaxYear = e.TaxYear
   join bPRDL l on l.PRCo = t.PRCo and l.DLCode = t.DednCode
   join bPREA a on a.PRCo = e.PRCo and a.Employee = e.Employee
   where e.PRCo = @PRCo and e.TaxYear = @TaxYear and t.Initialize = 'Y'
   	and a.Mth >= @firstdayinyear and a.Mth <= @lastdayinyear
   	and a.EDLType = 'D' and a.EDLCode = l.DLCode 
   	and l.IncldW2='Y' and l.W2State is not null and l.W2Local is not null and l.TaxType is not null --#29707 added l.IncldW2='Y' to where clause
   group by e.PRCo, e.Employee, t.State, t.LocalCode, l.TaxType
   
   -- warn user if any negative local accums exist
   delete from bPRWL
   where PRCo = @PRCo and TaxYear = @TaxYear and (Wages < 0 or Tax < 0)
   if @@rowcount <> 0
   	begin
        if @errmsg is null
   	   select @errmsg = 'Warning: Negative Local amounts were found and will not be included on W-2.', @rcode = 5
        else
   	   select @errmsg = 'Warning: Negative State and Local amounts were found and will not be included on W-2.', @rcode = 5
   	end
  
-- #138393 don't add PRWS record if there is local tax but no state tax 
--   -- create PRWS records if state in PRWL and not in PRWS
--   insert bPRWS (PRCo, TaxYear, Employee, State, TaxID, TaxEntity, Wages, Tax,
--   	OtherStateData, TaxType, StateControl, OptionCode1, OptionCode2, Misc1Amt, Misc2Amt, Misc3Amt, Misc4Amt) --#26938
--   select distinct a.PRCo, a.TaxYear, a.Employee, a.State, s.TaxID, null, 0, 0, null, 'F', null, null, null, 0, 0, 0, 0 --#26938
--   from bPRWL a
--   join bPRSI s on s.PRCo = a.PRCo and s.State = a.State
--   where a.PRCo = @PRCo and a.TaxYear = @TaxYear 
--   and not exists(select b.PRCo from bPRWS b WITH (NOLOCK) where b.PRCo=@PRCo and b.TaxYear=@TaxYear
--   					and b.Employee=a.Employee and b.State=a.State)
   
   --issue 23818  remove any W-2 with 0 amounts
   delete from bPRWE
   from bPRWE e
   where e.PRCo=@PRCo and e.TaxYear=@TaxYear
   	--and e.Misc1Amt=0 and e.Misc2Amt=0 and e.Misc3Amt=0 and e.Misc4Amt=0 --#26938 -137687
   	and (select isnull(sum(a.Amount),0) from bPRWA a where a.PRCo=e.PRCo and a.TaxYear=e.TaxYear and a.Employee=e.Employee)=0
   	and (select isnull(sum(s.Tax),0) -- #137687  +isnull(sum(s.Misc1Amt),0)+isnull(sum(s.Misc2Amt),0)+isnull(sum(s.Misc3Amt),0)+isnull(sum(s.Misc4Amt),0) --#26938
   			from bPRWS s where s.PRCo=e.PRCo and s.TaxYear=e.TaxYear and s.Employee=e.Employee)=0
   	and (select isnull(sum(l.Tax),0) from bPRWL l where l.PRCo=e.PRCo and l.TaxYear=e.TaxYear and l.Employee=e.Employee)=0

	--Issue 131629 Set State Wages = Federal Wages for NY State residents and non-residents who work in NY regardless of
	--of amount of time worked in NY.  Employees work out allocations with the state using Form IT-2104. 
	
	select b.Amount,a.*
	from bPRWS a
	left join PRWA b on a.PRCo=b.PRCo and a.TaxYear=b.TaxYear and a.Employee=b.Employee and b.Item=1
	where a.PRCo = @PRCo and a.TaxYear=@TaxYear and a.State='NY' and b.Amount<>a.Wages 
	
	
	update bPRWS set Wages=b.Amount
	from bPRWS a
	left join PRWA b on a.PRCo=b.PRCo and a.TaxYear=b.TaxYear and a.Employee=b.Employee and b.Item=1
	where a.PRCo = @PRCo and a.TaxYear=@TaxYear and a.State='NY' and b.Amount<>a.Wages 
	--End Issue 131629 
	   
   	select b.Amount,a.*
	from bPRWS a
	left join PRWA b on a.PRCo=b.PRCo and a.TaxYear=b.TaxYear and a.Employee=b.Employee and b.Item=1
	where a.PRCo = @PRCo and a.TaxYear=@TaxYear and a.State='NY' 
	
   bspexit:
   	if @openPRW2Empls = 1
   		begin
   		close bcPRW2Empls
   		deallocate bcPRW2Empls
   		end
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRW2InitSL] TO [public]
GO
