SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 9/10/13
-- Description:	CopyUsertoReviewer
-- =============================================
CREATE PROCEDURE [dbo].[mckInsertReviewer] 
	-- Add the parameters for the stored procedure here
	(@Company int = 101,
	@Employee int = 0,
	@VPUserName nvarchar(50) = NULL,
	@Reviewer nvarchar(3) = NULL output)
AS
BEGIN
DECLARE @Abbr varchar(2)
DECLARE @AbbrCount int = 0

SET @Abbr = (SELECT (LEFT(e.FirstName,1)) + (LEFT(e.LastName, 1))
FROM PREH e WHERE e.PRCo = @Company AND e.Employee = @Employee)
--SET @Abbr = 'BO'
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
IF (SELECT COUNT(r.KeyID)
			FROM HQRV r
			WHERE @Abbr LIKE r.Reviewer + '%') = 0
	BEGIN
		SET @Reviewer = @Abbr 
	END
IF (SELECT COUNT(*)
			FROM HQRV r
			WHERE @Abbr LIKE r.Reviewer + '%') <> 0
	BEGIN
		SET @AbbrCount = 	
			(SELECT COUNT(*) - 1
			FROM HQRV r
			WHERE @Abbr LIKE r.Reviewer + '%');
	
		SET @Reviewer = (SELECT (@Abbr) + CAST(@AbbrCount AS nvarchar))
	END
	BEGIN
	INSERT INTO HQRV (Reviewer, Name, RevEmail)
		VALUES 
			(@Reviewer,
			(SELECT e.FirstName + ' ' + e.LastName 
				FROM PREH e WHERE e.PRCo = @Company AND e.Employee = @Employee),
				(SELECT e.Email FROM PREH e WHERE e.PRCo = @Company AND e.Employee = @Employee)); 
	INSERT INTO bHQRP (Reviewer, VPUserName)
		VALUES (@Reviewer, @VPUserName);

	UPDATE vDDUP
		SET dbo.vDDUP.udReviewer = @Reviewer
		WHERE VPUserName = @VPUserName;
	END

END
GO
