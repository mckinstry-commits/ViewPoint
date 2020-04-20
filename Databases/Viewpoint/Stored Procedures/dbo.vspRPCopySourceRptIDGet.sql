SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE    PROC [dbo].[vspRPCopySourceRptIDGet]
    (
      @reportid INT ,
      @msg VARCHAR(256) OUTPUT
    )

/********************************
* Created: TRL  07/11/05  
* Modified: AMR 06/22/11 - Issue TK-07089 , Fixing performance issue with if exists statement.
* Modified: DK 06/11/12 - TK-15612: Added case statements to return a Custom location and path 
*			for the report copy process. 
*
* Called from RP Report Copy form to retrieve
* report type information.
*
* Input:
*	none
*
* Output:
*	resultset - current report type information
*	
* Return code:
*	0 = success, 1 = failure
*
*********************************/
AS 
    SET nocount ON
	
    DECLARE @rcode INT
	
    SELECT  @rcode = 0

    IF ISNULL(@reportid, 0) = 0 
        BEGIN
            SELECT  @msg = 'Invalid Report ID - cannot load report information.' ,
                    @rcode = 1
            GOTO vspexit
        END

    IF @reportid <= 9999 
        BEGIN
	-- resultset of current Report Types --
            SELECT  RPRT.ReportID ,
                    RPRT.Title ,
                    RPRT.Location,
                    CASE	WHEN DDCI.Seq = 1	THEN 'RS_Custom'
							WHEN DDCI.Seq = 0	THEN 'Custom'
							ELSE RPRT.Location
					END AS ToLocation, 
					RPRL.Path,
					CASE	WHEN DDCI.Seq = 1	THEN (SELECT RPRL.Path FROM RPRL WHERE RPRL.Location = 'RS_Custom')
							WHEN DDCI.Seq = 0	THEN (SELECT RPRL.Path FROM RPRL WHERE RPRL.Location = 'Custom')
							ELSE RPRL.Path
					END AS ToPath,
                    RPRT.FileName ,
                    RPRT.ReportType ,
                    RPRT.ShowOnMenu ,
                    RPRT.AppType ,
                    DDCI.Seq AS DDCISeq,
                    CASE WHEN RPRT.ReportID <= 9999 THEN 'viewpointcs'
                    END AS ReportOwner ,
                    RPRT.ReportMemo ,
                    RPRT.ReportDesc ,
                    RPRT.IconKey ,
                    FormsAssigned = CASE WHEN COUNT(RPFR.ReportID) >= 1
                                         THEN 'Y'
                                         ELSE 'N'
                                    END ,
                    MenusAssigned = CASE WHEN COUNT(RPRM.ReportID) >= 1
                                         THEN 'Y'
                                         ELSE 'N'
                                    END ,
                    ReportSecurity = CASE WHEN COUNT(vRPRS.ReportID) >= 1
                                          THEN 'Y'
                                          ELSE 'N'
                                     END ,
                    PrintPref = CASE WHEN ( vRPUP.ReportID ) >= 1 THEN 'Y'
                                     ELSE 'N'
                                END
            FROM    dbo.RPRT WITH ( NOLOCK )
                    LEFT JOIN dbo.RPRL WITH ( NOLOCK ) ON RPRT.Location = RPRL.Location
                    LEFT JOIN dbo.RPFR WITH ( NOLOCK ) ON RPRT.ReportID = RPFR.ReportID
                    LEFT JOIN dbo.RPRM WITH ( NOLOCK ) ON RPRT.ReportID = RPRM.ReportID
                    LEFT JOIN dbo.vRPRS WITH ( NOLOCK ) ON RPRT.ReportID = vRPRS.ReportID
                    LEFT JOIN dbo.vRPUP WITH ( NOLOCK ) ON RPRT.ReportID = vRPUP.ReportID
                    LEFT JOIN dbo.DDCI ON RPRT.AppType = DDCI.DisplayValue
										AND DDCI.ComboType = 'RPRTAppType'
            WHERE   RPRT.ReportID = @reportid
            GROUP BY RPRT.ReportID ,
                    RPRT.Title ,
                    RPRT.Location ,
                    RPRL.Path ,
                    RPRT.FileName ,
                    RPRT.ReportType ,
                    RPRT.ShowOnMenu ,
                    RPRT.AppType ,
                    DDCI.Seq,
                    RPRT.ReportMemo ,
                    RPRT.ReportDesc ,
                    vRPUP.ReportID ,
                    RPRT.IconKey
            ORDER BY RPRT.ReportID
            IF @@rowcount = 0 
                BEGIN
                    SELECT  @msg = 'Invalid Report ID - cannot load report information.' ,
                            @rcode = 1
                    GOTO vspexit
                END
        END

    IF @reportid >= 10000 
        BEGIN
	-- resultset of current Report Types --
            SELECT  RPRTShared.ReportID ,
                    RPRTShared.Title ,
                    RPRTShared.Location,
                    CASE	WHEN DDCI.Seq = 1	THEN 'RS_Custom'
							WHEN DDCI.Seq = 0	THEN 'Custom'
							ELSE RPRTShared.Location
					END AS ToLocation, 
					RPRL.Path,
					CASE	WHEN DDCI.Seq = 1	THEN (SELECT RPRL.Path FROM RPRL WHERE RPRL.Location = 'RS_Custom')
							WHEN DDCI.Seq = 0	THEN (SELECT RPRL.Path FROM RPRL WHERE RPRL.Location = 'Custom')
							ELSE RPRL.Path
					END AS ToPath,
                    RPRTShared.FileName ,
                    RPRTShared.ReportType ,
                    RPRTShared.ShowOnMenu ,
                    RPRTShared.AppType ,
                    DDCI.Seq AS DDCISeq,
                    CASE WHEN RPRTShared.ReportID <= 9999 THEN 'viewpointcs'
                         ELSE ' '
                    END AS ReportOwner ,
                    RPRTShared.ReportMemo ,
                    RPRTShared.ReportDesc ,
                    RPRTShared.IconKey ,
                    FormsAssigned = CASE WHEN COUNT(RPFRc.ReportID) >= 1
                                         THEN 'Y'
                                         ELSE 'N'
                                    END ,
                    MenusAssigned = CASE WHEN COUNT(RPRMc.ReportID) >= 1
                                         THEN 'Y'
                                         ELSE 'N'
                                    END ,
                    ReportSecurity = CASE WHEN COUNT(vRPRS.ReportID) >= 1
                                          THEN 'Y'
                                          ELSE 'N'
                                     END ,
                    PrintPref = CASE WHEN ( vRPUP.ReportID ) >= 1 THEN 'Y'
                                     ELSE 'N'
                                END
                    --use inline table function for performance issue
            FROM    dbo.vfRPRTShared(@reportid)  RPRTShared
                    LEFT JOIN dbo.RPRL WITH ( NOLOCK ) ON RPRTShared.Location = RPRL.Location
                    LEFT JOIN dbo.RPFRc WITH ( NOLOCK ) ON RPRTShared.ReportID = RPFRc.ReportID
                    LEFT JOIN dbo.RPRMc WITH ( NOLOCK ) ON RPRTShared.ReportID = RPRMc.ReportID
                    LEFT JOIN dbo.vRPRS WITH ( NOLOCK ) ON RPRTShared.ReportID = vRPRS.ReportID
                    LEFT JOIN dbo.vRPUP WITH ( NOLOCK ) ON RPRTShared.ReportID = vRPUP.ReportID
                    LEFT JOIN dbo.DDCI ON RPRTShared.AppType = DDCI.DisplayValue
										AND DDCI.ComboType = 'RPRTAppType'
            WHERE   RPRTShared.ReportID = @reportid
            GROUP BY RPRTShared.ReportID ,
                    RPRTShared.Title ,
                    RPRTShared.Location ,
                    RPRL.Path ,
                    RPRTShared.FileName ,
                    RPRTShared.ReportType ,
                    RPRTShared.ShowOnMenu ,
                    RPRTShared.AppType ,
                    DDCI.Seq,
                    RPRTShared.ReportOwner ,
                    RPRTShared.ReportMemo ,
                    RPRTShared.ReportDesc ,
                    vRPUP.ReportID ,
                    RPRTShared.IconKey
            ORDER BY RPRTShared.ReportID
            IF @@rowcount = 0 
                BEGIN
                    SELECT  @msg = 'Invalid Report ID - cannot load report information.' ,
                            @rcode = 1
                    GOTO vspexit
                END
        END


    vspexit:
    RETURN @rcode











GO
GRANT EXECUTE ON  [dbo].[vspRPCopySourceRptIDGet] TO [public]
GO
