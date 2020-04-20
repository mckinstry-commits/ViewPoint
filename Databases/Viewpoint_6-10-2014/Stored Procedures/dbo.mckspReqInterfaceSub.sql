SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 11/14/13
-- Description:	Request for Subcontract Interface
-- =============================================
CREATE PROCEDURE [dbo].[mckspReqInterfaceSub] 
	-- Add the parameters for the stored procedure here
	@Company TINYINT = 0, 
	@SL varchar(30) = 0,
	@To NVARCHAR(60) = 'erptest@mckinstry.com'
	,@rcode TINYINT =0,
	@ReturnMessage VARCHAR(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @subject NVARCHAR(100)
	,@tableHTML  NVARCHAR(MAX)
	,@OrigSLSum bDollar

	SET @OrigSLSum = (SELECT SUM(Amount) FROM PMSL WHERE PMCo = @Company AND SL = @SL AND SLItemType <>2)
	SELECT @subject = 'SL Interface: '
	SELECT @subject= COALESCE(@subject + ' '+ @SL + ' is ready for review.  Please create document and interface when ready.','')

    -- Insert statements for procedure here
	IF NOT EXISTS(SELECT 1 FROM SLHDPM h
					INNER JOIN PMSL i ON i.PMCo = h.PMCo AND i.SL = h.SL
					WHERE h.SLCo = @Company AND h.SL = @SL)
				BEGIN
					SELECT @ReturnMessage = 'No valid SL Items exist.  Please add items to the Subcontract and try again.', @rcode = 1
					GOTO spexit
				END
				ELSE
				IF EXISTS(SELECT 1 FROM SLHDPM h
					INNER JOIN PMSL i ON i.PMCo = h.PMCo AND i.SL = h.SL
					WHERE h.SLCo = @Company AND h.SL = @SL AND i.Phase IS NULL)
					BEGIN
						SELECT @ReturnMessage = 'No valid SL Items exist.  Please assign Phases to items and try again.', @rcode = 1
						GOTO spexit
					END


	IF EXISTS(SELECT 1 FROM SLHDPM WHERE SLCo = @Company AND SL=@SL)
	BEGIN
		SET @tableHTML =
				N'<H3>' + @subject + '</H3>' +
				N'<font size="-2">' +
				N'<table border="1">' +
				N'<tr bgcolor=silver>' +
				N'<th>Co</th>' + --1
				N'<th>Project</th>' +
				N'<th>SL</th>' +
				N'<th>Description</th>' +
				N'<th>Vendor</th>' +
				N'<th>Vendor Name</th>' +
				N'<th>Original Cost</th>' +
				 N'</tr>' +
				CAST 
				( 
					( 
						SELECT
							td = COALESCE(s.JCCo,' '), '' --1
						,	td = COALESCE(s.Project,' '), '' --2
						,	td = COALESCE(s.SL,' '), '' --3
						,	td = COALESCE(s.Description,' '), ''--4
						,	td = COALESCE(v.Vendor,' '), ''--4
						,	td = COALESCE(v.Name,' '), ''--4
						,	td = COALESCE(@OrigSLSum,' '), '' AS OrigCost --5
					
						FROM SLHDPM s
							JOIN APVM v ON v.VendorGroup=s.VendorGroup AND v.Vendor=s.Vendor
						WHERE s.SLCo = @Company AND s.SL = @SL					
						FOR XML PATH('tr'), TYPE 
					) AS NVARCHAR(MAX) ) + N'</table>' + N'<br/><br/>'

			SELECT  @tableHTML=@tableHTML+'<i>Original Cost is calculated as the total Amount from Non-Interfaced items on PM Subcontracts.</i></font>'

			IF (SELECT Approved FROM SLHDPM WHERE SLCo = @Company AND SL = @SL) = 'Y'
			BEGIN
				IF EXISTS(SELECT 1 FROM PMSL WHERE SLCo = @Company AND SL = @SL AND SendFlag = 'Y')
				BEGIN
					EXEC msdb.dbo.sp_send_dbmail 
						@profile_name = 'Viewpoint',
						@recipients = @To,
						@subject = @subject,
						@body = @tableHTML,
						@body_format = 'HTML' 
		

					SELECT @ReturnMessage = 'Document Request successfully sent.', @rcode=0
					GOTO spexit
				END
				ELSE
				BEGIN
				IF EXISTS(SELECT 1 FROM PMSL WHERE SLCo = @Company AND SL = @SL AND SendFlag = 'N')
					SELECT @ReturnMessage = 'This subcontract has no items marked ready to send.', @rcode=1
					GOTO spexit
				END
			END
			ELSE 
			BEGIN
				SELECT @ReturnMessage = 'This Subcontract does not have "Rte to SC" checked.  Request has not been sent', @rcode=1
				GOTO spexit
			END
		END
	ELSE
	BEGIN
		SELECT @ReturnMessage = 'Request has not been submitted.  SL: '+ @SL +' does not exist. Please save the record and try again.', @rcode=1
		GOTO spexit
	END
	spexit:
	BEGIN
	RETURN @rcode
	END
END
GO
GRANT EXECUTE ON  [dbo].[mckspReqInterfaceSub] TO [public]
GO
