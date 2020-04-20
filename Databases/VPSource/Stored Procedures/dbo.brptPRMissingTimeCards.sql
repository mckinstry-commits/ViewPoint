SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[brptPRMissingTimeCards] (@PRCo bCompany, @PRGroup tinyint, @PREndDate bDate)
   as
   /* brptPRMissingTimeCards is used for Crystal Report PRMissingTimeCards
      needs a stored procedure since Crystal won't allow a join to a parameter
      JRE 10/30/02 */
   --allow for selecting multiple groups
   if (select @PRGroup)=0     select @PRGroup=null
   
   SELECT PREH.PRCo, PREH.Employee, PREH.LastName, PREH.FirstName, PREH.MidName, PREH.PRGroup, 
       PREH.PRDept, PREH.Craft, PREH.JCCo, PREH.Job, PREH.ActiveYN,
       HQCO.HQCo, CoName=HQCO.Name
   FROM PREH 
   JOIN HQCO ON PREH.PRCo = HQCO.HQCo
   WHERE
       PREH.PRCo = @PRCo AND PREH.PRGroup=isnull(@PRGroup,PREH.PRGroup) and
       PREH.ActiveYN = 'Y' AND 
       not exists (select * from PRTH where PREH.PRCo = PRTH.PRCo AND PREH.PRGroup = PRTH.PRGroup AND
   	    PREH.Employee = PRTH.Employee and PRTH.PREndDate=@PREndDate)
   ORDER BY
       PREH.PRCo ASC,
       PREH.PRGroup ASC,
       PREH.Employee ASC

GO
GRANT EXECUTE ON  [dbo].[brptPRMissingTimeCards] TO [public]
GO
