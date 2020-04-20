SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspRPSavePrinterSettings]
/***********************************************************
 * CREATED BY: TEJ 04/19/2011 (Split out vspRPSavePrintOptions - which should now be obsolete)
 * MODIFIED BY: AMR 06/22/11 - Issue TK-07089, Fixing performance issue with if exists statement.
 *
 *USAGE:
 * Save the passed in values for the given report/username combination.
 * Saves a snapshot of the printer settings the last time the user printed
 * the given report. 
 *
 * INPUT PARAMETERS
 *    @username         VPUserName
 *    @reportid			ReportID
 *    @printername		String (128)
 *    @papersource      Int
 *    @papersize        Int
 *    @duplex           SmallInt
 *    @orientation      SmallInt
 *    @lastaccessdate   Small Date Time
 *
 * OUTPUT PARAMETERS
 *    @msg           error message from
 *
 * RETURN VALUE
 *    none
 *****************************************************/
    (
      @username VARCHAR(128) = NULL ,
      @reportid INT = NULL ,
      @printername VARCHAR(256) = NULL ,
      @papersource INT = NULL ,
      @papersize INT = NULL ,
      @duplex SMALLINT = NULL ,
      @orientation SMALLINT = NULL ,
      @lastaccessdate SMALLDATETIME = NULL ,
      @msg VARCHAR(255) OUTPUT
	
    )
AS 
    SET NOCOUNT OFF
    DECLARE @rcode INT
    SELECT  @rcode = 0

    IF @username IS NULL 
        BEGIN
            SELECT  @msg = 'Missing VP User Name' ,
                    @rcode = 1
            GOTO vspexit
        END

    IF @reportid IS NULL
        OR @reportid = 0 
        BEGIN
            SELECT  @msg = 'Missing ReportID' ,
                    @rcode = 1
            GOTO vspexit
        END

    IF @reportid > 0 
        BEGIN
            IF NOT EXISTS(	SELECT 1
             --use inline table function for performance issue
							FROM   dbo.vfRPRTShared(@reportid)
                 
               ) 
                BEGIN
                    SELECT  @msg = 'VP User:  ' + @username + 'Report ID: '
                            + CONVERT(VARCHAR, ISNULL(@reportid, 0))
                            + 'does not exist!' ,
                            @rcode = 1
                    GOTO vspexit
                END
        END

    IF ( SELECT COUNT(*)
         FROM   dbo.vRPUP
         WHERE  VPUserName = @username
                AND ReportID = @reportid
       ) = 0 
        BEGIN
            INSERT  INTO vRPUP
                    ( VPUserName ,
                      ReportID ,
                      PrinterName ,
                      PaperSource ,
                      PaperSize ,
                      Duplex ,
                      Orientation ,
                      LastAccessed
                    )
            VALUES  ( @username ,
                      @reportid ,
                      @printername ,
                      @papersource ,
                      @papersize ,
                      @duplex ,
                      @orientation ,
                      @lastaccessdate
                    )
            IF @@ROWCOUNT = 0 
                BEGIN
                    SELECT  @msg = 'VP User:  ' + @username + 'Report ID: '
                            + CONVERT(VARCHAR, ISNULL(@reportid, 0))
                            + ' did not insert!' ,
                            @rcode = 1
                    GOTO vspexit
                END
        END
    ELSE 
        BEGIN
            UPDATE  dbo.vRPUP
            SET     PrinterName = ISNULL(@printername, PrinterName) ,
                    PaperSource = ISNULL(@papersource, PaperSource) ,
                    PaperSize = ISNULL(@papersize, PaperSize) ,
                    Duplex = ISNULL(@duplex, Duplex) ,
                    Orientation = ISNULL(@orientation, Orientation) ,
                    LastAccessed = ISNULL(@lastaccessdate, LastAccessed)
            FROM    dbo.vRPUP
            WHERE   VPUserName = @username
                    AND ReportID = @reportid

            IF @@ROWCOUNT = 0 
                BEGIN
                    SELECT  @msg = 'VP User:  ' + @username + 'Report ID: '
                            + CONVERT(VARCHAR, ISNULL(@reportid, 0))
                            + ' did not update!' ,
                            @rcode = 1
                    GOTO vspexit
                END
        END

    vspexit:
    IF @rcode <> 0 
        SELECT  @msg = @msg + CHAR(13) + CHAR(10)
                + '[vspRPSavePrinterSettings]'	
    RETURN @rcode




GO
GRANT EXECUTE ON  [dbo].[vspRPSavePrinterSettings] TO [public]
GO
