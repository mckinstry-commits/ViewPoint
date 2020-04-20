SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Vaterlaus
-- Create date: 08/08/11
-- Description:	Load the last filter settings by SMCo and User for the multi-work order billing form.
-- =============================================
CREATE PROCEDURE dbo.vspSMBillingFilterLoad
	@SMCo tinyint,
	@UserName varchar(128),
	@DateTimeCreated datetime OUTPUT,
	@ServiceCenter varchar(10) OUTPUT,
	@Division varchar(10) OUTPUT,
	@Customer int OUTPUT,
	@BillTo int OUTPUT,
	@ServiceSite varchar(20) OUTPUT,
    @DateProvidedMin smalldatetime OUTPUT,
    @DateProvidedMax smalldatetime OUTPUT,
    @LineType tinyint OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT 
        @DateTimeCreated=DateTimeCreated, 
        @ServiceCenter=ServiceCenter,
        @Division=Division, 
        @Customer=Customer,
        @BillTo=BillTo,
        @ServiceSite=ServiceSite,
        @DateProvidedMin=DateProvidedMin,
        @DateProvidedMax=DateProvidedMax,
        @LineType=LineType
	FROM vSMBillingSessionFilter
	WHERE SMCo = @SMCo AND UserName = @UserName
		
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMBillingFilterLoad] TO [public]
GO
