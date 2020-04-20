SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE Procedure [dbo].[vrptPR940SchedAStateInfo] (      
  @PRCo bCompany       
, @Year INT      
, @FUTACap INT  

--, @UnemploymentState VARCHAR(2) --comment out for live - leave for testing or use for audit report   
--, @Employee bEmployee  --comment out for live - leave for testing or use for audit report   
--, @AuditFlag VARCHAR(1) -- comment out for live - leave for testing or use for audit report   
)      
        
/*==================================================================================      
      
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
      
==================================================================================*/      
          
AS   
         
SET NOCOUNT ON;    
SET ANSI_NULLS ON;   
  
/*  
First we take the @Year value given and create two new variables that act as the   
first and last date of that year. The @endYear variable takes off a few   
miliseconds to ensure it returns a date that is last date of the given year  
*/   
  
DECLARE @startYear DateTime, @endYear DateTime;    
SET @Year = @Year - DATEPART(yyyy,0);    
SELECT @startYear = DATEADD(Year,@Year,0);    
SELECT @endYear = DATEADD(ms,-3,DATEADD(Year,@Year+1,0));   
  
/*       
Need to get a list of PRTA (addons) records containing earnings subject to FUTA.          
This list will bring back all subject earnings (a.Amt).  
  
@Employee filter is turned off currently, left in preparation for future audit report         
       
Links:          
 PRTA (a) to get addon earning amounts         
 PRDB (b) to get a list of earning codes subject to the FUTA code         
 PRFI (f) to get the FUTA code for the company        
*/   
  
WITH   
ctePRAddons   
(        
   PRCo  
 , PRGroup  
    , PREndDate  
    , Employee  
    , PaySeq  
    , PostSeq  
    , Amt  
)  
AS  
(  
 SELECT   
    a.PRCo  
        , a.PRGroup  
        , a.PREndDate  
        , a.Employee  
        , a.PaySeq  
        , a.PostSeq  
        , SUM(CONVERT(NUMERIC(16,2),ISNULL(a.Amt,0.00)))  
 From   
  dbo.PRTA (NOLOCK)  a             
    JOIN   
  dbo.PRDB (NOLOCK) b ON   
       b.EDLType = 'E'  
   AND b.PRCo = a.PRCo  
   AND b.EDLCode = a.EarnCode  
 JOIN   
  dbo.PRFI (NOLOCK) f ON   
       b.DLCode = f.FUTALiab  
   AND b.PRCo = f.PRCo  
 WHERE  
      a.PRCo = @PRCo  
  --AND (CASE WHEN @Employee <> 0 THEN a.Employee ELSE @Employee END) = @Employee  
 GROUP BY         
  a.PRCo  
  , a.PRGroup  
  , a.PREndDate  
  , a.Employee  
  , a.PaySeq  
  , a.PostSeq     
),  
  
/*  
Need to get a list of PRTH records containing earnings subject to FUTA.          
This list will bring back all subject earnings (h.Amt).  
  
@Employee and @UnemploymentState filters are turned off currently, left in preparation for   
future audit report         
       
Links:          
 PRTA (a) to get addon earning amounts         
 PRDB (b) to get a list of earning codes subject to the FUTA code         
 PRFI (f) to get the FUTA code for the company    
*/  
  
ctePRHeader   
(      
   PRCo  
 , PRGroup  
 , PREndDate  
 , PostDate  
 , Employee  
 , PaySeq  
 , PostSeq  
 , Amt  
 , UnempState  
)  
AS   
(  
 SELECT   
    h.PRCo  
  , h.PRGroup  
  , h.PREndDate  
  , h.PostDate  
  , h.Employee  
  , h.PaySeq  
  , h.PostSeq  
  , CONVERT(NUMERIC(16,2),h.Amt)  
  , h.UnempState  
 From   
  dbo.PRTH (NOLOCK) h   
 JOIN   
  dbo.PRDB (NOLOCK) b ON   
       b.EDLType = 'E'  
   AND b.PRCo = h.PRCo  
   AND b.EDLCode = h.EarnCode  
 JOIN   
  dbo.PRFI (NOLOCK) f ON   
       b.DLCode = f.FUTALiab  
   AND b.PRCo = f.PRCo  
 WHERE  
      h.PRCo = @PRCo  
  --AND (CASE WHEN @UnemploymentState <> 'ZZ' THEN h.UnempState ELSE @UnemploymentState END) = @UnemploymentState  
  --AND (CASE WHEN @Employee <> 0 THEN h.Employee ELSE @Employee END) = @Employee  
),  
  
/*  
Need to join PRTH and PRTA together and then limit their related PREndDates to PREndDates from PRSQ records that  
have a PRSQ.PaidDate between @startYear AND @endYear. PaidDate determines what Tax Year the related PREndDate  
records are part of. We create an Amt field that is the sum of .Amt from PRTA and PRTH. Also left here are the   
individual PRTA (PRTAAmt) and PRTH (PRTHAmt) values for auditing purposes. The Row_Number() function calculated   
the row number for each unique Employee, PostDate, and UnempState combo to be used further down in the Recursion section.        
  
We do not need to filter on PRCo as this was done in the previous two CTEs  
       
Links:          
 ctePRHeader (h) for PRTH records  
 PRSQ (q) joined to limit PREndDates to the current reporting year (@startYear and @endYear)  
 ctePRAddons (a) for PRTA records   
*/  
  
cteAllPayroll   
(  
   PRCo  
 , PRTHAmt  
 , PRTAAmt  
 , Amt  
 , PREndDate  
 , PostDate  
 , Employee  
 , UnempState  
 , RowNum  
)  
AS   
(  
 SELECT    
    q.PRCo  
  , SUM(CONVERT(NUMERIC(16,2),h.Amt)) --PRTHAmt  
  , SUM(CONVERT(NUMERIC(16,2),ISNULL(a.Amt,0.00))) --PRTAAmt  
  , SUM(CONVERT(NUMERIC(16,2),h.Amt + ISNULL(a.Amt,0.00))) --Amt  
  , MAX(h.PREndDate)  
  , h.PostDate  
  , h.Employee  
  , h.UnempState  
  , row_number() OVER  
      (PARTITION BY    
        h.Employee  
       Order BY      
        q.PRCo  
        , h.Employee  
        , h.PostDate  
        , h.UnempState  
      ) AS RowNum  
 From    
  ctePRHeader h  
 JOIN  
  dbo.PRSQ (NOLOCK) q ON  
       h.PRCo = q.PRCo  
   AND h.PRGroup = q.PRGroup  
   AND h.PREndDate = q.PREndDate  
   AND h.Employee = q.Employee  
   AND h.PaySeq = q.PaySeq   
 LEFT JOIN   
  ctePRAddons a ON   
       a.PRCo = h.PRCo  
   AND a.PRGroup = h.PRGroup  
   AND a.PREndDate = h.PREndDate  
   AND a.Employee = h.Employee  
   AND a.PaySeq = h.PaySeq  
   AND a.PostSeq = h.PostSeq  
 WHERE  
  q.PaidDate BETWEEN @startYear AND @endYear  
 GROUP BY  
    q.PRCo  
  , h.Employee  
  , h.PostDate  
  , h.UnempState   
)  
  
/*  
Need to place this data into a temp table so that the above CTEs are not always called in the following sections.  
If this temp table was not used, the above CTEs would be called constantly in the code below and would  
tank this proc's performance  
  
This also allows us to set up the audit process as we can use an if\else statement control if this temp table  
(results just from PRTH and PRTA) is returned for the audit report or if we move down to the recursion area  
for the 940 Schedule A report  
  
Links:          
 cteAllPayroll  
*/  
  
SELECT   
 *  
INTO   
 #tmpPayrollAll  
From   
 cteAllPayroll;  
  
/*  
There are some instances where an employee may make the cap on the very first record seen. Since  
the recursion process can only ever be stopped after the second record (RowNum > 2) we need  
to make a list of these 'fast cap' employees so that we can filter the data after the   
recrusion process.    
  
We are not looking at a Sum of Amt, just single instances  
  
Links:          
 tmpPayrollAll  
*/  
  
  
SELECT   
   Min(RowNum) As StopRowNum  
 , Employee  
INTO   
 #tmpPayrollCapStop  
FROM    
 #tmpPayrollAll  
Where   
 Amt >= @FUTACap  
GROUP By   
 Employee;  
  
/*  
This If/Else statement is here for future audit report use. If @AuditFlag = 'A' then the  
#tmpPayrollAll temp table is returned which can be used to feed the audit report. The proc, at this  
point, would be finished so we need to a bit of clean up by droping the temp tables. If @AuditFlag = 'R'  
then we need to move past the #tmpPayrollAll call and instead go to the recursion code and start to feed  
the 940 Schedule A report.  
  
Links:  
 tmpPayrollAll  
*/  
  
--if @AuditFlag = 'A'  
  
-- Begin  
  
--  select * from #tmpPayrollAll;   
--  --select * from #tmpPayrollCapStop; --comment out for live - leave for testing  
  
--  DROP TABLE #tmpPayrollAll  
--  DROP TABLE #tmpPayrollCapStop  
  
-- End  
  
--Else  
  
-- Begin;  
  
  WITH  
    
/*  
Now we enter the start of the recursion code. These notes will not get into the theory of CTE recursion,  
if you would like to see more info go to this link (http://msdn.microsoft.com/en-us/library/ms186243.aspx).  
We grab the first record from #tmpPayrollAll to be used in the next CTE. We are creating a new field here  
caled AmtWithCap. The function of this field is to prevent instances of #tmpPayrollAll.Amt from being greater  
than @FUTACap. We will never need to see dollar amounts greate than @FUTACap.   
  
Links:  
 #tmpPayrollAll  
*/  
  
  cteFirstRecord   
  (  
     PRCo  
   , PRTHAmt  
   , PRTAAmt  
   , Amt  
   , AmtWithCap  
   , PREndDate  
   , PostDate  
   , Employee  
   , UnempState  
   , RowNum  
  )  
  AS   
  (  
   SELECT        
      PRCo  
    , CONVERT(NUMERIC(16,2),PRTHAmt) --PRTHAmt  
    , CONVERT(NUMERIC(16,2),PRTAAmt) --PRTAAmt  
    , CONVERT(NUMERIC(16,2),Amt) --Amt  
    , CONVERT(NUMERIC(16,2),(CASE WHEN Amt >= @FUTACap THEN @FUTACap ELSE Amt END)) --AmtWithCap  
    , PREndDate  
    , PostDate  
    , Employee  
    , UnempState  
    , RowNum   
   From   
    #tmpPayrollAll  
   WHERE   
    RowNum = 1  
  ),  
  
/*  
Now we are into the meat of the recursion code. Here is where magic occurs. This CTE first grabs data from   
cteFirstRecord above and then via a Union All functions adds to the records values from itself. Because this   
is calling a temp table and not the above CTEs again and again, it runs very fast. We introduce a RecursionFlag field  
for testing purposes to know which sections the results are coming from. Also added are some RowNum values so we   
can see just what row the data came from. RunningTotal is just that, a running total for the employee that will   
cause the CTE to ignore the employee once he hits the @FUTACap value. StateTotal is the total of the taxable wages  
of the employee in that state. If the employee works in more than one state then the total of state values for each  
state he worked in should equal @FUATCap.   
  
First half of the union statement:  
 Since AmtWithCap was cleaned up in cteFirstRecord we do not need to do it again. RunningTotal and StateTotal are  
 scrubbed so that no Amt > @FUTACap is shown, same reasoning as above  
  
Second half of the union statement:  
 The scrubbing of AmtWithCap at this point is probably not necessary, but there just in case. We do not want to scrub  
 RunningTotal as the where statement is <= @FUTACap and scrubbing would cause this to run endlessly (rinse, lather,  
 repeat.....endlessly). We do want to scrub StateTotal though.  
   
Links:  
 cteFirstRecord  
 cteRecursion (r)  
 #tmpPayrollAll (a)  
*/  
  
  cteRecursion   
  (  
     PRCo  
   , RecursionFlag   
   , PRTHAmt  
   , PRTAAmt  
   , Amt  
   , AmtWithCap  
   , PREndDate  
   , PostDate  
   , Employee  
   , UnempState  
   , RowNum  
   , aRowNum  
   , rRowNum  
   , RunningTotal  
   , NewState  
   , StateTotal  
  )  
  AS  
  (        
   SELECT    
      PRCo  
    , 'BU' --BeforeUnion  
    , CONVERT(NUMERIC(16,2),PRTHAmt) --PRTHAmt  
    , CONVERT(NUMERIC(16,2),PRTAAmt) --PRTAAmt  
    , CONVERT(NUMERIC(16,2),Amt) --Amt  
    , AmtWithCap  
    , PREndDate  
    , PostDate  
    , Employee  
    , UnempState  
    , RowNum  
    , CONVERT(Int,RowNum) -- aRowNum  
    , CONVERT(Int,0) -- rRowNum  
    , CONVERT(NUMERIC(16,2),(CASE WHEN Amt >= @FUTACap THEN @FUTACap ELSE Amt END)) --RunningTotal  
    , UnempState  
    , CONVERT(NUMERIC(16,2),(CASE WHEN Amt >= @FUTACap THEN @FUTACap ELSE Amt END)) --StateTotal  
   From   
    cteFirstRecord  
  
   UNION ALL   
  
   SELECT        
      a.PRCo  
    , 'AU' -- AfterUnion  
    , CONVERT(NUMERIC(16,2),a.PRTHAmt) --PRTHAmt  
    , CONVERT(NUMERIC(16,2),a.PRTAAmt) --PRTAAmt  
    , CONVERT(NUMERIC(16,2),a.Amt) --Amt  
    , CONVERT(NUMERIC(16,2),(CASE WHEN a.Amt >= @FUTACap THEN @FUTACap ELSE a.Amt END)) --AmtWithCap  
    , a.PREndDate  
    , a.PostDate  
    , a.Employee  
    , a.UnempState  
    , a.RowNum  
    , CONVERT(Int,a.RowNum)  
    , CONVERT(Int,r.RowNum)  
    , CONVERT(NUMERIC(16,2),r.RunningTotal + a.Amt) AS RunningTotal  
    , r.UnempState AS NewState  
    , CONVERT(NUMERIC(16,2),(CASE WHEN  
            (CASE WHEN a.UnempState <> r.UnempState   
             THEN a.Amt   
             ELSE r.StateTotal + a.Amt   
            END) > @FUTACap  
           THEN @FUTACap  
           ELSE (CASE WHEN a.UnempState <> r.UnempState   
             THEN a.Amt   
             ELSE r.StateTotal + a.Amt   
              END)  
           END)  
      ) AS StateTotal  
   From   
    cteRecursion r  
   JOIN   
    #tmpPayrollAll a ON   
      a.Employee = r.Employee   
     AND r.RowNum +1 = a.RowNum  
   WHERE   
    r.RunningTotal <= @FUTACap   
  )  
  
/*  
Now that we have our data in a per employee\state\postdate combo we add it to the #tmpPayrollFinal temp table   
so that any further queries do not keep calling the CTEs. This is also the final step of the recursion process.  
  
Links  
 cteRecursion  
*/  
  
  SELECT   
   *  
  INTO   
   #tmpPayrollFinal  
  From   
  (  
   SELECT   
      *  
    , row_number() OVER  
         (PARTITION BY   
           Employee   
          Order BY   
             Employee ASC  
           , RunningTotal DESC  
         ) AS RowNumReverse   
   From   
    cteRecursion  
  ) c  
  Order BY   
     c.UnempState ASC  
   , c.PostDate ASC  
   , c.Employee ASC  
  OPTION (MAXRECURSION 0)  
    
/*cleaning up*/  
     
  DROP TABLE #tmpPayrollAll  
    
/*  
This update section is really just to make things look clean. There will be instances (typically all) where  
the Running total or the State total will not meet the cap cleanly. The code below finds these instances and  
figures out what is needed to meet the cap and then records that in the last instance of AmtWithCap, RunningTotal,  
and StateTotal. This way we never see a dollar amount > @FUTACap  
  
Links:  
 tmpPayrollFinal  
*/  
  
  
  Update #tmpPayrollFinal      
  set       
     AmtWithCap = (case when RunningTotal >= @FUTACap 
		--then Amt - (RunningTotal - @FUTACap)        
        then (case when Amt - (RunningTotal - @FUTACap) > @FUTACap 
				then @FUTACap 
				else Amt - (RunningTotal - @FUTACap) 
			  end) --CL-147846 / V1-D-06512
        else AmtWithCap
       end)      
   , RunningTotal = (case when RunningTotal >= @FUTACap       
        then RunningTotal - (RunningTotal - @FUTACap)       
        else RunningTotal       
       end)      
   , StateTotal = (case when RunningTotal >= @FUTACap and StateTotal >= @FUTACap      
        then @FUTACap       
        else StateTotal       
       end)   
         
/*  
**RATES HERE NEED TO BE REVIEWED AT PRIOR TO END OF YEAR TAX UPDTES**  
  
Final select statement, we made it! This a two part union statement. First side of the union grabs the   
'Summary' lines. Grouped by PRCo and State this statement returns total earning dollars for each state   
seen. The second side of the union creates 'Detail' reocrds for each employee\state\postdate to be used   
in a future related audit report. First few records are for testing purposes and can be turned on  
when needed. Also, here is where we use the #tmpPayrollCapStop temp table to make sure we remove records  
when the employee reached the cap at the first line. We do not want the second+ lines of these employees.  
  
Since there will not always be related employee records in #tmpPayrollCapStop the  
RowNum <= isnull(b.StopRowNum, 2147483647) where statements wrap #tmpPayrollCapStop.StopRowNum in  
an isnull statement and sets the null value to the largest possible value of an Int datatype.  
  
Links:  
 #tmpPayrollFinal (s) - first half of union  
 #tmpPayrollFinal (d) - second half of union  
 #tmpPayrollCapStop (b)  
*/  
  
  SELECT  
   /*--fields used for testing comment out for live  
     null as RecursionFlag  
   , 0 AS RowNum  
   , 0 as aRowNum  
   , 0 as rRowNum  
   , 0 as StopRowNum  
   , '1/1/1950' AS PREndDate  
   , 0 AS Amt  
   ,  
   */   
     'S' AS SummaryFlag -- S = Summary Line for Schedule A report, D = Details for audit report          
   , s.PRCo       
   , MAX(c.FedTaxId) AS FedTaxId          
   , MAX(c.Name) AS Name        
   , 0 AS Employee          
   , 'ZZ' AS UnempState  
   , '1/1/1950' AS PostDate         
   , 0 AS PRTHAmt          
   , 0 AS PRTAAmt  
   , 0 AS EmployeeRunningTotalPerState  
   , 0 AS EmployeeRunningTotalPerEmployee  
   , 0 as CapOrLessThanCap               
   , SUM(CASE WHEN s.UnempState='AK' THEN s.AmtWithCap ELSE 0 END) AS AKAmount          
   , SUM(CASE WHEN s.UnempState='AL' THEN s.AmtWithCap ELSE 0 END) AS ALAmount          
   , SUM(CASE WHEN s.UnempState='AR' THEN s.AmtWithCap ELSE 0 END) AS ARAmount          
   , SUM(CASE WHEN s.UnempState='AZ' THEN s.AmtWithCap ELSE 0 END) AS AZAmount          
   , SUM(CASE WHEN s.UnempState='CA' THEN s.AmtWithCap ELSE 0 END) AS CAAmount        
   , SUM(CASE WHEN s.UnempState='CO' THEN s.AmtWithCap ELSE 0 END) AS COAmount          
   , SUM(CASE WHEN s.UnempState='CT' THEN s.AmtWithCap ELSE 0 END) AS CTAmount          
   , SUM(CASE WHEN s.UnempState='DC' THEN s.AmtWithCap ELSE 0 END) AS DCAmount          
   , SUM(CASE WHEN s.UnempState='DE' THEN s.AmtWithCap ELSE 0 END) AS DEAmount          
   , SUM(CASE WHEN s.UnempState='FL' THEN s.AmtWithCap ELSE 0 END) AS FLAmount          
   , SUM(CASE WHEN s.UnempState='GA' THEN s.AmtWithCap ELSE 0 END) AS GAAmount          
   , SUM(CASE WHEN s.UnempState='HI' THEN s.AmtWithCap ELSE 0 END) AS HIAmount          
   , SUM(CASE WHEN s.UnempState='IA' THEN s.AmtWithCap ELSE 0 END) AS IAAmount          
   , SUM(CASE WHEN s.UnempState='ID' THEN s.AmtWithCap ELSE 0 END) AS IDAmount          
   , SUM(CASE WHEN s.UnempState='IL' THEN s.AmtWithCap ELSE 0 END) AS ILAmount          
   , SUM(CASE WHEN s.UnempState='IN' THEN s.AmtWithCap ELSE 0 END) AS INAmount          
   , SUM(CASE WHEN s.UnempState='KS' THEN s.AmtWithCap ELSE 0 END) AS KSAmount          
   , SUM(CASE WHEN s.UnempState='KY' THEN s.AmtWithCap ELSE 0 END) AS KYAmount          
   , SUM(CASE WHEN s.UnempState='LA' THEN s.AmtWithCap ELSE 0 END) AS LAAmount          
   , SUM(CASE WHEN s.UnempState='MA' THEN s.AmtWithCap ELSE 0 END) AS MAAmount          
   , SUM(CASE WHEN s.UnempState='MD' THEN s.AmtWithCap ELSE 0 END) AS MDAmount          
   , SUM(CASE WHEN s.UnempState='ME' THEN s.AmtWithCap ELSE 0 END) AS MEAmount          
   , SUM(CASE WHEN s.UnempState='MI' THEN s.AmtWithCap ELSE 0 END) AS MIAmount          
   , SUM(CASE WHEN s.UnempState='MN' THEN s.AmtWithCap ELSE 0 END) AS MNAmount          
   , SUM(CASE WHEN s.UnempState='MO' THEN s.AmtWithCap ELSE 0 END) AS MOAmount          
   , SUM(CASE WHEN s.UnempState='MS' THEN s.AmtWithCap ELSE 0 END) AS MSAmount          
   , SUM(CASE WHEN s.UnempState='MT' THEN s.AmtWithCap ELSE 0 END) AS MTAmount          
   , SUM(CASE WHEN s.UnempState='NC' THEN s.AmtWithCap ELSE 0 END) AS NCAmount          
   , SUM(CASE WHEN s.UnempState='ND' THEN s.AmtWithCap ELSE 0 END) AS NDAmount          
   , SUM(CASE WHEN s.UnempState='NE' THEN s.AmtWithCap ELSE 0 END) AS NEAmount          
   , SUM(CASE WHEN s.UnempState='NH' THEN s.AmtWithCap ELSE 0 END) AS NHAmount          
   , SUM(CASE WHEN s.UnempState='NJ' THEN s.AmtWithCap ELSE 0 END) AS NJAmount          
   , SUM(CASE WHEN s.UnempState='NM' THEN s.AmtWithCap ELSE 0 END) AS NMAmount          
   , SUM(CASE WHEN s.UnempState='NV' THEN s.AmtWithCap ELSE 0 END) AS NVAmount          
   , SUM(CASE WHEN s.UnempState='NY' THEN s.AmtWithCap ELSE 0 END) AS NYAmount          
   , SUM(CASE WHEN s.UnempState='OH' THEN s.AmtWithCap ELSE 0 END) AS OHAmount          
   , SUM(CASE WHEN s.UnempState='OK' THEN s.AmtWithCap ELSE 0 END) AS OKAmount          
   , SUM(CASE WHEN s.UnempState='OR' THEN s.AmtWithCap ELSE 0 END) AS ORAmount          
   , SUM(CASE WHEN s.UnempState='PA' THEN s.AmtWithCap ELSE 0 END) AS PAAmount          
   , SUM(CASE WHEN s.UnempState='RI' THEN s.AmtWithCap ELSE 0 END) AS RIAmount          
   , SUM(CASE WHEN s.UnempState='SC' THEN s.AmtWithCap ELSE 0 END) AS SCAmount          
   , SUM(CASE WHEN s.UnempState='SD' THEN s.AmtWithCap ELSE 0 END) AS SDAmount          
   , SUM(CASE WHEN s.UnempState='TN' THEN s.AmtWithCap ELSE 0 END) AS TNAmount          
   , SUM(CASE WHEN s.UnempState='TX' THEN s.AmtWithCap ELSE 0 END) AS TXAmount          
   , SUM(CASE WHEN s.UnempState='UT' THEN s.AmtWithCap ELSE 0 END) AS UTAmount          
   , SUM(CASE WHEN s.UnempState='VA' THEN s.AmtWithCap ELSE 0 END) AS VAAmount          
   , SUM(CASE WHEN s.UnempState='VT' THEN s.AmtWithCap ELSE 0 END) AS VTAmount          
   , SUM(CASE WHEN s.UnempState='WA' THEN s.AmtWithCap ELSE 0 END) AS WAAmount          
   , SUM(CASE WHEN s.UnempState='WI' THEN s.AmtWithCap ELSE 0 END) AS WIAmount          
   , SUM(CASE WHEN s.UnempState='WV' THEN s.AmtWithCap ELSE 0 END) AS WVAmount          
   , SUM(CASE WHEN s.UnempState='WY' THEN s.AmtWithCap ELSE 0 END) AS WYAmount          
   , SUM(CASE WHEN s.UnempState='PR' THEN s.AmtWithCap ELSE 0 END) AS PRAmount          
   , SUM(CASE WHEN s.UnempState='VI' THEN s.AmtWithCap ELSE 0 END) AS VIAmount          
   --break -- please remember that 00.3% equates to a value of .003 in decimal format          
   , ROUND(SUM(CASE WHEN s.UnempState='AK' THEN s.AmtWithCap ELSE 0 END) * .000, 2) AS AKReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='AL' THEN s.AmtWithCap ELSE 0 END) * .000, 2) AS ALReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='AR' THEN s.AmtWithCap ELSE 0 END) * .006, 2) AS ARReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='AZ' THEN s.AmtWithCap ELSE 0 END) * .003, 2) AS AZReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='CA' THEN s.AmtWithCap ELSE 0 END) * .006, 2) AS CAReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='CO' THEN s.AmtWithCap ELSE 0 END) * .000, 2) AS COReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='CT' THEN s.AmtWithCap ELSE 0 END) * .006, 2) AS CTReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='DC' THEN s.AmtWithCap ELSE 0 END) * .000, 2) AS DCReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='DE' THEN s.AmtWithCap ELSE 0 END) * .003, 2) AS DEReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='FL' THEN s.AmtWithCap ELSE 0 END) * .006, 2) AS FLReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='GA' THEN s.AmtWithCap ELSE 0 END) * .006, 2) AS GAReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='HI' THEN s.AmtWithCap ELSE 0 END) * .000, 2) AS HIReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='IA' THEN s.AmtWithCap ELSE 0 END) * .000, 2) AS IAReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='ID' THEN s.AmtWithCap ELSE 0 END) * .000, 2) AS IDReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='IL' THEN s.AmtWithCap ELSE 0 END) * .000, 2) AS ILReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='IN' THEN s.AmtWithCap ELSE 0 END) * .009, 2) AS INReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='KS' THEN s.AmtWithCap ELSE 0 END) * .000, 2) AS KSReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='KY' THEN s.AmtWithCap ELSE 0 END) * .006, 2) AS KYReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='LA' THEN s.AmtWithCap ELSE 0 END) * .000, 2) AS LAReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='MA' THEN s.AmtWithCap ELSE 0 END) * .000, 2) AS MAReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='MD' THEN s.AmtWithCap ELSE 0 END) * .000, 2) AS MDReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='ME' THEN s.AmtWithCap ELSE 0 END) * .000, 2) AS MEReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='MI' THEN s.AmtWithCap ELSE 0 END) * .000, 2) AS MIReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='MN' THEN s.AmtWithCap ELSE 0 END) * .000, 2) AS MNReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='MO' THEN s.AmtWithCap ELSE 0 END) * .006, 2) AS MOReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='MS' THEN s.AmtWithCap ELSE 0 END) * .000, 2) AS MSReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='MT' THEN s.AmtWithCap ELSE 0 END) * .000, 2) AS MTReduction  
           
   , ROUND(SUM(CASE WHEN s.UnempState='NC' THEN s.AmtWithCap ELSE 0 END) * .006, 2) AS NCReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='ND' THEN s.AmtWithCap ELSE 0 END) * .000, 2) AS NDReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='NE' THEN s.AmtWithCap ELSE 0 END) * .000, 2) AS NEReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='NH' THEN s.AmtWithCap ELSE 0 END) * .000, 2) AS NHReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='NJ' THEN s.AmtWithCap ELSE 0 END) * .006, 2) AS NJReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='NM' THEN s.AmtWithCap ELSE 0 END) * .000, 2) AS NMReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='NV' THEN s.AmtWithCap ELSE 0 END) * .006, 2) AS NVReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='NY' THEN s.AmtWithCap ELSE 0 END) * .006, 2) AS NYReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='OH' THEN s.AmtWithCap ELSE 0 END) * .006, 2) AS OHReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='OK' THEN s.AmtWithCap ELSE 0 END) * .000, 2) AS OKReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='OR' THEN s.AmtWithCap ELSE 0 END) * .000, 2) AS ORReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='PA' THEN s.AmtWithCap ELSE 0 END) * .000, 2) AS PAReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='RI' THEN s.AmtWithCap ELSE 0 END) * .006, 2) AS RIReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='SC' THEN s.AmtWithCap ELSE 0 END) * .000, 2) AS SCReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='SD' THEN s.AmtWithCap ELSE 0 END) * .000, 2) AS SDReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='TN' THEN s.AmtWithCap ELSE 0 END) * .000, 2) AS TNReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='TX' THEN s.AmtWithCap ELSE 0 END) * .000, 2) AS TXReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='UT' THEN s.AmtWithCap ELSE 0 END) * .000, 2) AS UTReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='VA' THEN s.AmtWithCap ELSE 0 END) * .000, 2) AS VAReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='VT' THEN s.AmtWithCap ELSE 0 END) * .003, 2) AS VTReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='WA' THEN s.AmtWithCap ELSE 0 END) * .000, 2) AS WAReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='WI' THEN s.AmtWithCap ELSE 0 END) * .006, 2) AS WIReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='WV' THEN s.AmtWithCap ELSE 0 END) * .000, 2) AS WVReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='WY' THEN s.AmtWithCap ELSE 0 END) * .000, 2) AS WYReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='PR' THEN s.AmtWithCap ELSE 0 END) * .000, 2) AS PRReduction          
   , ROUND(SUM(CASE WHEN s.UnempState='VI' THEN s.AmtWithCap ELSE 0 END) * .015, 2) AS VIReduction          
   From           
    #tmpPayrollFinal s          
   JOIN          
    HQCO c ON   
     s.PRCo = c.HQCo  
   left outer Join  
    #tmpPayrollCapStop b ON   
     s.Employee = b.Employee   
   where  
    s.RowNum <= isnull(b.StopRowNum, 2147483647)          
   GROUP BY          
    s.PRCo  
     
  --UNION ALL  --commented out as this is really for a future audit report  
      --though this code may not be at all necessary as the audit report should  
      --stop at at the above temp table, but leaving this here just in case   
      --it is needed   
      
  -- SELECT  
  --  /*--fields used for testing           
  --  d.RecursionFlag  
  --  , d.RowNum  
  --  , d.aRowNum  
  --  , d.rRowNum   
  --  , b.StopRowNum  
  --  , d.PREndDate AS PREndDate  
  --  , d.Amt  
  --  ,  
  --  */    
  --    'D' AS SummaryFlag -- S = Summary Line for Schedule A report, D = Details for audit report          
  --  , d.PRCo    
  --  , NULL --FedTaxId          
  --  , NULL --Name        
  --  , d.Employee          
  --  , d.UnempState     
  --  , d.PostDate        
  --  , d.PRTHAmt           
  --  , d.PRTAAmt  
  --  , d.StateTotal AS EmployeeRunningTotalPerState   
  --  , d.RunningTotal AS EmployeeRunningTotalPerEmployee  
  --  , d.AmtWithCap as CapOrLessThanCap         
  --  , (CASE WHEN d.UnempState='AK' THEN d.AmtWithCap ELSE 0 END) AS AKAmount          
  --  , (CASE WHEN d.UnempState='AL' THEN d.AmtWithCap ELSE 0 END) AS ALAmount          
  --  , (CASE WHEN d.UnempState='AR' THEN d.AmtWithCap ELSE 0 END) AS ARAmount          
  --  , (CASE WHEN d.UnempState='AZ' THEN d.AmtWithCap ELSE 0 END) AS AZAmount          
  --  , (CASE WHEN d.UnempState='CA' THEN d.AmtWithCap ELSE 0 END) AS CAAmount          
  --  , (CASE WHEN d.UnempState='CO' THEN d.AmtWithCap ELSE 0 END) AS COAmount          
  --  , (CASE WHEN d.UnempState='CT' THEN d.AmtWithCap ELSE 0 END) AS CTAmount          
  --  , (CASE WHEN d.UnempState='DC' THEN d.AmtWithCap ELSE 0 END) AS DCAmount          
  --  , (CASE WHEN d.UnempState='DE' THEN d.AmtWithCap ELSE 0 END) AS DEAmount          
  --  , (CASE WHEN d.UnempState='FL' THEN d.AmtWithCap ELSE 0 END) AS FLAmount          
  --  , (CASE WHEN d.UnempState='GA' THEN d.AmtWithCap ELSE 0 END) AS GAAmount          
  --  , (CASE WHEN d.UnempState='HI' THEN d.AmtWithCap ELSE 0 END) AS HIAmount          
  --  , (CASE WHEN d.UnempState='IA' THEN d.AmtWithCap ELSE 0 END) AS IAAmount          
  --  , (CASE WHEN d.UnempState='ID' THEN d.AmtWithCap ELSE 0 END) AS IDAmount          
  --  , (CASE WHEN d.UnempState='IL' THEN d.AmtWithCap ELSE 0 END) AS ILAmount          
  --  , (CASE WHEN d.UnempState='IN' THEN d.AmtWithCap ELSE 0 END) AS INAmount          
  --  , (CASE WHEN d.UnempState='KS' THEN d.AmtWithCap ELSE 0 END) AS KSAmount          
  --  , (CASE WHEN d.UnempState='KY' THEN d.AmtWithCap ELSE 0 END) AS KYAmount          
  --  , (CASE WHEN d.UnempState='LA' THEN d.AmtWithCap ELSE 0 END) AS LAAmount          
  --  , (CASE WHEN d.UnempState='MA' THEN d.AmtWithCap ELSE 0 END) AS MAAmount          
  --  , (CASE WHEN d.UnempState='MD' THEN d.AmtWithCap ELSE 0 END) AS MDAmount          
  --  , (CASE WHEN d.UnempState='ME' THEN d.AmtWithCap ELSE 0 END) AS MEAmount          
  --  , (CASE WHEN d.UnempState='MI' THEN d.AmtWithCap ELSE 0 END) AS MIAmount          
  --  , (CASE WHEN d.UnempState='MN' THEN d.AmtWithCap ELSE 0 END) AS MNAmount          
  --  , (CASE WHEN d.UnempState='MO' THEN d.AmtWithCap ELSE 0 END) AS MOAmount          
  --  , (CASE WHEN d.UnempState='MS' THEN d.AmtWithCap ELSE 0 END) AS MSAmount          
  --  , (CASE WHEN d.UnempState='MT' THEN d.AmtWithCap ELSE 0 END) AS MTAmount          
  --  , (CASE WHEN d.UnempState='NC' THEN d.AmtWithCap ELSE 0 END) AS NCAmount          
  --  , (CASE WHEN d.UnempState='ND' THEN d.AmtWithCap ELSE 0 END) AS NDAmount          
  --  , (CASE WHEN d.UnempState='NE' THEN d.AmtWithCap ELSE 0 END) AS NEAmount          
  --  , (CASE WHEN d.UnempState='NH' THEN d.AmtWithCap ELSE 0 END) AS NHAmount          
  --  , (CASE WHEN d.UnempState='NJ' THEN d.AmtWithCap ELSE 0 END) AS NJAmount          
  --  , (CASE WHEN d.UnempState='NM' THEN d.AmtWithCap ELSE 0 END) AS NMAmount          
  --  , (CASE WHEN d.UnempState='NV' THEN d.AmtWithCap ELSE 0 END) AS NVAmount          
  --  , (CASE WHEN d.UnempState='NY' THEN d.AmtWithCap ELSE 0 END) AS NYAmount          
  --  , (CASE WHEN d.UnempState='OH' THEN d.AmtWithCap ELSE 0 END) AS OHAmount          
  --  , (CASE WHEN d.UnempState='OK' THEN d.AmtWithCap ELSE 0 END) AS OKAmount          
  --  , (CASE WHEN d.UnempState='OR' THEN d.AmtWithCap ELSE 0 END) AS ORAmount          
  --  , (CASE WHEN d.UnempState='PA' THEN d.AmtWithCap ELSE 0 END) AS PAAmount          
  --  , (CASE WHEN d.UnempState='RI' THEN d.AmtWithCap ELSE 0 END) AS RIAmount          
  --  , (CASE WHEN d.UnempState='SC' THEN d.AmtWithCap ELSE 0 END) AS SCAmount          
  --  , (CASE WHEN d.UnempState='SD' THEN d.AmtWithCap ELSE 0 END) AS SDAmount          
  --  , (CASE WHEN d.UnempState='TN' THEN d.AmtWithCap ELSE 0 END) AS TNAmount          
  --  , (CASE WHEN d.UnempState='TX' THEN d.AmtWithCap ELSE 0 END) AS TXAmount          
  --  , (CASE WHEN d.UnempState='UT' THEN d.AmtWithCap ELSE 0 END) AS UTAmount          
  --  , (CASE WHEN d.UnempState='VA' THEN d.AmtWithCap ELSE 0 END) AS VAAmount          
  --  , (CASE WHEN d.UnempState='VT' THEN d.AmtWithCap ELSE 0 END) AS VTAmount          
  --  , (CASE WHEN d.UnempState='WA' THEN d.AmtWithCap ELSE 0 END) AS WAAmount          
  --  , (CASE WHEN d.UnempState='WI' THEN d.AmtWithCap ELSE 0 END) AS WIAmount          
  --  , (CASE WHEN d.UnempState='WV' THEN d.AmtWithCap ELSE 0 END) AS WVAmount          
  --  , (CASE WHEN d.UnempState='WY' THEN d.AmtWithCap ELSE 0 END) AS WYAmount          
  --  , (CASE WHEN d.UnempState='PR' THEN d.AmtWithCap ELSE 0 END) AS PRAmount          
  --  , (CASE WHEN d.UnempState='VI' THEN d.AmtWithCap ELSE 0 END) AS VIAmount          
  --  --break          
  --  ,0 AS AKReduction          
  --  ,0 AS ALReduction          
  --  ,0 AS ARReduction          
  --  ,0 AS AZReduction          
  --  ,0 AS CAReduction          
  --  ,0 AS COReduction          
  --  ,0 AS CTReduction          
  --  ,0 AS DCReduction          
  --  ,0 AS DEReduction          
  --  ,0 AS FLReduction          
  --  ,0 AS GAReduction          
  --  ,0 AS HIReduction          
  --  ,0 AS IAReduction          
  --  ,0 AS IDReduction          
  --  ,0 AS ILReduction          
  --  ,0 AS INReduction          
  --  ,0 AS KSReduction          
  --  ,0 AS KYReduction          
  --  ,0 AS LAReduction          
  --  ,0 AS MAReduction          
  --  ,0 AS MDReduction          
  --  ,0 AS MEReduction          
  --  ,0 AS MIReduction          
  --  ,0 AS MNReduction          
  --  ,0 AS MOReduction          
  --  ,0 AS MSReduction          
  --  ,0 AS MTReduction          
  --  ,0 AS NCReduction          
  --  ,0 AS NDReduction          
  --  ,0 AS NEReduction          
  --  ,0 AS NHReduction          
  --  ,0 AS NJReduction          
  --  ,0 AS NMReduction          
  --  ,0 AS NVReduction          
  --  ,0 AS NYReduction          
  --  ,0 AS OHReduction          
  --  ,0 AS OKReduction          
  --  ,0 AS ORReduction          
  --  ,0 AS PAReduction          
  --  ,0 AS RIReduction          
  --  ,0 AS SCReduction          
  --  ,0 AS SDReduction          
  --  ,0 AS TNReduction          
  --  ,0 AS TXReduction          
  --  ,0 AS UTReduction          
  --  ,0 AS VAReduction          
  --  ,0 AS VTReduction          
  --  ,0 AS WAReduction          
  --  ,0 AS WIReduction          
  --  ,0 AS WVReduction          
  --  ,0 AS WYReduction          
  --  ,0 AS PRReduction          
  --  ,0 AS VIReduction          
  -- From           
  --  #tmpPayrollFinal d   
  -- left outer Join  
  --  #tmpPayrollCapStop b ON   
  --   d.Employee = b.Employee  
  -- where  
  --  d.RowNum <= isnull(b.StopRowNum, 2147483647)         
  -- Order BY          
  --    PRCo  
  --  , Employee  
  --  --, RowNum --comment out for live - leave for testing   
  --  , PostDate  
  --  , UnempState  
      
/* clean up */  
      
  DROP TABLE #tmpPayrollFinal  
  DROP TABLE #tmpPayrollCapStop   
            
-- End -- used in the if/else statement seen above if auding is enabled  
GO
GRANT EXECUTE ON  [dbo].[vrptPR940SchedAStateInfo] TO [public]
GO
