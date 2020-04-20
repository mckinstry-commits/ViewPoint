SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vrptPR940SchedAStateInfo] 
/************************************************************************
        
Author:     
Scott Alvey     
       
Create date:     
10/17/2011        
        
Usage:     
Used in Form 940 Schedule A reporting. Procedure returns two sets of data, difference being determined by the     
SummaryFlag column in the last select statement. A flag value of 'S' means the row is a summary row. It sums FUTA     
subject earning amounts by state for the reporting year. A flag of 'D' shows the individual employee records     
that make up state sum values. PRTH and PRTA PostDate values are used to detrmine down to the day what employee    
worked in what state in a given PREndDate value as many PostDates could have a single PREndDate value.    
    
**RATES NEED TO BE REVIEWED AT PRIOR TO END OF YEAR TAX UPDTES**    
    
Things to keep in mind regarding this report and proc:    
The most important thing about this report is its chronilogical ordering of data. FUTA has a cap (currently $7000)    
and an employee can meet this cap while working in a single state or while working in multiple states. If the    
cap is met via working in multiple states then the dollar amount each state worked in gets is determined by when    
the employee worked in that state. If the employee works in State A for the month of January for a total of $4000    
of taxable wages then works in State B for the month of February for a total of $5000 of taxable wages then     
State A will ready $4000 and State B will read $3000 of taxable earnings. The day the employee worked in a state is     
determined by PostDate in PRTH, and an employee may work in many states while keeping the same PostDate (think    
New England states). So the chronilogical order is based off of PostDate.    
        
Parameters:         
@PRCo - reporting Viewpoint company          
@Year - reporting year          
@FUTACap - earnings cap set by US Tax Code - may change year to year     
@UnemploymentState - testing purposes only - for limiting results to a certain state - NOT currently used in the report    
@Employee - testing purposes only - for limiting results to a certain employee - NOT currently used in the report    
@AuditFlag - testing purposes only - for limiting results to a certain employee - NOT currently used in the report    
    
Note regarding parameters:    
As of 1/30/12 there is no audit report for the 940 Schedule A report. This stored procedure can be used to drive    
a potential audit report and it currently designed in preparation for such a report. The @UnemploymentState, @Employee,    
and @AuditFlag params can be enabled and used by an audit report to return data for just a subset of employees or states.    
The current 940 Schedule A report would need to be modified to see these new params (it currently only sees the first 3)     
and then these new params would be hidden in the report report launcher. The 940 Schedule A report would pass the values    
of 'ZZ', 0, and 'R' for the @UnemploymentState, @Employee, and @AuditFlag params respectively so that it could    
continue to return data for all states and all employees in the reporting year. The new audit report would be designed    
to expose the first five params with the @AuditFlag param beign hidden and being set to pass a value of 'A'. The If\Else    
statement after population of the #tmpPayrollAll temp table would need to be enabled (along with where statements in    
ctePRAddons and ctePRHeader that look to @UnemploymentState and @Employee) for this to work properly. The If\Else statement    
would see a value of 'A' and then return the temp table which is just a combo of PRTA and PRTH in the reporting year.     
Since this temp table is an unmodified look to the PRTA and PRTH (modification occurs in the cteFirstRecord and     
cteRecursion areas) it would be a valid audit. The Audit report would have to be designed to group records in a logical    
way that would be easy to read and audit.    
    
All this audit code is turned off currently    
        
Related reports:     
PR 940 Schedule A (ID#: 976)        
        
Revision History        
Date  Author  Issue     Description        
11/10/2011 ScottAlvey CL-144151 / V1-B-06143 Previous PR 940 Schedule A report had multiple subreports        
            to figure out what states were being reported on.        
            Combining all subreports into this proc for performance        
            reasons and due to the layout change of the related IRS form.        
            This proc now will include EIN, Company Name, states FUTA         
            reduction rates, and the reduction values. Final select statement has 'S' records     
            meant to signify a summary line (used in related report above) and    
            'D' records meant to feed an audit report that will be made in the future    
                  
12/08/2011 Czeslaw  CL-145230 / V1-B-08099 In final Select statement, updated state-specific reduction rate         
            factors as needed, per IRS figures for 2011 available as of        
            2011-1207; added ROUND() function with precision length '2'         
            to every expression that calculates a state Credit Reduction value        
            in order to remedy rounding errors in credit total in the report.    
                
01/09/2012 ScottAlvey CL-145466 / V1-D-04240 - Report performance suffering    
   Customers with large datasets in PRTH may see this proc perform poorly, possibly    
   due to multiple CTEs, but not fully certain as to why. Removed second half of    
   union statement in final data select as the audit report has not been created yet    
   and modified the look in to PRSQ.PaidDate in PREmpListForYearwithPRTA and     
   PREmpListForYear to look to a range of dates.    
    
01/30/2012 ScottAlvey CL-145628 / V1-D-04385 - Further reporting performance changes    
   Due to poor performance results still found in this proc it has been fully    
   rewritten to use less CTEs and introduces a recursive method. Testing agaist    
   large datasets have resulted in very fast performance. Also added some    
   auditing code that can be turned off and on. Currently this code is turned off    
   but can be turned on and then used to drive a future audit report. See notes    
   surrounding audit code for more info. Notes regarding audit params are above.    
  
12/26/2012 DML CL-147739 / V1-D-06375 - Updated tax rates for 2012.   
  
01/15/2013 ScottAlvey CL-147846 / V1-D-06512 - report is returning too high a value if a high  
 earner (making more then 7k in one row in PRTH/PRTA combined) is paid a higher than 7k amount  
 the very first record for that employee in the reporting year.  
  
11/26/2013 DML TFS 67754 - Updated tax rates for 2013 and .pdf overlay.  

12/12/2013 Dan Sochacki - Bug:57150 - COMPLETE REWRITE - using PRDT values instead of detail 
	values from multiple tables.  
	
	Steps:
		1. Set up @Year variable with a time stamp from the beginning of the 
			incoming Year and just a few millseconds before Mid-Night of the 
			next Year.
		2. Get a few basic values
		3. Check and create #EmployeeSUTA and #CritialPPD  
			- #EmployeeSUTA: holds FUTA and SUTA values per Employee upto and including the Pay Period
							where the FUTA limit was reached.
			- #CritialPPD: Holds the FUTA amount, FUTA Total, and PREndDate when the FUTA limit was reached
		4. Populate #CritialPPD
		5. Populate #EmployeeSUTA
		6. SELECT State FUTA and State FUTA after Discount from #EmployeeSUTA
		7. There are few queries at the bottom of the stored procedure specifically for Customer Support
			- They need a way to look at what was data selected and how the values were computed.

01/30/2014 EN - TFS-73761/Task 73764 Fixed three select statements where PRDT_PREndDate was used to 
	determine wages to be reported based on a range of dates (@StartYear through @EndYear).  Actually we need 
	to check the paid date rather than the period ending date because there may be wages in a pay period indicating
	one year that are actually paid and needing to be reported in the next (or previous year).  To resolve I joined 
	PRSQ and used PRSQ_PaidDate for the date comparison.

01/31/2014 Dan Sochacki - US:73761/Task:73951 - Carried PaidDate through out the entire procedure and modified
		a few queries to handle multiple pay sequences for that PaidDate.

01/31/2014 Dan Sochacki	- US:73761/Task:73951 - Discovered another issue with related to employee who was
		paid in the new year, but the PREndDate was last year and he did not meet the FUTA limit - NULLS 
		were inserted into temp table.  Problem was in the query for determing FUTAEligAmt - referencing
		PREndDate - fix to reference PaidDate.
*************************************************************************/
(@PRCo bCompany, @Year INT, @FUTACap INT)

AS 
	SET NOCOUNT ON

	
	DECLARE @FUTACode bEDLCode, 
			@StartYear DateTime, 
			@EndYear DateTime,
			@CompanyName VARCHAR(60),
			@FedTaxID VARCHAR(20)

	----------------
	-- SETUP YEAR --
	----------------
	SET @Year = @Year - DATEPART(yyyy, 0)
	SET @StartYear = DATEADD(Year, @Year, 0);      
	SET @EndYear = DATEADD(ms, -3, DATEADD(Year, @Year+1 ,0)); 

	------------------------------
	-- GET HQCO DATA FOR REPORT --
	------------------------------
	SELECT	@CompanyName = Name, @FedTaxID = FedTaxId
	  FROM	dbo.bHQCO
	 WHERE	HQCo = @PRCo
	
	-------------------------------
	-- GET FUTA DLCode and Limit --
	-------------------------------
	SELECT	@FUTACode = fi.FUTALiab
	  FROM	dbo.bPRFI AS fi
	  JOIN	dbo.bPRDL AS dl 
		ON	fi.PRCo = dl.PRCo AND fi.FUTALiab = dl.DLCode
	 WHERE	fi.PRCo=@PRCo

	------------------------------------------------
	-- SET UP TABLES TO HOLD SUTA AND FUTA VALUES --
	------------------------------------------------
	-- HOLD EMPLOYEE SUTA VALUES --
	IF OBJECT_ID('tempdb..#EmployeeSUTA') IS NOT NULL BEGIN DROP TABLE #EmployeeSUTA END
	CREATE TABLE #EmployeeSUTA
		(
			Employee		int
			,SUTALiab		smallint
			,[State]		varchar(4)
			,PaidDate		smalldatetime
			,CurrSUTAAmt	decimal(10,2)	-- SUTA amount to be added to final State total
			,TotalSUTAAmt	decimal(10,2)	-- Total SUTA for PPD
			,FUTAEligAmt	decimal(10,2)	-- Amount of FUTA eligible for PPD
			,Factor			decimal(10,4)	-- will be less than 1 when spreading SUTA across multiple state for same pay period
			,FinalFUTAAmt	decimal(10,2)	-- FUTAEligAmt * Factor 
		)
		
	-- HOLD VALUES OF WHEN FUTA LIMIT HAS BEEN REACHED --
	IF OBJECT_ID('tempdb..#CritialPPD') IS NOT NULL BEGIN DROP TABLE #CritialPPD END
	CREATE TABLE #CritialPPD
		(
			Employee		int
			,FUTATotal		decimal(10,2)   -- Total eligible FUTA amount 
			,CurrFUTAAmt	decimal(10,2)   -- FUTA Amount from last paid period when FUTA limit has been reached
			,PaidDate		smalldatetime
		)
		

	-------------------------------------------------------
	-- GET PAY PERIOD AND FUTA AMOUNT WHEN FUTA <= LIMIT -- Critical PD
	-------------------------------------------------------
	-- p = previous -- n = next
	;WITH cteFUTA
		AS (
			SELECT	dt.Employee, SUM(dt.EligibleAmt) AS EligibleAmt, sq.PaidDate,
					ROW_NUMBER() OVER (PARTITION BY dt.Employee ORDER BY dt.Employee, sq.PaidDate) AS RowNum
		      FROM	dbo.bPRDT AS dt
		      JOIN	dbo.bPRSQ AS sq ON	sq.PRCo = dt.PRCo
									AND	sq.PRGroup = dt.PRGroup
									AND	sq.PREndDate = dt.PREndDate
									AND	sq.Employee = dt.Employee
									AND	sq.PaySeq = dt.PaySeq	
		     WHERE	dt.PRCo = @PRCo 
		       AND	dt.EDLType = 'L'
		       AND	dt.EDLCode = @FUTACode
		       AND	sq.PaidDate	BETWEEN @StartYear AND @EndYear
		       GROUP BY dt.Employee, sq.PaidDate
		   ),
	cteRunningFUTA
		AS
		   (
			SELECT	Employee, 
					CONVERT(DECIMAL(19,2),EligibleAmt) AS EligibleAmt, 
					PaidDate, RowNum,
					CONVERT(DECIMAL(19,2),EligibleAmt) AS RunningTotal
			  FROM	cteFUTA
			 WHERE	RowNum = 1

			UNION ALL 

			SELECT	n.Employee, 
					CONVERT(DECIMAL(19,2),n.EligibleAmt) AS EligibleAmt, 
					n.PaidDate, n.RowNum,
					CONVERT(DECIMAL(19,2),p.RunningTotal + n.EligibleAmt) AS RunningTotal
		      FROM	cteRunningFUTA AS p
			  JOIN	cteFUTA AS n ON n.Employee = p.Employee AND p.RowNum + 1 = n.RowNum
			 WHERE	CONVERT(DECIMAL(19,2),p.RunningTotal) <= @FUTACap
		   )
    
	--------------------------------------------------
	-- POPULATE WITH PD's WHERE FUTUA LIMIT WAS MET --
	--------------------------------------------------
	-- Paid Date when FUTA limit has been reached - used to Ratio amounts  --
	-- when Employee has worked in multiple states						   --
	INSERT INTO	#CritialPPD
				(Employee, CurrFUTAAmt, FUTATotal   , PaidDate) 
         SELECT	 Employee, EligibleAmt, RunningTotal, PaidDate 
		   FROM cteRunningFUTA r1
		  WHERE RunningTotal >= @FUTACap AND EligibleAmt > 0
		  --AND r1.RowNum =
		  --  (
		  --  SELECT MAX(RowNum)
		  --  FROM cteRunningFUTA r2
		  --  WHERE r1.Employee = r2.Employee
		  --  AND r1.PaidDate = r2.PaidDate
		  --  )
         OPTION (MAXRECURSION 0)
         
	------------------------------------------
	-- POPULATE WITH SUTA UNTIL CRITICAL PD -- 
	------------------------------------------		
	INSERT INTO	#EmployeeSUTA 
				(Employee, SUTALiab, State, CurrSUTAAmt, PaidDate, Factor)     
	     SELECT	dt.Employee, Codes.SUTALiab, Codes.State, dt.EligibleAmt, sq.PaidDate, 1 
	       FROM	dbo.bPRDT AS dt 
		   JOIN dbo.bPRSQ AS sq ON	sq.PRCo = dt.PRCo
								AND	sq.PRGroup = dt.PRGroup
								AND	sq.PREndDate = dt.PREndDate
								AND	sq.Employee = dt.Employee
								AND	sq.PaySeq = dt.PaySeq	
	  LEFT JOIN #CritialPPD  AS CritPPD
			 ON dt.Employee = CritPPD.Employee 
	       JOIN (SELECT si.SUTALiab, si.PRCo, si.State
			       FROM	dbo.bPRSI AS si 
			       JOIN dbo.bPRDL AS dl ON si.PRCo=dl.PRCo AND si.SUTALiab=dl.DLCode) AS Codes 
		     ON	dt.PRCo = Codes.PRCo AND dt.EDLCode = Codes.SUTALiab
	      WHERE	dt.PRCo = @PRCo 
	        AND	dt.EDLType = 'L'
	        AND	sq.PaidDate	BETWEEN @StartYear AND @EndYear
			AND (sq.PaidDate <= CritPPD.PaidDate OR CritPPD.PaidDate IS NULL)

	-- UPDATE AMOUNTS --  Split from the above statement for simpler query --
	UPDATE EmpSUTA
	SET EmpSUTA.FUTAEligAmt = 
	    (
	    SELECT SUM(dt.EligibleAmt)
	    FROM dbo.bPRDT AS dt 
			JOIN dbo.bPRSQ AS sq ON	sq.PRCo = dt.PRCo
							AND	sq.PRGroup = dt.PRGroup
							AND	sq.PREndDate = dt.PREndDate
							AND	sq.Employee = dt.Employee
							AND	sq.PaySeq = dt.PaySeq
		WHERE EmpSUTA.Employee = dt.Employee  
		AND EmpSUTA.PaidDate = sq.PaidDate
		AND dt.PRCo = @PRCo 
		AND	dt.EDLType = 'L'
		AND sq.PaidDate BETWEEN @StartYear AND @EndYear
		AND dt.EDLCode = @FUTACode
	    )
		,EmpSUTA.TotalSUTAAmt = (SELECT SUM(ta_sum.CurrSUTAAmt) 
								  FROM #EmployeeSUTA AS ta_sum 
							     WHERE EmpSUTA.Employee = ta_sum.Employee 
								   AND EmpSUTA.PaidDate = ta_sum.PaidDate),
		EmpSUTA.Factor = EmpSUTA.CurrSUTAAmt / (SELECT CASE WHEN SUM(ta_sum.CurrSUTAAmt) > 0 
															THEN  SUM(ta_sum.CurrSUTAAmt) 
															ELSE 1 END
												  FROM #EmployeeSUTA AS ta_sum 
												 WHERE EmpSUTA.Employee = ta_sum.Employee 
												   AND EmpSUTA.PaidDate = ta_sum.PaidDate)
	   FROM #EmployeeSUTA EmpSUTA  
  
	-------------------------------------------------------------------------------------------
	-- UPDATE @EmployeeSUTA WITH CALCULATED RATIO AND FUTA VALUES FOR THE CRITICAL PAID DATE --
	------------------------------------------------------------------------------------------- 
	UPDATE EmpSUTA
	  SET EmpSUTA.FUTAEligAmt = CurrFUTAAmt - (CritPPD.FUTATotal - @FUTACap), 
		  EmpSUTA.Factor = (SELECT EmpSUTA.CurrSUTAAmt / (SELECT CASE WHEN SUM(ta_sum.CurrSUTAAmt) > 0 THEN  SUM(ta_sum.CurrSUTAAmt) ELSE 1 END
															FROM #EmployeeSUTA AS ta_sum 
														   WHERE EmpSUTA.Employee = ta_sum.Employee 
															 AND EmpSUTA.PaidDate = ta_sum.PaidDate) AS Ratio)
	 FROM #EmployeeSUTA EmpSUTA
	 JOIN #CritialPPD AS CritPPD
	   ON EmpSUTA.Employee = CritPPD.Employee 
	  AND EmpSUTA.PaidDate = CritPPD.PaidDate

   ---------------------------------
   -- CALCULATE FINAL FUTA AMOUNT -- ROUND to 2 decimals
   ---------------------------------
   UPDATE EmpSUTA
	  SET FinalFUTAAmt = ROUND((FUTAEligAmt * Factor), 2)
     FROM #EmployeeSUTA EmpSUTA
     
	----------------------------------
	-- TOTALS FOR ALL STATES WORKED --
	----------------------------------	
	SELECT 'S' AS SummaryFlag, @FedTaxID AS FedTaxId, @CompanyName AS Name
	   , SUM(CASE WHEN State='AK' THEN FinalFUTAAmt ELSE 0 END) AS AKAmount            
	   , SUM(CASE WHEN State='AL' THEN FinalFUTAAmt ELSE 0 END) AS ALAmount            
	   , SUM(CASE WHEN State='AR' THEN FinalFUTAAmt ELSE 0 END) AS ARAmount            
	   , SUM(CASE WHEN State='AZ' THEN FinalFUTAAmt ELSE 0 END) AS AZAmount            
	   , SUM(CASE WHEN State='CA' THEN FinalFUTAAmt ELSE 0 END) AS CAAmount          
	   , SUM(CASE WHEN State='CO' THEN FinalFUTAAmt ELSE 0 END) AS COAmount            
	   , SUM(CASE WHEN State='CT' THEN FinalFUTAAmt ELSE 0 END) AS CTAmount            
	   , SUM(CASE WHEN State='DC' THEN FinalFUTAAmt ELSE 0 END) AS DCAmount            
	   , SUM(CASE WHEN State='DE' THEN FinalFUTAAmt ELSE 0 END) AS DEAmount            
	   , SUM(CASE WHEN State='FL' THEN FinalFUTAAmt ELSE 0 END) AS FLAmount            
	   , SUM(CASE WHEN State='GA' THEN FinalFUTAAmt ELSE 0 END) AS GAAmount            
	   , SUM(CASE WHEN State='HI' THEN FinalFUTAAmt ELSE 0 END) AS HIAmount            
	   , SUM(CASE WHEN State='IA' THEN FinalFUTAAmt ELSE 0 END) AS IAAmount            
	   , SUM(CASE WHEN State='ID' THEN FinalFUTAAmt ELSE 0 END) AS IDAmount            
	   , SUM(CASE WHEN State='IL' THEN FinalFUTAAmt ELSE 0 END) AS ILAmount            
	   , SUM(CASE WHEN State='IN' THEN FinalFUTAAmt ELSE 0 END) AS INAmount            
	   , SUM(CASE WHEN State='KS' THEN FinalFUTAAmt ELSE 0 END) AS KSAmount            
	   , SUM(CASE WHEN State='KY' THEN FinalFUTAAmt ELSE 0 END) AS KYAmount            
	   , SUM(CASE WHEN State='LA' THEN FinalFUTAAmt ELSE 0 END) AS LAAmount            
	   , SUM(CASE WHEN State='MA' THEN FinalFUTAAmt ELSE 0 END) AS MAAmount            
	   , SUM(CASE WHEN State='MD' THEN FinalFUTAAmt ELSE 0 END) AS MDAmount            
	   , SUM(CASE WHEN State='ME' THEN FinalFUTAAmt ELSE 0 END) AS MEAmount            
	   , SUM(CASE WHEN State='MI' THEN FinalFUTAAmt ELSE 0 END) AS MIAmount            
	   , SUM(CASE WHEN State='MN' THEN FinalFUTAAmt ELSE 0 END) AS MNAmount            
	   , SUM(CASE WHEN State='MO' THEN FinalFUTAAmt ELSE 0 END) AS MOAmount            
	   , SUM(CASE WHEN State='MS' THEN FinalFUTAAmt ELSE 0 END) AS MSAmount            
	   , SUM(CASE WHEN State='MT' THEN FinalFUTAAmt ELSE 0 END) AS MTAmount            
	   , SUM(CASE WHEN State='NC' THEN FinalFUTAAmt ELSE 0 END) AS NCAmount            
	   , SUM(CASE WHEN State='ND' THEN FinalFUTAAmt ELSE 0 END) AS NDAmount            
	   , SUM(CASE WHEN State='NE' THEN FinalFUTAAmt ELSE 0 END) AS NEAmount            
	   , SUM(CASE WHEN State='NH' THEN FinalFUTAAmt ELSE 0 END) AS NHAmount            
	   , SUM(CASE WHEN State='NJ' THEN FinalFUTAAmt ELSE 0 END) AS NJAmount            
	   , SUM(CASE WHEN State='NM' THEN FinalFUTAAmt ELSE 0 END) AS NMAmount            
	   , SUM(CASE WHEN State='NV' THEN FinalFUTAAmt ELSE 0 END) AS NVAmount            
	   , SUM(CASE WHEN State='NY' THEN FinalFUTAAmt ELSE 0 END) AS NYAmount            
	   , SUM(CASE WHEN State='OH' THEN FinalFUTAAmt ELSE 0 END) AS OHAmount            
	   , SUM(CASE WHEN State='OK' THEN FinalFUTAAmt ELSE 0 END) AS OKAmount            
	   , SUM(CASE WHEN State='OR' THEN FinalFUTAAmt ELSE 0 END) AS ORAmount            
	   , SUM(CASE WHEN State='PA' THEN FinalFUTAAmt ELSE 0 END) AS PAAmount            
	   , SUM(CASE WHEN State='RI' THEN FinalFUTAAmt ELSE 0 END) AS RIAmount            
	   , SUM(CASE WHEN State='SC' THEN FinalFUTAAmt ELSE 0 END) AS SCAmount            
	   , SUM(CASE WHEN State='SD' THEN FinalFUTAAmt ELSE 0 END) AS SDAmount            
	   , SUM(CASE WHEN State='TN' THEN FinalFUTAAmt ELSE 0 END) AS TNAmount            
	   , SUM(CASE WHEN State='TX' THEN FinalFUTAAmt ELSE 0 END) AS TXAmount            
	   , SUM(CASE WHEN State='UT' THEN FinalFUTAAmt ELSE 0 END) AS UTAmount            
	   , SUM(CASE WHEN State='VA' THEN FinalFUTAAmt ELSE 0 END) AS VAAmount            
	   , SUM(CASE WHEN State='VT' THEN FinalFUTAAmt ELSE 0 END) AS VTAmount            
	   , SUM(CASE WHEN State='WA' THEN FinalFUTAAmt ELSE 0 END) AS WAAmount            
	   , SUM(CASE WHEN State='WI' THEN FinalFUTAAmt ELSE 0 END) AS WIAmount            
	   , SUM(CASE WHEN State='WV' THEN FinalFUTAAmt ELSE 0 END) AS WVAmount            
	   , SUM(CASE WHEN State='WY' THEN FinalFUTAAmt ELSE 0 END) AS WYAmount            
	   , SUM(CASE WHEN State='PR' THEN FinalFUTAAmt ELSE 0 END) AS PRAmount            
	   , SUM(CASE WHEN State='VI' THEN FinalFUTAAmt ELSE 0 END) AS VIAmount            
	   --break -- please remember that 00.3% equates to a value of .003 in decimal format        
	   , ROUND(SUM(CASE WHEN State='AK' THEN FinalFUTAAmt ELSE 0 END) * 0.000, 2) AS AKReduction          
	   , ROUND(SUM(CASE WHEN State='AL' THEN FinalFUTAAmt ELSE 0 END) * 0.000, 2) AS ALReduction            
	   , ROUND(SUM(CASE WHEN State='AR' THEN FinalFUTAAmt ELSE 0 END) * 0.009, 2) AS ARReduction            
	   , ROUND(SUM(CASE WHEN State='AZ' THEN FinalFUTAAmt ELSE 0 END) * 0.000, 2) AS AZReduction            
	   , ROUND(SUM(CASE WHEN State='CA' THEN FinalFUTAAmt ELSE 0 END) * 0.009, 2) AS CAReduction            
	   , ROUND(SUM(CASE WHEN State='CO' THEN FinalFUTAAmt ELSE 0 END) * 0.000, 2) AS COReduction            
	   , ROUND(SUM(CASE WHEN State='CT' THEN FinalFUTAAmt ELSE 0 END) * 0.009, 2) AS CTReduction            
	   , ROUND(SUM(CASE WHEN State='DC' THEN FinalFUTAAmt ELSE 0 END) * 0.000, 2) AS DCReduction            
	   , ROUND(SUM(CASE WHEN State='DE' THEN FinalFUTAAmt ELSE 0 END) * 0.006, 2) AS DEReduction            
	   , ROUND(SUM(CASE WHEN State='FL' THEN FinalFUTAAmt ELSE 0 END) * 0.000, 2) AS FLReduction            
	   , ROUND(SUM(CASE WHEN State='GA' THEN FinalFUTAAmt ELSE 0 END) * 0.009, 2) AS GAReduction            
	   , ROUND(SUM(CASE WHEN State='HI' THEN FinalFUTAAmt ELSE 0 END) * 0.000, 2) AS HIReduction            
	   , ROUND(SUM(CASE WHEN State='IA' THEN FinalFUTAAmt ELSE 0 END) * 0.000, 2) AS IAReduction            
	   , ROUND(SUM(CASE WHEN State='ID' THEN FinalFUTAAmt ELSE 0 END) * 0.000, 2) AS IDReduction            
	   , ROUND(SUM(CASE WHEN State='IL' THEN FinalFUTAAmt ELSE 0 END) * 0.000, 2) AS ILReduction            
	   , ROUND(SUM(CASE WHEN State='IN' THEN FinalFUTAAmt ELSE 0 END) * 0.012, 2) AS INReduction            
	   , ROUND(SUM(CASE WHEN State='KS' THEN FinalFUTAAmt ELSE 0 END) * 0.000, 2) AS KSReduction            
	   , ROUND(SUM(CASE WHEN State='KY' THEN FinalFUTAAmt ELSE 0 END) * 0.009, 2) AS KYReduction            
	   , ROUND(SUM(CASE WHEN State='LA' THEN FinalFUTAAmt ELSE 0 END) * 0.000, 2) AS LAReduction            
	   , ROUND(SUM(CASE WHEN State='MA' THEN FinalFUTAAmt ELSE 0 END) * 0.000, 2) AS MAReduction            
	   , ROUND(SUM(CASE WHEN State='MD' THEN FinalFUTAAmt ELSE 0 END) * 0.000, 2) AS MDReduction            
	   , ROUND(SUM(CASE WHEN State='ME' THEN FinalFUTAAmt ELSE 0 END) * 0.000, 2) AS MEReduction            
	   , ROUND(SUM(CASE WHEN State='MI' THEN FinalFUTAAmt ELSE 0 END) * 0.000, 2) AS MIReduction            
	   , ROUND(SUM(CASE WHEN State='MN' THEN FinalFUTAAmt ELSE 0 END) * 0.000, 2) AS MNReduction            
	   , ROUND(SUM(CASE WHEN State='MO' THEN FinalFUTAAmt ELSE 0 END) * 0.009, 2) AS MOReduction            
	   , ROUND(SUM(CASE WHEN State='MS' THEN FinalFUTAAmt ELSE 0 END) * 0.000, 2) AS MSReduction            
	   , ROUND(SUM(CASE WHEN State='MT' THEN FinalFUTAAmt ELSE 0 END) * 0.000, 2) AS MTReduction    
	   , ROUND(SUM(CASE WHEN State='NC' THEN FinalFUTAAmt ELSE 0 END) * 0.009, 2) AS NCReduction            
	   , ROUND(SUM(CASE WHEN State='ND' THEN FinalFUTAAmt ELSE 0 END) * 0.000, 2) AS NDReduction            
	   , ROUND(SUM(CASE WHEN State='NE' THEN FinalFUTAAmt ELSE 0 END) * 0.000, 2) AS NEReduction            
	   , ROUND(SUM(CASE WHEN State='NH' THEN FinalFUTAAmt ELSE 0 END) * 0.000, 2) AS NHReduction            
	   , ROUND(SUM(CASE WHEN State='NJ' THEN FinalFUTAAmt ELSE 0 END) * 0.000, 2) AS NJReduction            
	   , ROUND(SUM(CASE WHEN State='NM' THEN FinalFUTAAmt ELSE 0 END) * 0.000, 2) AS NMReduction            
	   , ROUND(SUM(CASE WHEN State='NV' THEN FinalFUTAAmt ELSE 0 END) * 0.000, 2) AS NVReduction            
	   , ROUND(SUM(CASE WHEN State='NY' THEN FinalFUTAAmt ELSE 0 END) * 0.009, 2) AS NYReduction            
	   , ROUND(SUM(CASE WHEN State='OH' THEN FinalFUTAAmt ELSE 0 END) * 0.009, 2) AS OHReduction            
	   , ROUND(SUM(CASE WHEN State='OK' THEN FinalFUTAAmt ELSE 0 END) * 0.000, 2) AS OKReduction            
	   , ROUND(SUM(CASE WHEN State='OR' THEN FinalFUTAAmt ELSE 0 END) * 0.000, 2) AS ORReduction            
	   , ROUND(SUM(CASE WHEN State='PA' THEN FinalFUTAAmt ELSE 0 END) * 0.000, 2) AS PAReduction            
	   , ROUND(SUM(CASE WHEN State='RI' THEN FinalFUTAAmt ELSE 0 END) * 0.009, 2) AS RIReduction            
	   , ROUND(SUM(CASE WHEN State='SC' THEN FinalFUTAAmt ELSE 0 END) * 0.000, 2) AS SCReduction            
	   , ROUND(SUM(CASE WHEN State='SD' THEN FinalFUTAAmt ELSE 0 END) * 0.000, 2) AS SDReduction            
	   , ROUND(SUM(CASE WHEN State='TN' THEN FinalFUTAAmt ELSE 0 END) * 0.000, 2) AS TNReduction            
	   , ROUND(SUM(CASE WHEN State='TX' THEN FinalFUTAAmt ELSE 0 END) * 0.000, 2) AS TXReduction            
	   , ROUND(SUM(CASE WHEN State='UT' THEN FinalFUTAAmt ELSE 0 END) * 0.000, 2) AS UTReduction            
	   , ROUND(SUM(CASE WHEN State='VA' THEN FinalFUTAAmt ELSE 0 END) * 0.000, 2) AS VAReduction            
	   , ROUND(SUM(CASE WHEN State='VT' THEN FinalFUTAAmt ELSE 0 END) * 0.000, 2) AS VTReduction            
	   , ROUND(SUM(CASE WHEN State='WA' THEN FinalFUTAAmt ELSE 0 END) * 0.000, 2) AS WAReduction            
	   , ROUND(SUM(CASE WHEN State='WI' THEN FinalFUTAAmt ELSE 0 END) * 0.009, 2) AS WIReduction            
	   , ROUND(SUM(CASE WHEN State='WV' THEN FinalFUTAAmt ELSE 0 END) * 0.000, 2) AS WVReduction            
	   , ROUND(SUM(CASE WHEN State='WY' THEN FinalFUTAAmt ELSE 0 END) * 0.000, 2) AS WYReduction            
	   , ROUND(SUM(CASE WHEN State='PR' THEN FinalFUTAAmt ELSE 0 END) * 0.000, 2) AS PRReduction            
	   , ROUND(SUM(CASE WHEN State='VI' THEN FinalFUTAAmt ELSE 0 END) * 0.012, 2) AS VIReduction      
	  FROM #EmployeeSUTA
	  
	  
	-----------------------------
	-- INFORMATION FOR SUPPORT --
	----------------------------- 
	-- Date and Amounts when FUTA Limit has been reached --
	SELECT	Employee, FUTATotal AS 'Total FUTA', 
			CurrFUTAAmt AS 'PD FUTA Amount', PaidDate AS 'PD FUTA >= FUTA Limit'  --PREndDate AS 'PPD FUTA >= FUTA Limit'	
	  FROM	#CritialPPD
  ORDER BY	Employee, PaidDate --PREndDate

	-- Line amounts by Employee and PREndDate --
	SELECT	Employee, SUTALiab AS 'SUTA Code', [State], PaidDate AS 'PaidDate (PD)', 
			CurrSUTAAmt AS 'PD SUTA by State', TotalSUTAAmt AS 'Total PD SUTA', 
			FUTAEligAmt AS 'Total PD FUTA', Factor AS 'Factor (PD SUTA by State/Total PD SUTA)', 
			FinalFUTAAmt AS 'FUTA by State, Employee, and PD (Factor * PD FUTA)'	
	  FROM	#EmployeeSUTA
  ORDER BY  [State], Employee, PaidDate

	-- FUTA Amounts By State --	
	SELECT	[State], SUM(FinalFUTAAmt) AS 'Total FUTA by State'
	  FROM	#EmployeeSUTA
  GROUP BY	[State]
  ORDER BY	[State]
  

	--------------------------
	-- CLEAN UP TEMP TABLES --
	--------------------------
	IF OBJECT_ID('tempdb..#EmployeeSUTA') IS NOT NULL BEGIN DROP TABLE #EmployeeSUTA END
	IF OBJECT_ID('tempdb..#CritialPPD')	IS NOT NULL BEGIN DROP TABLE #CritialPPD END
GO
GRANT EXECUTE ON  [dbo].[vrptPR940SchedAStateInfo] TO [public]
GO
