SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROCEDURE [dbo].[vspRPCopySourceReportIDVal] 
  /********************************  
* Created: Terrylis 06/14/2006  
* Modified: AMR 06/22/11 - Issue TK-07089 , Fixing performance issue with if exists statement.
*  
*  
* Validates All Reports in vRPRTShared used on RP Report Copy 
*  
*********************************/
    (
      @ReportID INT = 0 ,
      @nextreportid INT = 0 OUTPUT ,
      @msg VARCHAR(255) OUTPUT
    )
AS 
    SET nocount ON
    DECLARE @rcode INT  
    SELECT  @rcode = 0
  
    IF ISNULL(@ReportID, 0) = 0 
        BEGIN
            SELECT  @msg = CONVERT(VARCHAR, ISNULL(@ReportID, 0))
                    + ' not a invalid Report ID.' ,
                    @rcode = 1
            RETURN @rcode
        END

    SELECT  @msg = Title
    --use inline table function for performance issue
    FROM    dbo.vfRPRTShared(@ReportID)
    WHERE   (AppType = 'Crystal' AND RIGHT(FileName, 4) = '.rpt')
         OR (AppType = 'SQL Reporting Services')
    IF @@rowcount = 0 
        BEGIN
            SELECT  @msg = 'Report ID: ' + CONVERT(VARCHAR, ISNULL(@ReportID,
                                                              0))
                    + ' does not exist or is not a valid report. ' ,
                    @rcode = 1 
            RETURN @rcode
        END

    IF SUSER_NAME() = 'viewpointcs' 
        BEGIN
            SELECT  @nextreportid = ISNULL(MAX(ReportID), 9999) + 1
            FROM    dbo.RPRT
            WHERE   ReportID <= 9999
            IF @nextreportid > 99999 
                BEGIN
                    SELECT  @msg = 'Next Report ID has exceded 99,999.' ,
                            @rcode = 1 
                    RETURN @rcode
                END
        END
    ELSE -- Not viewpointcs
        BEGIN
            SELECT  @nextreportid = ISNULL(MAX(ReportID), 10000) + 1
            FROM    dbo.RPRTc
            WHERE   ReportID >= 10000
            IF @@rowcount = 0 
                BEGIN
                    SELECT  @msg = 'Error getting next Report ID' ,
                            @rcode = 1
                    RETURN @rcode
                END
            IF @nextreportid > 99999 
                BEGIN
                    SELECT  @msg = 'Next Report ID has exceded 99,999.' ,
                            @rcode = 1 
                    RETURN @rcode
                END
        END

    RETURN @rcode
  


GO
GRANT EXECUTE ON  [dbo].[vspRPCopySourceReportIDVal] TO [public]
GO
