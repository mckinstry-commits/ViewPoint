SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************************************
* CREATED: AL 1/22/13
* 
* USAGE:
* Validates All Reports for use in RP Form Reports. Also
* Prevents users from using UNC reports in RP Reports by Form
* because they are not currently supported. D-05339
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
CREATE PROCEDURE [dbo].[vspRPReportIDSharedValNoUNC]
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


        SELECT  @msg = Title
        FROM    dbo.vfRPRTShared(@ReportID)
      
        IF @@rowcount = 0 
            BEGIN
                SELECT  @msg = 'Report ID: '
                        + CONVERT(VARCHAR, ISNULL(@ReportID, 0))
                        + ' does not exist. ' + CHAR(13) + CHAR(10)
						+ ' [vspRPReportIDSharedVal]',
                        @rcode = 1 
                        
                RETURN @rcode
			END
			
		SELECT @msg = Title
		From RPRTShared t with(nolock)
		Join RPRL as l on t.Location = l.Location
		Where NOT (l.LocType = 'UNC' AND AppType = 'SQL Reporting Services')
		AND t.ReportID=@ReportID
		
		IF @@rowcount = 0 
            BEGIN
                SELECT  @msg = 'Report ID: '
                        + CONVERT(VARCHAR, ISNULL(@ReportID, 0))
                        + ' Is not available as a Form report. ' + CHAR(13) + CHAR(10)
						+ ' [vspRPReportIDSharedVal]',
                        @rcode = 1 
                        
                RETURN @rcode
			END
        

GO
GRANT EXECUTE ON  [dbo].[vspRPReportIDSharedValNoUNC] TO [public]
GO
