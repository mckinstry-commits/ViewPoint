SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 11/14/13
-- Description:	Request for Interface ACO
-- =============================================
CREATE PROCEDURE [dbo].[mckspACORequestInterface] 
	-- Add the parameters for the stored procedure here
	@Company TINYINT = 0, 
	@Project bProject = 0
	,@ACO bACO = 0
	,@To NVARCHAR(MAX) = 'erptest@mckinstry.com'
	,@rcode INT = 0
	,@ReturnMessage VARCHAR(255) OUTPUT 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;



    -- Insert statements for procedure here
IF EXISTS(SELECT 1 FROM PMOH WHERE @Company=PMCo AND @Project=Project AND @ACO = ACO AND ReadyForAcctg = 'Y')
	BEGIN  --Send Message
	IF EXISTS(SELECT 1 FROM PMOI WHERE @Company=PMCo AND @Project=Project AND @ACO = ACO AND Approved='Y' AND InterfacedDate IS NULL)
		BEGIN
			DECLARE @subject NVARCHAR(100)
			,@tableHTML  NVARCHAR(MAX)
			,@ApprovedRev bDollar
			,@ApprovedCost bDollar

			SET @ApprovedRev = (SELECT SUM(ApprovedAmt) FROM PMOI WHERE @Company=PMCo AND @Project = Project AND @ACO = ACO)
			SET @ApprovedCost = (SELECT SUM(EstCost) FROM PMOL WHERE @Company=PMCo AND @Project = Project AND @ACO = ACO)
			SELECT @subject = COALESCE('ACO Interface Request - Co: ' + CONVERT(varchar(3),@Company) + ' - Project: ' + @Project+ ' - ACO: ' + @ACO, ' ')
	
			SET @tableHTML =
			N'<H3>' + @subject + '</H3>' +
			N'<font size="-2">' +
			N'<table border="1">' +
			N'<tr bgcolor=silver>' +
			N'<th>Co</th>' + --1
			N'<th>Project</th>' +
			N'<th>ACO</th>' +
			N'<th>Description</th>' +
			N'<th>Approved Revenue</th>' +
			N'<th>Approved Cost</th>' +
				N'</tr>' +
			CAST 
			( 
				( 
					SELECT
						td = COALESCE(aco.PMCo,' '), '' --1
					,	td = COALESCE(aco.Project,' '), '' --2
					,	td = COALESCE(aco.ACO,' '), '' --3
					,	td = COALESCE(aco.Description,' '), ''--4
					,	td = COALESCE(@ApprovedRev,' '), '' AS ApprovedRev --5
					,	td = COALESCE(@ApprovedCost,' '), '' AS ApprovedCost
					
					FROM PMOH aco
					WHERE aco.PMCo=@Company AND aco.Project=@Project AND aco.ACO=@ACO	
					FOR XML PATH('tr'), TYPE 
				) AS NVARCHAR(MAX) ) + N'</table>' + N'<br/><br/>'

			EXEC msdb.dbo.sp_send_dbmail 
				@profile_name = 'Viewpoint',
				@recipients = @To,
				@subject = @subject,
				@body = @tableHTML,
				@body_format = 'HTML' 

			SELECT @ReturnMessage= 'Request to interface ACO sent successfully.',@rcode=0
			GOTO spexit
		END
		ELSE
		BEGIN --No Approved ACO Items or All Items Already Interfaced.
			SELECT @ReturnMessage = 'This ACO contains no uninterfaced, approved items.  Please approve at least one uninterfaced item and try again.', @rcode=1
			GOTO spexit
		END
	END
	ELSE
	BEGIN --Ready for Acct not checked
	IF EXISTS(SELECT 1 FROM PMOH WHERE @Company=PMCo AND @Project=Project AND @ACO = ACO AND ReadyForAcctg = 'N')
		SELECT @ReturnMessage = 'This ACO has not been marked "Ready for Accounting".  Please check the box and try again.', @rcode=1
		GOTO spexit
	END
	spexit:
	RETURN @rcode
END
GO
GRANT EXECUTE ON  [dbo].[mckspACORequestInterface] TO [public]
GO
