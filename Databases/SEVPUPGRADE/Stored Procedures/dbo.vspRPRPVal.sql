SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[vspRPRPVal]
/*****************************************
* Created - Terrylis 05/02/2005
* Modified: GG 01/18/07 - cleanup
*			AMR 06/22/11 - Issue TK-07089, Fixing performance issue with if exists statement.
*
* Checks for the existence of a Report Parameter
*
* Inputs:
*	@reportid		Report ID#
*	@param			Parameter Name
*
* Outputs:
*	@msg			Parameter description or error message
*
* Return code:
*	0 = success, 1 = error
*
*****************************************/
    (
      @reportid INT = NULL ,
      @param VARCHAR(60) = NULL ,
      @msg VARCHAR(255) OUTPUT
    )
AS 
    SET nocount ON
    DECLARE @rcode INT
    SELECT  @rcode = 0

--Validate Report ID  
    IF NOT EXISTS ( SELECT  1
                    FROM    dbo.vfRPRTShared(@reportid) ) 
        BEGIN
            SELECT  @msg = 'Report ID:  ' + CONVERT(VARCHAR, @reportid)
                    + '  not on file!' ,
                    @rcode = 1
            RETURN	@rcode
        END
--Validate Parameter Name
    IF @param IS NULL 
        BEGIN
            SELECT  @msg = 'Missing Report Parameter.' ,
                    @rcode = 1
            RETURN	@rcode
        END

    SELECT  @msg = Description
    FROM    dbo.RPRPShared (NOLOCK)
    WHERE   ReportID = @reportid
            AND ParameterName = @param
            
    IF @@rowcount = 0 
        BEGIN
            SELECT  @msg = 'Parameter: ' + @param + ' not on file!' ,
                    @rcode = 1
        END

    RETURN @rcode
  
GO
GRANT EXECUTE ON  [dbo].[vspRPRPVal] TO [public]
GO
