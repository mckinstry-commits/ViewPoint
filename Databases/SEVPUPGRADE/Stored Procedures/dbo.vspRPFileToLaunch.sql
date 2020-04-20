SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE    PROC [dbo].[vspRPFileToLaunch]
    (
      @reportid AS INT ,
      @filename AS VARCHAR(255) OUTPUT ,
      @apptype AS VARCHAR(30) OUTPUT ,
      @path AS VARCHAR(512) OUTPUT ,
      @loctype AS VARCHAR(20) OUTPUT
    )

/********************************
* Created: JRK 01/04/06
* Modified:	AMR 06/22/11 - Issue TK-07089 , Fixing performance issue with if exists statement.
*			 HH 01/31/12 - TK-12099, extend RPRT.FileName from varchar(60) to varchar(255)
*           TEJ 02/05/12 - TK-12099, extend RPRT.Path from varchar(132) to varchar(512)
*           HH 6/04/12 - TK-15179, extend @loctype from varchar(10) to varchar(20) to reflect RPRL.LocType's size
*
* Called from Helper.GetReportInfo when a report is about to be launched. 
* Brings back info that determines the type of report and how to launch it.
* In most cases the AppType is "Crystal" and we launch the report viewer.
* But the AppType could be Excel, in which case we are going to shell the
* file which would cause whatever program is associated with ".xls" files to
* open and display the data.
*
* Input:
*	the report id to be launched.
*
* Output:
*	@apptype will be "Crystal", "Excel" or other.
*   @filename will be file name like "AP1099.xls".
*   @path will be the path to the file.  Eg, "\\NetDevel\Reports\AP".
*   @loctype says how to interpret the path.  Eg, "UNC".
*	
* Return code:
*	0 = success, 1 = failure
*
*********************************/
AS 
    SET nocount ON
	
    DECLARE @rcode INT
	
    SELECT  @rcode = 0

    SELECT  @filename = t.FileName ,
            @apptype = t.AppType ,
            @path = l.Path ,
            @loctype = l.LocType
            --using a inline table function to reduce index scans
    FROM    dbo.vfRPRTShared(@reportid) t
            JOIN RPRL l ON l.Location = t.Location
    
    vspexit:
    RETURN @rcode



GO
GRANT EXECUTE ON  [dbo].[vspRPFileToLaunch] TO [public]
GO
