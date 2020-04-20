SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspRPFRInfo    Script Date: 8/28/99 9:33:38 AM ******/
 
 
  
CREATE      PROC [dbo].[bspRPFRInfo]
/*************************************************
* Created: ??
* Modified: kb 11/8/98 - so will get stuff from RPFR and RPFRupdate
* 			jre  10/17/99 - do notl get stuff from RPFRupdate
* 			LM 02/25/00 - Added company to select statement 
* 			JRE 09/09/04 - 25516 - performance - don't count security records, rather test for existance
* 			DANF 09/14/2004 - Issue 19246 added new login
* 			GG 01/23/05 - VP6.0 mods for vRP tables
*			TRL 03/19/07 - Updated for VP 6
*			AMR 06/22/11 - Issue TK-06411, Fixing performance issue with if exists statement.
************************************************/
    (
      @co bCompany = 0 ,
      @form VARCHAR(30) = NULL ,
      @msg VARCHAR(60) OUTPUT
    )
AS 
    SET nocount ON
  
    DECLARE @rcode INT ,
			@securityexists INT
  	
    SELECT  @rcode = 0 ,
            @msg = 'Nothing'
  
    IF @co = 0 
        BEGIN
            SELECT  @msg = 'Missing Company number!' ,
                    @rcode = 1
            GOTO bspexit
        END
 
    IF @form IS NULL 
        BEGIN
            SELECT  @msg = 'Missing Form!' ,
                    @rcode = 1
            GOTO bspexit
        END
  	
    SELECT  @securityexists = 0
    SELECT TOP 1
            @securityexists = 1
    FROM    RPFR WITH ( NOLOCK )
            LEFT JOIN RPRS WITH ( NOLOCK ) ON RPFR.ReportID = RPRS.ReportID
    WHERE   RPFR.Form = @form
  	
    IF ( SUSER_SNAME() = 'bidtek'
         OR SUSER_SNAME() = 'viewpointcs'
         OR @securityexists = 0
       ) 
        BEGIN
            SELECT  t.Title ,
                    [FileName]
            FROM	dbo.RPFR r WITH ( NOLOCK ) 
					--use inline table function for performance issue
                    CROSS APPLY (SELECT ReportID,ShowOnMenu,Title,[FileName] FROM dbo.vfRPRTShared(r.ReportID)) t 
            WHERE   r.Form = @form
                    AND ShowOnMenu <> 'N'
            ORDER BY t.Title
        END
    ELSE 
        BEGIN
            SELECT  t.Title ,
                    [FileName]
            FROM    dbo.RPRS u WITH ( NOLOCK )
					--use inline table function for performance issue
                    CROSS APPLY (SELECT ReportID,ShowOnMenu,Title,[FileName] FROM dbo.vfRPRTShared(u.ReportID)) t 
                    JOIN RPFR r WITH ( NOLOCK ) ON t.ReportID = r.ReportID
                    
            WHERE   u.Co = @co
                    AND r.Form = @form
                    AND ShowOnMenu <> 'N'
                    AND u.VPUserName = SUSER_SNAME()
                    AND u.Access = 0
            ORDER BY t.Title
        END
 
    bspexit:
  
    RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspRPFRInfo] TO [public]
GO
