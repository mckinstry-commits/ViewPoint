SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspRPReportVal]
/***********************************************************
* CREATED: GG 09/19/06
* MODIFIED: AMR 06/22/11 - Issue TK-07089, Fixing performance issue with if exists statement.
*
* USAGE:
* Validates a ReportID#
*
* INPUTS
*   @reportid		Report to validate
*
* OUTPUTS
*   @msg			error message if something went wrong, otherwise description
*
* RETURN VALUE
*   @rcode			0 = success, 1 = failure
*   
************************************************************************/
    @reportid INT = NULL ,
    @msg VARCHAR(60) OUTPUT
AS 
    SET nocount ON
    DECLARE @rcode INT

    SELECT  @rcode = 0

    IF @reportid IS NULL 
        BEGIN
            SELECT  @msg = 'Missing ReportID#!' ,
                    @rcode = 1
            RETURN @rcode
        END

    SELECT  @msg = Title
    FROM    dbo.vfRPRTShared(@reportid)
    
    IF @@rowcount = 0 
        BEGIN
            SELECT  @msg = 'Report ID# not on file!' ,
                    @rcode = 1
        END

    RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspRPReportVal] TO [public]
GO
