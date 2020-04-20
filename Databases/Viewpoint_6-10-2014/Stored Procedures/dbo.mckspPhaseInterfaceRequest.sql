SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 11/13/13
-- Description:	Project Phases Interface Request Email
-- =============================================
CREATE PROCEDURE [dbo].[mckspPhaseInterfaceRequest] 
	-- Add the parameters for the stored procedure here
	@PMCo tinyint = 0, 
	@Project varchar(30) = 0
	,@To VARCHAR(255) = 'erptest@mckinstry.com'
	,@Requestor bVPUserName = SUSER_SNAME
	,@rcode INT=0
	,@ReturnMessage VARCHAR(255) = '' OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	
	-- Insert statements for procedure here
	IF EXISTS(SELECT 1 FROM JCCH WHERE (JCCo = @PMCo AND Job = @Project) AND SourceStatus = 'Y')
	BEGIN
		DECLARE @subject NVARCHAR(100)

		SELECT @subject = 'Project Update'
		SELECT @subject = COALESCE(@subject + ' : ' + @Project,@subject + 's')
		SELECT @subject = @subject + ' has been requested by ' + @Requestor


		DECLARE @tableHTML  NVARCHAR(MAX) 
		DECLARE @SumOrigCost bDollar
		SET @SumOrigCost = (SELECT SUM(OrigCost) FROM JCCH WHERE JCCo = @PMCo AND Job = @Project GROUP BY JCCo, Job)

		SET @tableHTML =
			N'<H3>' + @subject + '</H3>' +
			N'<font size="-2">' +
			N'<table border="1">' +
			N'<tr bgcolor=silver>' +
			N'<th>Co</th>' + --1
			N'<th>Project</th>' +
			N'<th>Description</th>' +
			N'<th>Original Cost</th>' +
			 N'</tr>' +
			CAST 
			( 
				( 
					SELECT
						td = COALESCE(j.JCCo,' '), '' --1
					,	td = COALESCE(j.Job,' '), '' --2
					,	td = COALESCE(j.Description,' '), '' --3
					,	td = COALESCE(@SumOrigCost,' '), '' AS OrigCost --3
					
					FROM JCJM j
					WHERE j.JCCo=@PMCo AND j.Job = @Project						
					FOR XML PATH('tr'), TYPE 
				) AS NVARCHAR(MAX) ) + N'</table>' + N'<br/><br/>'

		SELECT  @tableHTML=@tableHTML+'<i>Original Cost is calculated as the original total of Phase Cost Types</i></font>'
		
		EXEC msdb.dbo.sp_send_dbmail 
			@profile_name = 'Viewpoint',
			@recipients = @To,
			@subject = @subject,
			@body = @tableHTML,
			@body_format = 'HTML' 
		
		SELECT @ReturnMessage = 'A request to interface has been sent.', @rcode=0
		GOTO spexit
	END
	ELSE
	BEGIN
		SELECT @ReturnMessage = 'This project has no phase details that are ready to interface.', @rcode=1
		GOTO spexit
	END
	
	spexit:
	BEGIN
	RETURN @rcode
	END

END
GO
GRANT EXECUTE ON  [dbo].[mckspPhaseInterfaceRequest] TO [public]
GO
