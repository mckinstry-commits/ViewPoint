SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
  
/**********************************************************  
*
* Created:	CWirtz 9/20/2010 Issue 123660  
*
* Modified: 
*		CWirtz  1/01/2011 Issue 142520 
*			Desc of Change:  
*			On the PR W-2 Process form Federal Information tab, multiple earning, deduction or liability(EDL)   
*			codes with their own name(description) may be associated at the item level for W2 box 14 reporting.  
*			However, on the W2, box 14 the aggregated amount at the item level is reported and not at the   
*			EDL code level.  The aggregated item amount is stored in table PRWA.  Since the EDL codes   
*			description is typically use as the display the item on the W2 in box 14, the max function   
*			on description is used to select the title.
*
*		ScottAlvey 1/02/2012 Issue 145357 - D-04144
*			Desc of Change:
*			The original version of this view (the commented out section below plus the rest) was
*			used in the Box14Totals.rpt, a subreport of PRW2Preview.rpt. The Pivot function used was
*			causing the subreport to return bad data so this view was split up. The first section
*			(now commented out below) was placed in brvPRW2Box14FederalEntriesBase and is called 
*			by the subreport. The rest left here is used in the PRW2Preview.rpt.			  
*   
* Purpose:    
*		This view will return state information to be printed on  
*		Federal W2s(Copy B) for Box 14.  This view will retrun up to eight box 14 entries.  
*   
* NOTE: 
*		W2s are limited to four box 14 entries per page.  There is a not a federal or state limit  
*		to the number of pages a W2 may be, but Viewpoint has limited their printing of W2s to two pages.  
*       Therefore, the first eight non-zero box 14 entries will be printed on the state W2.  
*    
*		The federal box 14 entries are identified by PRWA.Item with specific fixed values of 40,41,46,47,51,52,53,54.  
*   
*   
******************************************************************/  
CREATE VIEW [dbo].[brvPRW2Box14FederalEntries]   
AS  
  
/* commented out for Issue 145357 - D-04144 - kept for historical reference
  
-- CTE Box14FederalAmounts will contain the entries for box 14 on the Federal W2s.  Field FederalEntries is   
-- the count of the number of lines that will be displayed on the  
-- W2 and will be used to determine if a two page W2 is required.  
WITH vPRBox14FederalEntries  
      AS  
      (SELECT PRWA.PRCo, PRWA.TaxYear,PRWA.Employee,Count(*) AS FederalEntries   
   FROM PRWA   
   WHERE PRWA.Item in (40,41,46,47,51,52,53,54)  
            GROUP BY PRWA.PRCo, PRWA.TaxYear,PRWA.Employee  
)  
,  
vPRBox14Federal  
      AS  
      (  
  SELECT PRWA.PRCo, PRWA.TaxYear,PRWA.Employee,PRWA.Item,PRWA.Amount  
    ,MAX(isnull(PRWC.Description,' ')) AS Description, e.FederalEntries   
   FROM PRWA LEFT OUTER JOIN PRWC  
    ON PRWA.PRCo = PRWC.PRCo AND PRWA.TaxYear = PRWC.TaxYear AND PRWA.Item = PRWC.Item  
   INNER JOIN vPRBox14FederalEntries e  
    ON PRWA.PRCo = e.PRCo AND PRWA.TaxYear = e.TaxYear AND PRWA.Employee = e.Employee  
   WHERE PRWA.Item in (40,41,46,47,51,52,53,54)  
   AND PRWA.Amount <> 0 AND PRWA.Amount IS NOT NULL   
   GROUP BY PRWA.PRCo, PRWA.TaxYear,PRWA.Employee,PRWA.Item,PRWA.Amount, e.FederalEntries  
  
)  
,  

*/

-- The inititial select will retun multiple rows unique to PRCo, TaxYear,and Employee.  
-- The FederalEntries is contains the summarized value at the employee level.  
-- table vPRBox14FederalAmounts will be a denormalize(Pivoted) version of the result set.  
-- The First pivot(8 entires) will be based on the amount and the second(8 entires) on the description.  
-- NOTE: NULL description fields will cause erroneous results 

with 
vPRBox14FederalAmounts  
AS  
(  
select d.PRCo,d.TaxYear,d.Employee,d.FederalEntries  
            ,d.[1]  AS Amount1, d.[2]  AS Amount2,  d.[3]  AS Amount3,  d.[4]  AS Amount4  
            ,d.[5]  AS Amount5, d.[6]  AS Amount6,  d.[7]  AS Amount7,  d.[8]  AS Amount8  
            ,d.[9]  AS Desc1,   d.[10] AS Desc2,    d.[11] AS Desc3,    d.[12] AS Desc4  
   ,d.[13] AS Desc5,   d.[14] AS Desc6,    d.[15] AS Desc7,    d.[16] AS Desc8  
  
From  
(SELECT PRCo,TaxYear,Employee,FederalEntries,Amount,ISNULL(Description,'') AS Description  
,ROW_NUMBER() OVER (PARTITION BY  PRCo,TaxYear,Employee,FederalEntries Order BY Item ) AS AmountIndex   
,ROW_NUMBER() OVER (PARTITION BY  PRCo,TaxYear,Employee,FederalEntries Order BY Item ) +8 AS DescIndex   
--FROM vPRBox14Federal) AS g  
FROM brvPRW2Box14FederalEntriesBase) as g
  
PIVOT  
(SUM (Amount)   
FOR AmountIndex                                      
IN ([1] ,[2] ,[3] ,[4] ,[5] ,[6] ,[7] ,[8]))   
AS p  --First Pivot Table  
  
PIVOT  
(MAX (Description)   
FOR DescIndex  
IN ([9] ,[10] ,[11] ,[12] ,[13] ,[14] ,[15] ,[16]))  
 AS d  --Second and Final Pivot Table  
  
  )  
  
  
--Return the pivoted table with the new columns  
SELECT PRCo,  
            TaxYear,  
            Employee,  
            FederalEntries,  
            SUM(Amount1)  AS Amount1,  
            SUM(Amount2)  AS Amount2,  
            SUM(Amount3)  AS Amount3,  
            SUM(Amount4)  AS Amount4,  
            SUM(Amount5)  AS Amount5,  
            SUM(Amount6)  AS Amount6,  
            SUM(Amount7)  AS Amount7,  
            SUM(Amount8)  AS Amount8,  
  
            MAX(Desc1)  AS Desc1,  
            MAX(Desc2)  AS Desc2,  
            MAX(Desc3)  AS Desc3,  
            MAX(Desc4)  AS Desc4,  
            MAX(Desc5)  AS Desc5,  
            MAX(Desc6)  AS Desc6,  
            MAX(Desc7)  AS Desc7,  
            MAX(Desc8)  AS Desc8  
FROM vPRBox14FederalAmounts  
GROUP BY PRCo,  
            TaxYear,  
            Employee,  
            FederalEntries  
  
  
  
  
  
  
  
GO
GRANT SELECT ON  [dbo].[brvPRW2Box14FederalEntries] TO [public]
GRANT INSERT ON  [dbo].[brvPRW2Box14FederalEntries] TO [public]
GRANT DELETE ON  [dbo].[brvPRW2Box14FederalEntries] TO [public]
GRANT UPDATE ON  [dbo].[brvPRW2Box14FederalEntries] TO [public]
GRANT SELECT ON  [dbo].[brvPRW2Box14FederalEntries] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvPRW2Box14FederalEntries] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvPRW2Box14FederalEntries] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvPRW2Box14FederalEntries] TO [Viewpoint]
GO
