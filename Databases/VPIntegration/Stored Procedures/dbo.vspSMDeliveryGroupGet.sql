SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jeremiah Barkley
-- Create date: 9/22/11
-- Description:	Get a usable delivery group.  This will create a delivery group.  
--				If a SMSessionID is passed in, it will find an existing delivery group
--				for the SMSessionID or create a new one.
-- Modified:	
-- =============================================

CREATE PROCEDURE [dbo].[vspSMDeliveryGroupGet]
	@SMSessionID AS int = NULL,
	@SMDeliveryGroupID AS int OUTPUT, 
	@msg AS varchar(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	IF (@SMSessionID IS NOT NULL)
	BEGIN
		-- Find the DeliveryGroupID for the SMSessionID
		SELECT @SMDeliveryGroupID = SMDeliveryGroupID FROM dbo.SMDeliveryGroup WHERE SMSessionID = @SMSessionID 
		
		IF (@SMDeliveryGroupID IS NOT NULL) RETURN 0
	END
	
	-- At this point 
	-- Create a new DeliveryGroup
	INSERT INTO dbo.SMDeliveryGroup (SMSessionID) VALUES (@SMSessionID)
	SELECT @SMDeliveryGroupID = SCOPE_IDENTITY()
	
	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspSMDeliveryGroupGet] TO [public]
GO
