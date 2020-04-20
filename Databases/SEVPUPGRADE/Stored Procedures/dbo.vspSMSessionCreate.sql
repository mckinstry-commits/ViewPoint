SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 4/4/11
-- Description:	Creates a new SM session and returns the SMSessionID
-- Modified:    08/16/11 Eric V - Add input parameter Prebilling
-- =============================================
CREATE PROCEDURE [dbo].[vspSMSessionCreate]
	@SMCo bCompany, @SMSessionID int OUTPUT, @Prebilling bit=0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    --Create the next session. Do it in a transaction so that no one else can end up with the
	--same session id.
	BEGIN TRAN
		SELECT @SMSessionID = ISNULL(MAX(SMSessionID), 0) + 1
		FROM dbo.SMSession

		INSERT dbo.SMSession (SMSessionID, SMCo, Prebilling)
		VALUES (@SMSessionID, @SMCo, @Prebilling)
	COMMIT TRAN
END
GO
GRANT EXECUTE ON  [dbo].[vspSMSessionCreate] TO [public]
GO
