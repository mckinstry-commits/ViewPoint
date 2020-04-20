SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
   
/**********************************************************    
*   
* Created: ScottAlvey 12/29/11 Issue 145357 - D-04144  
*    
* Modified:   
*  
* Notes:   
*	This view used to be called brvPRW2Box14FederalEntries and was combination of what is  
*	currently seen below AND the current brvPRW2Box14FederalEntries (please see the current   
*	brvPRW2Box14FederalEntries for the ORIGINAL look). This current view was created  
*	to allow the PRW2Preview.rpt to work properly. In that report on the last page there is a subreport  
*	caleld Box14Totals.rpt and its job is summarize all Box 14 totals for the ranges provided by  
*	the main report. The original version of this view used to cause problems in this subreport  
*	due to the Pivot function used within. The Pivot function is necessary for the main reprort  
*	that calls the above subreport.  
*  
*	Since the section below is still needed it is best not to keep the same code in two locations.  
*	This view acts as the basis for the current brvPRW2Box14FederalEntries so that brvPRW2Box14FederalEntries  
*	may then only contain the Pivot funtion for use in the main report. It is also used in the  
*	above mentioned subreport so that the totals can be reflected correctly. The notes below are kept  
*	for historical purposes.  
*  
* Historical Notes:  
*	On the PR W-2 Process form Federal Information tab, multiple earning, deduction or liability(EDL)     
*	codes with their own name(description) may be associated at the item level for W2 box 14 reporting.    
*	However, on the W2, box 14 the aggregated amount at the item level is reported and not at the     
*	EDL code level.  The aggregated item amount is stored in table PRWA.  Since the EDL codes     
*	description is typically use as the display the item on the W2 in box 14, the max function     
*	on description is used to select the title.    
*     
* Purpose:      
*	This view will return state information to be printed on    
*	Federal W2s(Copy B) for Box 14.  This view will retrun up to eight box 14 entries.    
*     
* NOTE: 
*	W2s are limited to four box 14 entries per page.  There is a not a federal or state limit    
*	to the number of pages a W2 may be, but Viewpoint has limited their printing of W2s to two pages.    
*   Therefore, the first eight non-zero box 14 entries will be printed on the state W2.    
*      
*  The federal box 14 entries are identified by PRWA.Item with specific fixed values of 40,41,46,47,51,52,53,54.    
*  
* Related Reports:  
*	PRW2Preview.rpt  
*     
*     
******************************************************************/    
create VIEW [dbo].[brvPRW2Box14FederalEntriesBase]     
AS     
    
-- CTE Box14FederalAmounts will contain the entries for box 14 on the Federal W2s.    
-- Field FederalEntries (used in brvPRW2Box14FederalEntries) is the count of the number of   
-- lines that will be displayed on the W2 and will be used to determine if a two page W2 is required.   
  
WITH   
  
vPRBox14FederalEntries AS    
        
(  
 SELECT   
	PRWA.PRCo  
	, PRWA.TaxYear  
	, PRWA.Employee  
	, Count(*) AS FederalEntries 
	--, PRWA.Item    
 FROM   
	PRWA     
 WHERE   
	PRWA.Item in (40,41,46,47,51,52,53,54)  
 GROUP BY   
	PRWA.PRCo  
	, PRWA.TaxYear  
	, PRWA.Employee
	--, PRWA.Item    
)  
  
-- Final select for use in the Box14Totals.rpt a subreport of PRW2Preview.rpt  
  
 SELECT   
	PRWA.PRCo  
	, PRWA.TaxYear  
	, PRWA.Employee  
	, PRWA.Item  
	, PRWA.Amount    
    , MAX(isnull(PRWC.Description,' ')) AS Description  
    , e.FederalEntries     
 FROM   
	PRWA   
 LEFT OUTER JOIN   
	PRWC ON   
	PRWA.PRCo = PRWC.PRCo   
	AND PRWA.TaxYear = PRWC.TaxYear   
	AND PRWA.Item = PRWC.Item    
 INNER JOIN   
	vPRBox14FederalEntries e ON   
	PRWA.PRCo = e.PRCo   
	AND PRWA.TaxYear = e.TaxYear   
	AND PRWA.Employee = e.Employee
 WHERE
	PRWA.Item in (40,41,46,47,51,52,53,54)  
    and PRWA.Amount <> 0   
    and PRWA.Amount IS NOT NULL         
 GROUP BY   
	PRWA.PRCo  
	, PRWA.TaxYear  
	, PRWA.Employee  
	, PRWA.Item  
	, PRWA.Amount  
	, e.FederalEntries    
GO
GRANT SELECT ON  [dbo].[brvPRW2Box14FederalEntriesBase] TO [public]
GRANT INSERT ON  [dbo].[brvPRW2Box14FederalEntriesBase] TO [public]
GRANT DELETE ON  [dbo].[brvPRW2Box14FederalEntriesBase] TO [public]
GRANT UPDATE ON  [dbo].[brvPRW2Box14FederalEntriesBase] TO [public]
GO
