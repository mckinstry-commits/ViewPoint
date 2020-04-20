SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE proc [dbo].[vspPMFormReportListFill]
/*****************************************
* Created By:	TRL	03/4/2013  Task - 42464  
* Modified By:	 TRL 07/08/2013 Bug:  55167 Task: 55175 limit to only crystal reports
*				
*This report returns a list of form reports assigne in RP Form Reports and then returns reports based on report security.
******************************************/
(@Co bCompany = NULL, @DocumentForm VARCHAR(30) = NULL, @errmsg VARCHAR(512) OUTPUT)

AS

DECLARE   @rcode INT, @reportid INT, @openreportcursor TINYINT, @access TINYINT, @errmsg2 VARCHAR(512)

SELECT @rcode = 0

--Create Temp table for  VP and Customer Reports assigned to PM Form
DECLARE @pmFormReports TABLE
(
     ReportID INT ,
     Title VARCHAR(60) ,
     Access TINYINT
)    
    
INSERT  @pmFormReports (ReportID, Title, Access )
SELECT  RPFRShared.ReportID,RPRTShared.Title,0  -- assume full access    
FROM    dbo.RPFRShared  
--use inline table function for performance issue
CROSS APPLY (SELECT Title FROM dbo.vfRPRTShared(RPFRShared.ReportID) WHERE AppType = 'Crystal') RPRTShared 
WHERE   RPFRShared.Form = @DocumentForm  AND RPFRShared.Active = 'Y' -- active reports only    
ORDER BY	RPRTShared.Title    
 
-- use a cursor to get access level for each Report    
DECLARE vcReportSecurity CURSOR  FOR
SELECT  ReportID FROM @pmFormReports
    
OPEN vcReportSecurity    
SET @openreportcursor = 1    
    
-- loop through all Reports on the Form    
report_loop:    
FETCH NEXT FROM vcReportSecurity INTO @reportid    
    
IF @@fetch_status <> 0 
GOTO report_loop_end    

EXEC @rcode = vspRPReportSecurity @Co, @reportid, @access OUTPUT, @errmsg2 OUTPUT    
IF @rcode <> 0 
   BEGIN    
       SELECT  @errmsg = 'rcode <> 0 returned from vspRPReportSecurity.  @errmsg2='  + @errmsg2    
       RETURN 1
   END    
UPDATE  @pmFormReports
SET     Access = @access -- save Report Access level    
WHERE   ReportID = @reportid    

GOTO report_loop    

report_loop_end: -- processed all Reports on the Form    

CLOSE vcReportSecurity    
DEALLOCATE vcReportSecurity    
SET @openreportcursor = 0    

-- 9th resultset - return accessible Form Reports only    
SELECT  ReportID, Title FROM    @pmFormReports WHERE   Access = 0     
GO
GRANT EXECUTE ON  [dbo].[vspPMFormReportListFill] TO [public]
GO
