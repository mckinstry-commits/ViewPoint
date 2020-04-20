
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/**********************************************************
* Copyright 2013 Viewpoint Construction Software. All rights reserved.
* Created: CWirtz	9/20/2010 Issue 123660
* Modified: CWirtz  1/28/2011 Issue 143076  Allow zero amounts to be printed on the W2
*           JayR 5/21/2013 removed special symbol so database compares will go smoothly. 
* Purpose:  
* 	This view will return state information to be printed on
* 	State W2s(Copy B) for Box 14.  This view will return up to eight box 14 entries.
* 
*   Special Record processing:
*   To allow for specific state reporting there are times when a state record 
*   in table vPRW2MiscHeader will have a null value for the EDLType and an associated record 
*   in vPRW2MiscDetail with the key PRCo, TaxYear, State and LineNumber is not created 
*   for each employee.  This is a valid condition requiring unique data extraction.  
*   The following common table expressions(CTE) builds a new version of PRW2MiscDetail including
*      1)Employee records with the amount=0 when the associated header record EDLType value is null 
*      2)All zero-pay detail records in table vPRW2MiscDetail where a following header record 
*        in table vPRW2MiscHeader(Based on Linenumber) has a null EDLType. 
*      3)All non-zero pay records from vPRW2MiscDetail (normal processing)
*    
*   
* 	NOTE: W2s are limited to four box 14 entries per page.  There is a not a federal or state limit
* 		  to the number of pages a W2 may be, but Viewpoint has limited their printing of W2s to two pages.
* 	      Therefore, the first eight box 14 entries generated by this view will be printed on the state W2.
* 	
* 
* 
******************************************************************/

CREATE VIEW [dbo].[brvPRW2Box14StateEntries] 
AS


-- CTE Box14StateEntries will contain the entries for box 14 on the State W2s.  Field StateEntries is 
-- the count of the number of lines that will be displayed on the
-- W2 and will be used to determine if a two page W2 is required.


--Extract all records from vPRW2MiscHeader where the EDLType is null.
WITH vPRW2MiscHeaderNullEDLType
AS
(
SELECT g.PRCo,g.TaxYear,g.State,g.LineNumber, PreviousLineNumber= LineNumber-1 FROM PRW2MiscHeader g
where g.EDLType IS Null
)

--Build a dummy record for each employee based on any records in CTE vPRW2MiscHeaderNullEDLType(EDLType IS NULL). 
--The amount will be set to zero.
,vPRW2MiscDetailDummy
AS
(
SELECT h.PRCo,h.TaxYear,h.State,e.Employee,h.LineNumber,Amount=0 FROM vPRW2MiscHeaderNullEDLType h
	LEFT OUTER JOIN PRW2MiscDetail e
		ON h.PRCo = e.PRCo AND h.TaxYear = e.TaxYear AND h.State = e.State AND h.PreviousLineNumber = e.LineNumber
)

--Extract zero pay records from PRW2MiscDetail associated with a any any records in CTE vPRW2MiscHeaderNullEDLType(EDLType IS NULL).
--NOTE: The join h.PreviousLineNumber = e.LineNumber ensures the parent child reporting relationship even if the amount is zero.
,vPRW2MiscDetailZeroPay
AS
(
SELECT h.PRCo,h.TaxYear,h.State,e.Employee,h.PreviousLineNumber AS LineNumber,Amount=0 FROM vPRW2MiscHeaderNullEDLType h
	LEFT OUTER JOIN PRW2MiscDetail e
                  ON h.PRCo = e.PRCo AND h.TaxYear = e.TaxYear AND h.State = e.State AND h.PreviousLineNumber = e.LineNumber
    Where e.Amount=0              

)
--Build a vitual PRW2MiscDetail table with 1)All non zero records from vPRW2MiscDetail
--and the data extacted from above.
,vPRW2MiscDetailFinal
AS
(
SELECT PRCo, TaxYear, State, Employee, LineNumber, Amount 
FROM PRW2MiscDetail Where Amount <> 0

UNION ALL
SELECT PRCo, TaxYear, State, Employee, LineNumber, Amount 
FROM vPRW2MiscDetailDummy

UNION ALL
SELECT PRCo, TaxYear, State, Employee, LineNumber, Amount 
FROM vPRW2MiscDetailZeroPay
)


-- CTE Box14StateEntries will contain the entries for box 14 on the State W2s.  Field StateEntries is 
-- the count of the number of lines that will be displayed on the
-- W2 and will be used to determine if a two page W2 is required.
,vPRBox14StateEntries
      AS
      (SELECT PRCo,TaxYear,State,Employee,Count(*)AS StateEntries
            FROM vPRW2MiscDetailFinal
            GROUP BY PRCo,TaxYear,State,Employee
)

,
vPRBox14State
      AS
      (SELECT e.PRCo,e.TaxYear,e.State,e.Employee,e.LineNumber,e.Amount, f.StateEntries,isnull(g.Description,' ') AS Description
            FROM vPRW2MiscDetailFinal e INNER JOIN vPRBox14StateEntries f
                  ON e.PRCo = f.PRCo AND e.TaxYear = f.TaxYear AND e.State = f.State AND e.Employee = f.Employee
             LEFT OUTER JOIN PRW2MiscHeader g
                  ON e.PRCo = g.PRCo AND e.TaxYear = g.TaxYear AND e.State = g.State AND e.LineNumber = g.LineNumber

)

--Select * from vPRBox14StateEntries
--Select * from vPRBox14State
,
-- The inititial select will retun multiple rows unique to PRCo, TaxYear,and Employee.
-- The FederalEntries is contains the summarized value at the employee level.
-- table vPRBox14StateAmounts will be a denormalize(Pivoted) version of the result set.
-- The First pivot(8 entires) will be based on the amount and the second(8 entires) on the description.
--NOTE: NULL description fields will cause erroneous results
vPRBox14StateAmounts
AS
(
select d.PRCo,d.TaxYear,d.State,d.Employee,d.StateEntries
            ,d.[1]  AS Amount1, d.[2]  AS Amount2,  d.[3]  AS Amount3,  d.[4]  AS Amount4
            ,d.[5]  AS Amount5, d.[6]  AS Amount6,  d.[7]  AS Amount7,  d.[8]  AS Amount8
            ,d.[9]  AS Amount9, d.[10] AS Amount10, d.[11] AS Amount11, d.[12] AS Amount12
            ,d.[13] AS Desc1, d.[14] AS Desc2,  d.[15] AS Desc3,  d.[16] AS Desc4
			,d.[17] AS Desc5, d.[18] AS Desc6,  d.[19] AS Desc7,  d.[20] AS Desc8
            ,d.[21] AS Desc9, d.[22] AS Desc10, d.[23] AS Desc11, d.[24] AS Desc12

From
(SELECT PRCo,TaxYear,State,Employee,StateEntries,Amount,ISNULL(Description,'') AS Description
,ROW_NUMBER() OVER (PARTITION BY  PRCo,TaxYear,State,Employee,StateEntries Order BY LineNumber ) AS AmountIndex 
,ROW_NUMBER() OVER (PARTITION BY  PRCo,TaxYear,State,Employee,StateEntries Order BY LineNumber ) +12 AS DescIndex 
FROM vPRBox14State) AS g

PIVOT
(SUM (Amount) 
FOR AmountIndex                                    
IN ([1] ,[2] ,[3] ,[4] ,[5] ,[6] ,[7] ,[8],[9] ,[10] ,[11] ,[12])) 
AS p    --First Pivot Table

PIVOT
(MAX (Description) 
FOR DescIndex
IN ([13] ,[14] ,[15] ,[16] ,[17] ,[18] ,[19] ,[20],[21] ,[22] ,[23] ,[24]))
 AS d  --First Pivot Table

  )

--Return the pivoted table with the new columns
SELECT PRCo,
            TaxYear,
            State,
            Employee,
            StateEntries,
            SUM(Amount1)  AS Amount1,
            SUM(Amount2)  AS Amount2,
            SUM(Amount3)  AS Amount3,
            SUM(Amount4)  AS Amount4,
            SUM(Amount5)  AS Amount5,
            SUM(Amount6)  AS Amount6,
            SUM(Amount7)  AS Amount7,
            SUM(Amount8)  AS Amount8,
            SUM(Amount9)  AS Amount9,
            SUM(Amount10) AS Amount10,
            SUM(Amount11) AS Amount11,
            SUM(Amount12) AS Amount12,

            MAX(Desc1)  AS Desc1,
            MAX(Desc2)  AS Desc2,
            MAX(Desc3)  AS Desc3,
            MAX(Desc4)  AS Desc4,
            MAX(Desc5)  AS Desc5,
            MAX(Desc6)  AS Desc6,
            MAX(Desc7)  AS Desc7,
            MAX(Desc8)  AS Desc8,
            MAX(Desc9)  AS Desc9,
            MAX(Desc10) AS Desc10,
            MAX(Desc11) AS Desc11,
            MAX(Desc12) AS Desc12
FROM vPRBox14StateAmounts
GROUP BY PRCo,
            TaxYear,
            State,
            Employee,
            StateEntries








GO

GRANT SELECT ON  [dbo].[brvPRW2Box14StateEntries] TO [public]
GRANT INSERT ON  [dbo].[brvPRW2Box14StateEntries] TO [public]
GRANT DELETE ON  [dbo].[brvPRW2Box14StateEntries] TO [public]
GRANT UPDATE ON  [dbo].[brvPRW2Box14StateEntries] TO [public]
GO