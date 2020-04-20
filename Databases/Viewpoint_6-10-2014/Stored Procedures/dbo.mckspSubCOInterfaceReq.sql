SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 11/14/13
-- Description:	Sub CO Request for Interface
-- =============================================
CREATE PROCEDURE [dbo].[mckspSubCOInterfaceReq] 
	-- Add the parameters for the stored procedure here
	@Company TINYINT = 0, 
	@Project varchar(30) = 0
	,@SL varchar(30) = 0
	,@SubCO SMALLINT = 0
	,@To VARCHAR(100) = 'erptest@mckinstry.com'
	,@rcode TINYINT = 0
	,@ReturnMessage varchar(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF NOT EXISTS(SELECT 1 FROM PMSubcontractCO sco WHERE @Company = sco.PMCo AND @Project = sco.Project AND @SL = SL AND @SubCO = sco.SubCO)
		BEGIN --Record not saved.
			SELECT @ReturnMessage = 'This record does not exist.  Please save the record and try again.', @rcode=1
			goto spexit
		END
		ELSE
		BEGIN --Record exists
		IF EXISTS(SELECT 1 
			FROM PMSubcontractCO sco 
			INNER JOIN PMSL si ON si.PMCo = sco.PMCo AND si.Project = sco.Project AND si.SubCO = sco.SubCO
			WHERE @Company = sco.PMCo AND @Project = sco.Project AND @SL = sco.SL AND @SubCO = sco.SubCO AND sco.ReadyForAcctg = 'Y' /*AND si.SLItemType = 2 AND si.IntFlag = 'Y'*/)
			BEGIN

				DECLARE @subject NVARCHAR(100)
				DECLARE @tableHTML  NVARCHAR(MAX)
				
				SELECT @subject = COALESCE('AN SCO from project: '+ Project +' is ready to interface.' ,'') FROM dbo.PMSubcontractCO WHERE @Company = SLCo AND @Project = Project AND @SL = SL AND @SubCO = SubCO 
				SET @tableHTML =
				N'<H3>' + @subject + '</H3>' +
				N'<font size="-2">' +
				N'<table border="1">' +
				N'<tr bgcolor=silver>' +
				N'<th>Co</th>' +
				N'<th>Project</th>' +
				N'<th>SubCO</th>' +
				N'<th>Description</th>' +
				N'<th>SL</th>' +
				N'<th>Approved By</th>' +
				 N'</tr>' +
				CAST 
				( 
					( 
						SELECT
							td = COALESCE(sco.PMCo,' '), ''
						,	td = COALESCE(sco.Project,' '), ''
						,	td = COALESCE(sco.SubCO ,' '), ''
						,	td = COALESCE(sco.Description,' '), ''
						,	td = COALESCE(sco.SL,' '), '' AS VendorName
						,	td = COALESCE(sco.ApprovedBy,' '), ''
						FROM 
							PMSubcontractCO sco
						WHERE @Company=SLCo AND @Project=Project AND @SL=SL AND @SubCO = SubCO
						ORDER BY 2	
						FOR XML PATH('tr'), TYPE 
					) AS NVARCHAR(MAX) ) + N'</table>' + N'<br/><br/>'
			
				EXEC msdb.dbo.sp_send_dbmail 
					@profile_name = 'Viewpoint',
					@recipients = @To,
					@subject = @subject,
					@body = @tableHTML,
					@body_format = 'HTML';

				SELECT @ReturnMessage = 'Request to interface successfully sent.', @rcode=0
				GOTO spexit
			END
			ELSE 
			BEGIN
				IF EXISTS(SELECT 1 
					FROM PMSubcontractCO sco 
					INNER JOIN PMSL si ON si.PMCo = sco.PMCo AND si.Project = sco.Project AND si.SubCO = sco.SubCO
					WHERE @Company = sco.PMCo AND @Project = sco.Project AND @SL = sco.SL AND @SubCO = sco.SubCO AND sco.ReadyForAcctg = 'N' /*AND si.SLItemType = 2 AND si.IntFlag = 'Y'*/)
					BEGIN
						SELECT @ReturnMessage='This Sub CO is not ready for interface because the "Ready for Accounting" checkbox is not checked.', @rcode=1
						GOTO spexit
					END
				IF EXISTS(SELECT 1 
					FROM PMSubcontractCO sco 
					INNER JOIN PMSL si ON si.PMCo = sco.PMCo AND si.Project = sco.Project AND si.SubCO = sco.SubCO
					WHERE @Company = sco.PMCo AND @Project = sco.Project AND @SL = sco.SL AND @SubCO = sco.SubCO AND sco.ReadyForAcctg = 'Y' /*AND si.SLItemType = 2 AND si.IntFlag = 'N'*/)
					BEGIN
						SELECT @ReturnMessage='This Sub CO is not ready for interface because the "Ready for Accounting" checkbox is not checked.', @rcode=1
						GOTO spexit
					END
			END
		END
	

	spexit:
	BEGIN
	return @rcode
	END
END
GO
GRANT EXECUTE ON  [dbo].[mckspSubCOInterfaceReq] TO [public]
GO
