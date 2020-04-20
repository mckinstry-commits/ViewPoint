SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************************************
* CREATED: Terrylis 06/14/2006
* MODIFIED: AMR 06/22/11 - Issue TK-07089 , Fixing performance issue with if exists statement.
*
* USAGE:
* Validates All Reports in RPRTShared used on RP Report Copy and RPRT
*
* INPUTS
*   pass ReportID
*
* OUTPUTS
*  returns error message if error
*
* RETURN VALUE
*   @rcode			0 = success, 1 = failure
*   
************************************************************************/
CREATE PROCEDURE [dbo].[vspRPReportIDSharedVal]
    (
      @ReportID INT = 0 ,
      @msg VARCHAR(255) OUTPUT
    )
AS 
    SET nocount ON
    DECLARE @rcode INT
    SELECT  @rcode = 0
  
    IF @ReportID = 0 
        BEGIN
            SELECT  @msg = ISNULL(@ReportID, '') + ' invalid Report ID.'
					+ CHAR(13) + CHAR(10)
					+ ' [vspRPReportIDSharedVal]' ,
                    @rcode = 1
            RETURN @rcode
        END

    BEGIN
        SELECT  @msg = Title
        FROM    dbo.vfRPRTShared(@ReportID)
      
        IF @@rowcount = 0 
            BEGIN
                SELECT  @msg = 'Report ID: '
                        + CONVERT(VARCHAR, ISNULL(@ReportID, 0))
                        + ' does not exist. ' + CHAR(13) + CHAR(10)
						+ ' [vspRPReportIDSharedVal]',
                        @rcode = 1 
            END
        RETURN @rcode
    END

    IF @rcode <> 0 
        SELECT  @msg = @msg + CHAR(13) + CHAR(10)
                + ' [vspRPReportIDSharedVal]'
    RETURN @rcode


GO
GRANT EXECUTE ON  [dbo].[vspRPReportIDSharedVal] TO [public]
GO
