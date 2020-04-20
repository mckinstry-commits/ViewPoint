SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		CC
-- Create date: 4/18/08
-- Description:	Procedure to retrieve default new checklist status
-- =============================================
CREATE PROCEDURE [dbo].[vspWFGetChecklistStatus] 
	-- Add the parameters for the stored procedure here
	@status VARCHAR(2000) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT @status = [Description] FROM WFStatusCodes WHERE IsChecklistStatus = 'Y' AND StatusType = 0

END

GO
GRANT EXECUTE ON  [dbo].[vspWFGetChecklistStatus] TO [public]
GO
