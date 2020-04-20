SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		HH
-- Create date: 11/1/2012
-- Description:	Add initial record for WDJBTableLayout if not existing
-- =============================================
CREATE PROCEDURE [dbo].[vspWDJBTableInitialize] 
	-- Add the parameters for the stored procedure here
	@JobName VARCHAR(150) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF NOT EXISTS (SELECT TOP 1 1 FROM WDJBTableLayout WHERE JobName = @JobName)
		INSERT INTO WDJBTableLayout (JobName) VALUES (@JobName)
END
GO
GRANT EXECUTE ON  [dbo].[vspWDJBTableInitialize] TO [public]
GO
