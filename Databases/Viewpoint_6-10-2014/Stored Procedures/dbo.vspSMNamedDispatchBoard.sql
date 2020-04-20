SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Paul Wiegardt
-- Create date: 4/18/2013
-- Description:	SM Named Dispatch Boards
--
-- Modified by: GPT Task-53548 Insert 'All' board on first access for @SMCo.
-- =============================================
CREATE PROCEDURE [dbo].[vspSMNamedDispatchBoard]
	@SMCo bCompany = NULL,
	@msg nvarchar OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	-- Insert default "All" board on first access of the Dispatch form for a given @SMCo 
	IF NOT EXISTS (SELECT 1 FROM dbo.SMNamedDispatchBoard WHERE SMCo = @SMCo AND SMBoardName = 'All')
	BEGIN
		INSERT INTO SMNamedDispatchBoard (SMCo, SMBoardName)
		VALUES (@SMCo,'All')
	END

	SELECT	SMBoardName
	FROM dbo.SMNamedDispatchBoard
	WHERE SMCo = @SMCo

	IF @@rowcount = 0
	BEGIN
		SET @msg = 'No SM Named Dispatch Boards are available.'
		RETURN 1
	END
	
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMNamedDispatchBoard] TO [public]
GO
