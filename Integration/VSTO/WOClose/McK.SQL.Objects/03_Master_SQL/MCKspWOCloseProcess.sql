USE Viewpoint
GO

If EXISTS ( Select * From INFORMATION_SCHEMA.ROUTINES Where ROUTINE_NAME='MCKspWOCloseProcess' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='PROCEDURE' )
Begin
	Print 'DROP PROCEDURE dbo.MCKspWOCloseProcess'
	DROP PROCEDURE dbo.MCKspWOCloseProcess
End
GO

Print 'CREATE PROCEDURE dbo.MCKspWOCloseProcess'
GO


CREATE PROCEDURE dbo.MCKspWOCloseProcess
(
    @SMCo bCompany,
    @BatchMonth bMonth,
    @Rbatchid bBatchID output  
)
AS
/*
PURPOSE: Close OPEN Work Orders.  If open; close Scopes, delete Trips.

DATE         TECH      DESCRIPTION
==================================================================================================
2019-02-14	Leo G.	TFS 4182 - BUG FIXED @wo (changed from INT to VARCHAR) 
					provide better error reporting, more efficient
2018-05-17  Curt S. TFS 3400 - add inner cursor to loop through work order scopes and close them

*/
DECLARE @smco bCompany = @SMCo;
DECLARE @month bMonth = @BatchMonth;
DECLARE @MyTripCount INT;
DECLARE @wo INT;
DECLARE @errMsg VARCHAR(255);

-- begin TFS 3400
DECLARE @FirstOfMonth SMALLDATETIME
DECLARE @FetchWorkOrder INT
DECLARE @FetchScope INT
DECLARE @Scope INT
DECLARE @pIsTrackingWIP CHAR(1)
DECLARE @pClosestOpenMonth SMALLDATETIME
DECLARE @pMsg VARCHAR(255)

DECLARE @RecordsPassed INT
DECLARE	@RecordsTotal INT

SET @FirstOfMonth = dbo.mckfFirstDayOfMonth(GETDATE())

-- end TFS 3400

SELECT @Rbatchid =  ISNULL(MAX(ISNULL(CAST(BatchNum AS INT),0)) + 1, 1) FROM dbo.MCKWOCloseStage -- grab next batch number

UPDATE dbo.MCKWOCloseStage
SET BatchNum = @Rbatchid
WHERE BatchMth = @month
	AND BatchNum IS NULL
	AND Co = @SMCo

DECLARE WO_Cursor CURSOR LOCAL READ_ONLY STATIC FORWARD_ONLY FOR
SELECT DISTINCT
       @smco AS Co,
       a.WO
FROM dbo.MCKWOCloseStage a
	INNER JOIN 
     dbo.SMWorkOrder b
		ON	@smco = b.SMCo
			AND a.WO = b.WorkOrder
WHERE a.BatchMth = @month
      AND a.BatchNum = @Rbatchid

BEGIN

    BEGIN
        OPEN WO_Cursor;
        FETCH NEXT FROM WO_Cursor
        INTO @smco,
             @wo;

		-- TFS 3400 store fetch status in variable because inner cursor fetch will overwrite the value
		-- WHILE @@FETCH_STATUS = 0
		SET @FetchWorkOrder = @@FETCH_STATUS
		WHILE @FetchWorkOrder = 0 

        BEGIN

			-- begin TFS 3400
			SET @pIsTrackingWIP = 'N'
			SET @pClosestOpenMonth = NULL
			SET @pMsg = ''

			DECLARE Scope_Cursor CURSOR LOCAL STATIC FORWARD_ONLY FOR
				SELECT Scope
				FROM dbo.SMWorkOrderScope s
				WHERE s.WorkOrder = @wo AND s.SMCo = @smco AND s.Status <> 4 -- Scope Status 4 = Closed

			OPEN Scope_Cursor
			FETCH NEXT FROM Scope_Cursor INTO @Scope
			SET @FetchScope = @@FETCH_STATUS

			-- loop through scopes for this work order and close them
			WHILE @FetchScope = 0
			BEGIN
				-- call VP proc to close the scope
				EXEC dbo.vspSMScopeCompleteChange @SMCo = @smco,
                            @WorkOrder = @wo,
                            @Scope = @Scope,
                            @WIPHasBeenTransferred = 0, 
                            @BatchMonth = @FirstOfMonth,
                            @DesiredStatus = 4,
                            @IsTrackingWIP = @pIsTrackingWIP OUTPUT,
                            @ClosestOpenMonth = @pClosestOpenMonth OUTPUT,
                            @msg = @pMsg OUTPUT
				
				-- get next scope for this work order and save the fetch status
				FETCH NEXT FROM Scope_Cursor INTO @Scope
				SET @FetchScope = @@FETCH_STATUS
			END

			CLOSE Scope_Cursor
			DEALLOCATE Scope_Cursor
			-- end TFS 3400

           EXEC [dbo].[vspSMWorkOrderChangeStatus] @SMCo = @smco,
                                                    @WorkOrder = @wo,
                                                    @WOStatus = 1,
                                                    @DeleteOpenTrips = 0,
                                                    @TripCount = @MyTripCount OUTPUT,
                                                    @msg = @errMsg OUTPUT;
			/* Mark FAILED records */
			IF (@errMsg IS NOT NULL)
				BEGIN
					UPDATE dbo.MCKWOCloseStage
						SET CloseStatus = 'F',
							ErrorMsg = @errMsg 
					WHERE	  BatchNum  = @Rbatchid
						  AND BatchMth	= @month
						  AND WO		= @wo
						  AND Co		= @smco;

					SET @errMsg = NULL
                    
				END
			ELSE
				/* Mark SUCCESSFUL records */
				BEGIN
					UPDATE dbo.MCKWOCloseStage
					SET CloseStatus = 'P'
					WHERE	  BatchNum  = @Rbatchid
						  AND BatchMth	= @month
						  AND WO		= @wo
						  AND Co		= @smco;
				END
            
            FETCH NEXT FROM WO_Cursor
            INTO @smco,
                 @wo;
			
			-- TFS 3400 store fetch status in variable
			SET @FetchWorkOrder = @@FETCH_STATUS

        END;

        CLOSE WO_Cursor;
        DEALLOCATE WO_Cursor;
    END;


	/* Pass/failed counts */
    BEGIN
        SELECT @RecordsPassed = COUNT(*)
        FROM dbo.MCKWOCloseStage
        WHERE BatchNum = @Rbatchid
			  AND CloseStatus = 'P'

        SELECT @RecordsTotal = COUNT(*)
        FROM dbo.MCKWOCloseStage
        WHERE BatchNum = @Rbatchid

    END;

    --email the results
    DECLARE @tableHTML NVARCHAR(MAX),
            @subject NVARCHAR(100),
			@body1 NVARCHAR(MAX),
			@msge VARCHAR(2000);

    BEGIN
		SET @subject
			= N'VP WO Close List for Co: ' + CAST(@SMCo AS VARCHAR(3)) + N' - Batch Num: '
				+ CAST(@Rbatchid AS VARCHAR(15)) + N' - Batch Mth: ' + CAST(@BatchMonth AS VARCHAR(20))
				+ N' -  Batch Rec Count: ' + CAST(@RecordsPassed AS VARCHAR(6)) + '/' + CAST(@RecordsTotal AS VARCHAR(6));
		SET @msge
			= '<html><head><title>Viewpoint WO Close Processing Message</title></head><body>'
				+ '<p>Note: If there is no records to be processed, there will not be a list.<br/>'
				+ '<br/><br/></p>' 
				+ '<hr/><br/><font size="-2" color="silver"><i>' + @@SERVERNAME + '.' + DB_NAME() + ' [' + SUSER_SNAME() + ' @ ' + CONVERT(VARCHAR(20), GETDATE(), 100) + '] '
				+ '</i></font><br/><br/></body></html>';
		SET @tableHTML
			= N'<H3>' + @subject + N'</H3>' + N'<H4>' + @msge + N'</H4>' + N'<font size="-2">'
				+ N'<table border="1">' + N'<tr bgcolor=silver>' + N'<th>Co</th>' + N'<th>WO</th>'
				+ N'<th>Close Status</th>'+ N'<th>Errors</th>' + N'</tr>' + CAST(
														(
															SELECT td = COALESCE(@SMCo, ' '),
																	'',
																	td = COALESCE(a.WO, ' '),
																	'',
																	td = COALESCE(a.CloseStatus, ' '),
																	''
																	,
																	td = COALESCE(a.ErrorMsg, ' '),
																	''
															FROM dbo.MCKWOCloseStage a
															WHERE BatchNum = @Rbatchid
																AND BatchMth = @month
																AND Co = @SMCo
															ORDER BY 2
															FOR XML PATH('tr'), TYPE
														) AS NVARCHAR(MAX)) + N'</table>' + N'<br/><br/>';

		SET @body1 = ISNULL(@tableHTML, @msge);

		EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Viewpoint',
										@recipients = 'HOWARDS@mckinstry.com;JobClose@mckinstry.com',
										--@blind_copy_recipients = 'BenWi@mckinstry.com;LeoG@Mckinstry.com',
										@subject = @subject,
										@body = @body1,
										@body_format = 'HTML';
    END;

	SELECT	
		  a.Co			AS SMCo
		, a.WO			AS WorkOrder
		, a.BatchNum
		, a.BatchMth
		, a.Creationdate AS ErrDate
		, a.CloseStatus	 AS CloseStatus
		, a.ErrorMsg	 AS Errmsg
	FROM dbo.MCKWOCloseStage a
	WHERE	  BatchNum		= @Rbatchid
			AND BatchMth	= @month
			AND a.Co		= @SMCo
			AND CloseStatus <> 'P';
END;

GO

Grant EXECUTE ON dbo.MCKspWOCloseProcess TO [MCKINSTRY\Viewpoint Users]

/* TEST ***

DECLARE @Rbatchid INT
EXEC dbo.MCKspWOCloseProcess 1, '2019-02-01', @Rbatchid OUT
PRINT @Rbatchid

*/