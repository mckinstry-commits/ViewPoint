SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[vspDDUpdateFormReports]
/********************************
* Created: GG 09/19/06  
* Modified:	AMR 06/22/11 - Issue TK-07089, Fixing performance issue with if exists statement.
*
* Called from Form Properties to add or update linked Reports.
*
* Input:
*	@form		Form Name
*	@reportid	Report ID# to link		
*	@active		Report is active - Y/N 
*
* Output:
*	@errmsg		error message
*	
* Return code:
*	0 = success, 1 = failure
*
*********************************/
    (
      @form VARCHAR(30) = NULL ,
      @reportid INT = NULL ,
      @active CHAR(1) = NULL ,
      @errmsg VARCHAR(255) OUTPUT
    )
AS 
    SET nocount ON
	
    DECLARE @rcode INT
	
    SELECT  @rcode = 0

    IF @form IS NULL
        OR @reportid IS NULL
        OR @active IS NULL 
        BEGIN
            SELECT  @errmsg = 'Missing parameter values!' ,
                    @rcode = 1
            RETURN @rcode
        END
    IF NOT EXISTS ( SELECT TOP 1
                            1
                    FROM    dbo.DDFHShared (NOLOCK)
                    WHERE   Form = @form ) 
        BEGIN
            SELECT  @errmsg = 'Invalid Form: ' + @form ,
                    @rcode = 1
            RETURN @rcode
        END
        --use inline table function for performance issue
    IF NOT EXISTS ( SELECT 1
                    FROM    dbo.vfRPRTShared(@reportid))
        BEGIN
            SELECT  @errmsg = 'Invalid Report: ' + CONVERT(VARCHAR, @reportid) ,
                    @rcode = 1
            RETURN @rcode
        END
    IF @active NOT IN ( 'Y', 'N' ) 
        BEGIN
            SELECT  @errmsg = 'Active property must be ''Y'' or ''N''!' ,
                    @rcode = 1
            RETURN @rcode
        END


-- update/add Reports to vRPFRc
    UPDATE  dbo.vRPFRc
    SET     Active = @active
    WHERE   Form = @form
            AND ReportID = @reportid
    IF @@rowcount = 0 
        BEGIN
            INSERT  dbo.vRPFRc
                    ( Form, ReportID, Active )
            VALUES  ( @form, @reportid, @active )
        END

GO
GRANT EXECUTE ON  [dbo].[vspDDUpdateFormReports] TO [public]
GO
