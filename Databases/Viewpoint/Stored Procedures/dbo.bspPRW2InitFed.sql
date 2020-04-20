SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRW2InitFed    Script Date: 8/28/99 9:35:41 AM ******/
  CREATE          procedure [dbo].[bspPRW2InitFed]
/************************************************************
* CREATED BY: 	 EN 12/01/98
* MODIFIED By : EN 1/28/99
*                           JRE 1/19/00  - moved DeferedComp  to the end - after all of PRWA is caluclated
*               EN 9/6/00 - clear entries from new bPRWL table
*               EN 10/13/00 - misc box 14 info selected in header not getting initialized correctly (issue #10948)
*               EN 10/23/00 - added init to 0 for SUIWages, SUITaxableWages, WeeksWorked (Georgia W-2's)
*               EN 12/26/00 - fixed to ignore YEARLY neg amts rather than by month (issue #11686)
*               MV 9/12/01 - Issue 11918 - fixed bPRWA insert to insert all items > 7 but not items 40, 41 which are 'other'
*				  EN 1/9/02 - issue 14712 - added suffix to bPREH ... include that data when write to bPRWE
*				  EN 1/9/02 - issue 15746 - need to display abs of amts in case of neg dedns but needed to fix select stmt to get abs value of sum rather than sum of abs
*				  EN 10/9/02 - issue 18877 change double quotes to single
*				  EN 1/17/03 - issue 20036 for Misc Amts 1 & 2 get abs of sum rather than sum of abs (similar to issue 15746)
*				EN 9/24/04 - issue 23612 initialize PRWA_ItemID to 'yy'
*				EN 9/07/05 - issue 26938 add Misc lines 3 & 4
*				EN 1/9/06 - issue 119749 ** temporary fix to allow for neg earnings in item 43 (code W) **
*				EN 10/27/06 - issue 122912 change issue 119749 temp fix to permanent by changing hardcoded '2005' to @TaxYear
*				mh 12/02/08 - issue 123667.  Need to cycle through the Employees and EDL Codes mapped to HSA item 43.  Need
*								to get the absolute value of the annual total of the individual EDLCode and then add those together.
*				mh 07/28/09	- Issue 134984 - Initialize @hsatotal to 0. 
*				MattP 09/10/10 - Issue #137687- Removed Misc1Amt/Desc - Misc4Amt/Desc.
*				MV 09/21/10 - Issue #141113 - exclude item 50'New Hire Act Subject wages and tip' from 'Other' amts. Update bPRWA with
*					subject wages for Fed Soc Sec Liability for New Hire Act.  
*				CHS 12/29/2011 added code to exclude item 50 - new hire act for years other than 2010   
*				DAN SO 11/26/2012 - TK-19491/#147280 - Added case statement for Item 55 - need to SUM the ABS values - not take ABS of the SUM values
*				EN/CS 12/06/2012 D-04513/TK-19975/#145818 Changed to get zip extention from PREH if provided rather than just returning empty string
*				DAN SO 12/13/2012 - D-06327/#147677 - Modified fix for 11/26/2012 - TK-19491/#147280
*
* USAGE:
* Clear out PRWE, PRWS and PRWA for the PRCo and TaxYear and
* initialize federal W-2 information.
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
 
  declare @rcode int, @firstdayinyear char(10), @lastdayinyear char(10), @penplan char(1),
	@MiscFedDL3 int
 
  select @rcode = 0
 
  /* verify Tax Year Ending Month */
  if @TaxYear is null
  	begin
  	select @errmsg = 'Tax Year has not been selected.', @rcode = 1
  	goto bspexit
  	end
 
  /* clear entries from PRWE, PRWS and PRWA */
  delete bPRWE where PRCo=@PRCo and TaxYear=@TaxYear
  delete bPRWS where PRCo=@PRCo and TaxYear=@TaxYear
  delete bPRWL where PRCo=@PRCo and TaxYear=@TaxYear
  delete bPRWA where PRCo=@PRCo and TaxYear=@TaxYear
 
  /* Initialize Federal W-2 Information */
 
  /* set variables for first and last day in tax year */
  select @firstdayinyear = '01/01/' + @TaxYear
  select @lastdayinyear = '12/31/' + @TaxYear
 
  /* get pension plan from PRWH */
  select @penplan = PensionPlan from bPRWH
  where PRCo = @PRCo and TaxYear = @TaxYear
 
  /* basic PRWE information */
  -- issue 14712 - now we can get Suffix from bPREH
  insert bPRWE ( PRCo, TaxYear, Employee, SSN, FirstName, MidName, LastName, Suffix, LocAddress, DelAddress,
                 City, State, Zip, ZipExt, TaxState, Statutory, Deceased, PensionPlan, LegalRep, DeferredComp,
                 CivilStatus, SpouseSSN, Misc1Amt, Misc2Amt, Misc3Amt, Misc4Amt, SUIWages, SUITaxableWages, WeeksWorked ) --#26938
  select distinct h.PRCo, @TaxYear, h.Employee, substring(h.SSN, 1, 3) +
  	substring(h.SSN, 5, 2) + substring(h.SSN, 8, 4), h.FirstName, h.MidName, h.LastName,
  	h.Suffix, substring(h.Address2,1,22), substring(h.Address,1,40),
  	substring(h.City,1,22), h.State, substring(h.Zip, 1, 5),
  	ZipExt = CASE WHEN h.Country = 'US' OR h.Country IS NULL THEN 
				  (CASE WHEN LEN(SUBSTRING(dbo.vfStripNonNumerics(h.Zip),6,4)) = 4 
				   THEN SUBSTRING(dbo.vfStripNonNumerics(h.Zip),6,4) 
				   ELSE '' 
				   END)
			 END,
  	h.TaxState, Statutory = 0, Deceased = 0, CASE @penplan WHEN 'F' THEN (CASE WHEN
  	h.PensionYN = 'Y' THEN 1 ELSE 0 END) WHEN 'Y' THEN 1 ELSE 0 END, LegalRep = 0,
  	DeferredComp = 0, CivilStatus = null, SpouseSSN = '', 0, 0, 0, 0, 0, 0, 0 --#26938
  from bPREH h
  join bPREA a on a.PRCo = h.PRCo and a.Employee = h.Employee
  join bPRWC c on c.PRCo = h.PRCo and c.TaxYear = @TaxYear and c.EDLType = a.EDLType
  	and c.EDLCode = a.EDLCode
  where h.PRCo = @PRCo and a.Mth >= @firstdayinyear and a.Mth <= @lastdayinyear
 
 
 /* Begin Change
	MattP. 9/10/2010 Issue #137687
	Removed Misc1Amt/Desc - Misc4Amt/Desc. These values will now be contained in bPRWA ONLY.
 
  /* misc amounts for PRWE */
  update bPRWE
  set Misc1Amt = isnull((select abs(sum(CASE i.AmtType WHEN 'S' THEN a.SubjectAmt 
 				WHEN 'E' THEN a.EligibleAmt ELSE a.Amount END)) -- issue 20036  get abs of sum rather than sum of abs 
  	from bPREA a
  	join bPRWH h on h.PRCo = a.PRCo and h.TaxYear = e.TaxYear and h.Misc1EDLType = a.EDLType and h.Misc1EDLCode = a.EDLCode
  	join bPRWI i on i.TaxYear = h.TaxYear
  	where a.PRCo = e.PRCo and a.Employee = e.Employee and a.Mth >= @firstdayinyear
  	and a.Mth <= @lastdayinyear and i.Item = 40),0),
      Misc2Amt = isnull((select abs(sum(CASE i.AmtType WHEN 'S' THEN a.SubjectAmt 
 				WHEN 'E' THEN a.EligibleAmt ELSE a.Amount END)) -- issue 20036  get abs of sum rather than sum of abs 
  	from bPREA a
  	join bPRWH h on h.PRCo = a.PRCo and h.TaxYear = e.TaxYear and h.Misc2EDLType = a.EDLType and h.Misc2EDLCode = a.EDLCode
  	join bPRWI i on i.TaxYear = h.TaxYear
  	where a.PRCo = e.PRCo and a.Employee = e.Employee and a.Mth >= @firstdayinyear
  	and a.Mth <= @lastdayinyear and i.Item = 41),0),
 	--#26938
 	 Misc3Amt = isnull((select abs(sum(CASE i.AmtType WHEN 'S' THEN a.SubjectAmt 
 				WHEN 'E' THEN a.EligibleAmt ELSE a.Amount END))
  	from bPREA a
  	join bPRWH h on h.PRCo = a.PRCo and h.TaxYear = e.TaxYear and h.Misc3EDLType = a.EDLType and h.Misc3EDLCode = a.EDLCode
  	join bPRWI i on i.TaxYear = h.TaxYear
  	where a.PRCo = e.PRCo and a.Employee = e.Employee and a.Mth >= @firstdayinyear
  	and a.Mth <= @lastdayinyear and i.Item = 46),0),
      Misc4Amt = isnull((select abs(sum(CASE i.AmtType WHEN 'S' THEN a.SubjectAmt 
 				WHEN 'E' THEN a.EligibleAmt ELSE a.Amount END))
  	from bPREA a
  	join bPRWH h on h.PRCo = a.PRCo and h.TaxYear = e.TaxYear and h.Misc4EDLType = a.EDLType and h.Misc4EDLCode = a.EDLCode
  	join bPRWI i on i.TaxYear = h.TaxYear
  	where a.PRCo = e.PRCo and a.Employee = e.Employee and a.Mth >= @firstdayinyear
  	and a.Mth <= @lastdayinyear and i.Item = 47),0)
  from bPRWE e
  where PRCo = @PRCo and TaxYear = @TaxYear
 
  update bPRWE
  set Misc1Amt = Misc1Amt + isnull((select abs(sum(CASE i.AmtType WHEN 'S' THEN a.SubjectAmt 
 				WHEN 'E' THEN a.EligibleAmt ELSE a.Amount END)) -- issue 20036  get abs of sum rather than sum of abs 
  	from bPREA a
  	join bPRWC c on c.PRCo=a.PRCo and c.TaxYear = e.TaxYear and c.EDLType = a.EDLType
  		and c.EDLCode=a.EDLCode
  	join bPRWI i on i.TaxYear=c.TaxYear and i.Item=c.Item
  	where a.PRCo = e.PRCo and a.Employee = e.Employee and a.Mth >= @firstdayinyear
  	and a.Mth <= @lastdayinyear and c.Item = 40),0),
      Misc2Amt = Misc2Amt + isnull((select abs(sum(CASE i.AmtType WHEN 'S' THEN a.SubjectAmt 
 				WHEN 'E' THEN a.EligibleAmt ELSE a.Amount END)) -- issue 20036  get abs of sum rather than sum of abs 
  	from bPREA a
  	join bPRWC c on c.PRCo = a.PRCo and c.TaxYear = e.TaxYear and c.EDLType = a.EDLType
  		and c.EDLCode = a.EDLCode
  	join bPRWI i on i.TaxYear = c.TaxYear and i.Item = c.Item
  	where a.PRCo = e.PRCo and a.Employee = e.Employee and a.Mth >= @firstdayinyear
  	and a.Mth <= @lastdayinyear and c.Item = 41),0),
 	--#26938
 	 Misc3Amt = Misc3Amt + isnull((select abs(sum(CASE i.AmtType WHEN 'S' THEN a.SubjectAmt 
 				WHEN 'E' THEN a.EligibleAmt ELSE a.Amount END))
  	from bPREA a
  	join bPRWC c on c.PRCo=a.PRCo and c.TaxYear = e.TaxYear and c.EDLType = a.EDLType
  		and c.EDLCode=a.EDLCode
  	join bPRWI i on i.TaxYear=c.TaxYear and i.Item=c.Item
  	where a.PRCo = e.PRCo and a.Employee = e.Employee and a.Mth >= @firstdayinyear
  	and a.Mth <= @lastdayinyear and c.Item = 46),0),
      Misc4Amt = Misc4Amt + isnull((select abs(sum(CASE i.AmtType WHEN 'S' THEN a.SubjectAmt 
 				WHEN 'E' THEN a.EligibleAmt ELSE a.Amount END))
  	from bPREA a
  	join bPRWC c on c.PRCo = a.PRCo and c.TaxYear = e.TaxYear and c.EDLType = a.EDLType
  		and c.EDLCode = a.EDLCode
  	join bPRWI i on i.TaxYear = c.TaxYear and i.Item = c.Item
  	where a.PRCo = e.PRCo and a.Employee = e.Employee and a.Mth >= @firstdayinyear
  	and a.Mth <= @lastdayinyear and c.Item = 47),0)
  from bPRWE e
  where PRCo = @PRCo and TaxYear = @TaxYear
 
 
 
  MattP. 9/10/2010 Issue #137687
  End Change*/
 
 
  /* get federal/social security/medicare amounts */
  insert bPRWA ( PRCo, TaxYear, Employee, Item, Amount, Seq)
  select a.PRCo, @TaxYear, h.Employee, c.Item, 
  	Amount = sum(CASE i.AmtType WHEN 'S' THEN a.SubjectAmt WHEN 'E' THEN a.EligibleAmt ELSE a.Amount END), 1
  from bPREH h
  join bPREA a on a.PRCo = h.PRCo and a.Employee = h.Employee
  join bPRWC c on c.PRCo = h.PRCo and c.TaxYear = @TaxYear and c.EDLType = a.EDLType
  	and c.EDLCode = a.EDLCode
  join bPRWI i on i.TaxYear = c.TaxYear and i.Item = c.Item
  where h.PRCo = @PRCo and a.Mth >= @firstdayinyear and a.Mth <= @lastdayinyear and c.Item >=1 and c.Item <=6
  group by a.PRCo, h.Employee, c.Item
 
  /* enforce social security and medicare limits */
  /* note: remmed out because it looks like we don't need this since eligible amount is used */
  /*update bPRWA
  set Amount = CASE d.LimitBasis WHEN 'S' THEN
  	(CASE WHEN a.Amount > d.LimitAmt THEN d.LimitAmt ELSE a.Amount END)
  	WHEN 'C' THEN
  	(CASE WHEN a.Amount > d.LimitAmt/d.RateAmt1 THEN d.LimitAmt/d.RateAmt1 ELSE a.Amount END)
  	ELSE a.Amount END
  from bPRWA a, bPRWC c, bPRDL d
  where a.PRCo = @PRCo and a.TaxYear = @TaxYear and (a.Item = 3 or a.Item = 5)
  	and c.PRCo = a.PRCo and c.TaxYear = a.TaxYear and c.Item = a.Item and c.EDLType = 'D'
  	and d.PRCo = a.PRCo and d.DLCode = c.EDLCode*/
 
  /* warn user if any negative federal/social security/medicare accums exist */
  delete from bPRWA
  where PRCo = @PRCo and TaxYear = @TaxYear and Item >= 1 and Item <= 6 and Amount < 0
  if @@rowcount <> 0
  	begin
  	 select @errmsg = 'Warning: Negative Fed/FICA/Medicare amounts were found and will not be included on W-2(s).', @rcode = 5
  	end
 
 -- OLD CODE -- BEFORE D-06327/#147677 --
 ---------- /* get other amounts */
 -------- INSERT dbo.bPRWA ( PRCo, TaxYear, Employee, Item, Amount, Seq )
 -------- SELECT a.PRCo, @TaxYear, h.Employee, c.Item, 
	-------- -- TK-19491/#147280 --
 --------    --CASE c.Item WHEN '55' THEN SUM(ABS(a.Amount)) ELSE 
	--------	ABS(SUM(CASE i.AmtType WHEN 'S' THEN a.SubjectAmt WHEN 'E' THEN a.EligibleAmt ELSE a.Amount END)) --END
	--------, 1 -- issue 15746 - get abs of sum rather than sum of abs 
 -------- FROM dbo.bPREH h
 -------- JOIN dbo.bPREA a ON a.PRCo = h.PRCo AND a.Employee = h.Employee
 -------- JOIN dbo.bPRWC c ON c.PRCo = h.PRCo AND c.TaxYear = @TaxYear AND c.EDLType = a.EDLType
 -------- 	AND c.EDLCode = a.EDLCode
 -------- JOIN dbo.bPRWI i ON i.TaxYear = c.TaxYear AND i.Item = c.Item
 -------- WHERE h.PRCo = @PRCo 
	--------AND a.Mth >= @firstdayinyear 
	--------AND a.Mth <= @lastdayinyear
	---------- issue 137687 do not exclude items 40 and 41 anymore - issue 11918 --issue 119749 also exclude item 43 (Code W)
	---------- issue #141113 exclude item 50 New Hire Act Subject wages and tips
 -------- 	AND c.Item >=7 AND c.Item <> 43 AND c.Item <> 50 
 -------- GROUP BY a.PRCo, h.Employee, c.Item

-- NEW CODE -- AFTER D-06327/#147677 --
  INSERT dbo.bPRWA (PRCo, TaxYear, Employee, Item, Amount, Seq)
  SELECT  PRCo, @TaxYear, Employee, Item, SUM(ABS(MyEDL)), 1 
	FROM (
	  SELECT a.PRCo, h.Employee, c.Item,
			 SUM(CASE c.EDLType 
				WHEN 'E' THEN 
					CASE i.AmtType WHEN 'S' THEN a.SubjectAmt WHEN 'E' THEN a.EligibleAmt ELSE a.Amount END
				WHEN 'D' THEN 
					CASE i.AmtType WHEN 'S' THEN a.SubjectAmt WHEN 'E' THEN a.EligibleAmt ELSE a.Amount END
				WHEN 'L' THEN 
					CASE i.AmtType WHEN 'S' THEN a.SubjectAmt WHEN 'E' THEN a.EligibleAmt ELSE a.Amount END
				ELSE
					0
				END) AS MyEDL
	    FROM dbo.bPREH h
	    JOIN dbo.bPREA a ON a.PRCo = h.PRCo AND a.Employee = h.Employee
	    JOIN dbo.bPRWC c ON c.PRCo = h.PRCo AND c.TaxYear = @TaxYear AND c.EDLType = a.EDLType
  	     AND c.EDLCode = a.EDLCode
	    JOIN dbo.bPRWI i ON i.TaxYear = c.TaxYear AND i.Item = c.Item
	   WHERE h.PRCo = @PRCo 
		 AND a.Mth >= @firstdayinyear  
		 AND a.Mth <= @lastdayinyear
		-- issue 137687 do not exclude items 40 and 41 anymore - issue 11918 --issue 119749 also exclude item 43 (Code W)
		-- issue #141113 exclude item 50 New Hire Act Subject wages and tips
  		 AND c.Item >=7 AND c.Item <> 43 AND c.Item <> 50 
	GROUP BY a.PRCo, h.Employee, c.Item, c.EDLType
  ) MyGroup
  GROUP BY PRCo, Employee, Item




 /*	Get subject wages for Fed Soc Sec Liability for New Hire Act - Issue #141113
	For New Hire Act, only include wages paid 3/19/2010 or later if employee was eligible earlier,
	or wages paid after employee's eligible date. End date will be null if employee is still eligible */
	-- Fed Info Soc Sec Liability Code
	SELECT @MiscFedDL3 = MiscFedDL3 
	FROM dbo.bPRFI
	WHERE PRCo=@PRCo
	
	INSERT bPRWA ( PRCo, TaxYear, Employee, Item, Amount, Seq )
	SELECT  @PRCo, @TaxYear, e.Employee, 50, ABS(SUM(d.EligibleAmt)), 1
	FROM dbo.PRDT d
	JOIN dbo.PRSQ s ON d.PRCo=s.PRCo AND d.PRGroup=s.PRGroup AND d.Employee=s.Employee AND d.PaySeq=s.PaySeq AND d.PREndDate=s.PREndDate
	JOIN dbo.PREH e ON e.PRCo=d.PRCo AND e.Employee=d.Employee
	WHERE d.PRCo=@PRCo
		AND EDLType='L' 
		AND EDLCode=@MiscFedDL3
		AND (
						(s.PaidDate >= '2010/03/19' AND e.NewHireActStartDate < '2010/03/19') 
					OR	(s.PaidDate >= e.NewHireActStartDate AND e.NewHireActStartDate >= '2010/03/18')
				) 
		AND s.PaidDate <= ISNULL(e.NewHireActEndDate,'2010/12/31') 
		AND @TaxYear = '2010'		
	GROUP BY e.PRCo, e.Employee

/*Issue 123667 - Per Andrew need to get the absolute values of the total for each EDLCode mapped to Item 43 then add those
absolute values together.  Since we cannot know how many codes the user has mapped to Item 43 in bPRWC we must use a 
cursor to cycle through them.

  --old code
  /* issue 119749 get amts for item 43 (Code W) here -- same as previous code but gets sum of abs rather than abs of sum */
  insert bPRWA ( PRCo, TaxYear, Employee, Item, Amount, Seq )
  select a.PRCo, @TaxYear, h.Employee, c.Item,  --issue 122912 changed '2005' to @TaxYear
  	sum(abs(a.Amount)), 1
  from bPREH h
  join bPREA a on a.PRCo = h.PRCo and a.Employee = h.Employee
  join bPRWC c on c.PRCo = h.PRCo and c.TaxYear = @TaxYear and c.EDLType = a.EDLType
  	and c.EDLCode = a.EDLCode
  join bPRWI i on i.TaxYear = c.TaxYear and i.Item = c.Item
  where h.PRCo = @PRCo and a.Mth >= @firstdayinyear and a.Mth <= @lastdayinyear
  	and c.Item = 43
  group by a.PRCo, h.Employee, c.Item
*/

declare @edltype varchar(20), @edlcode bEDLCode, @hsatotal decimal(12,2), @employee bEmployee,
@openedlcurs tinyint, @openempcurs tinyint

declare cEmps cursor local fast_forward for 
select distinct a.Employee 
from bPREH h 
join bPREA a on h.PRCo = a.PRCo and h.Employee = a.Employee
where h.PRCo = @PRCo and a.Mth >= @firstdayinyear and a.Mth <= @lastdayinyear

open cEmps
select @openempcurs = 1

fetch next from cEmps into @employee

while @@fetch_status = 0
begin

	declare cEDLCodes cursor local fast_forward for 
	select EDLType, EDLCode from bPRWC where PRCo = @PRCo and TaxYear = @TaxYear and
	Item = 43

	open cEDLCodes
	select @openedlcurs = 1

	fetch next from cEDLCodes into @edltype, @edlcode

	--Issue 134984 - Initialize @hsatotal to 0.  
	select @hsatotal = 0

	while @@fetch_status = 0
	begin
		select @hsatotal = @hsatotal + abs(isnull(sum(Amount),0)) 
		from bPREA 
		where PRCo = @PRCo and EDLType = @edltype and EDLCode = @edlcode and Employee = @employee
		and (Mth >= @firstdayinyear and Mth <= @lastdayinyear)

		fetch next from cEDLCodes into @edltype, @edlcode
	end

	close cEDLCodes
	deallocate cEDLCodes
	select @openedlcurs = 0

	if @hsatotal > 0
	begin
		--only insert if we have a value.
		insert bPRWA(PRCo, TaxYear, Employee, Item, Amount, Seq)
		values(@PRCo, @TaxYear, @employee, 43, @hsatotal, 1)
	end

	select @hsatotal = 0
	fetch next from cEmps into @employee

end


if @openedlcurs = 1
begin
	close cEDLCodes
	deallocate cEDLCodes
end

if @openempcurs = 1
begin
	close cEmps
	deallocate cEmps
end

--End Issue 123667
  
   /* set DeferredComp flags in PRWE */
  update bPRWE
  set DeferredComp = (select CASE WHEN (select count(*) from bPRWA a, bPRWI i where i.TaxYear = a.TaxYear and i.Item = a.Item
  		    and a.PRCo = bPRWE.PRCo and a.TaxYear =  bPRWE.TaxYear and a.Employee =  bPRWE.Employee
  		    and (i.W2Code = 'D' or i.W2Code = 'E' or i.W2Code = 'F' or i.W2Code = 'G'
  		     or i.W2Code = 'H')) = 0 THEN 0 ELSE 1 END)
  from bPRWE
  where  bPRWE.PRCo = @PRCo and bPRWE.TaxYear = @TaxYear
 
 
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRW2InitFed] TO [public]
GO
