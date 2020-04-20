SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Eric Vaterlaus
-- Create date: 7/27/11
-- Description:	Creates a SMStandardItemDefault record and returns the SMStandardItemDefaultID
-- Modified:    
-- =============================================
CREATE PROCEDURE [dbo].[vspSMStandardItemDefaultCreate]
	@Type tinyint, --This value represents what table needs the rate override. 1 = rate template, 2 = customer, 3 = service site
	@SMStandardItemDefaultID bigint = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	INSERT dbo.SMStandardItemDefault ([Type])
	VALUES (@Type)

	SET @SMStandardItemDefaultID = SCOPE_IDENTITY()
	
	IF @SMStandardItemDefaultID IS NULL RETURN 1
		
	RETURN 0
END




GO
GRANT EXECUTE ON  [dbo].[vspSMStandardItemDefaultCreate] TO [public]
GO
