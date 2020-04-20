SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Vaterlaus
-- Create date: 08/08/11
-- Description:	Keep track of the last filter settings by SMCo and User for the multi-work order billing form.
-- =============================================
CREATE PROCEDURE dbo.vspSMBillingFilterSave 
	@SMCo tinyint, @UserName varchar(128), @ServiceCenter varchar(10),
	@Division varchar(10), @Customer int, @BillTo int, @ServiceSite varchar(20),
    @DateProvidedMin smalldatetime, @DateProvidedMax smalldatetime,
    @LineType tinyint, @msg varchar(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @rcode int

	BEGIN TRY
		DELETE vSMBillingSessionFilter WHERE SMCo=@SMCo and UserName=@UserName          

		INSERT INTO vSMBillingSessionFilter
           ([SMCo], [UserName], [ServiceCenter], [Division],
           [Customer], [BillTo], [ServiceSite],
           [DateProvidedMin], [DateProvidedMax], [LineType], [DateTimeCreated])
		VALUES
           (@SMCo, @UserName, @ServiceCenter, @Division, 
           @Customer, @BillTo, @ServiceSite,
           @DateProvidedMin, @DateProvidedMax, @LineType, GetDate())
	END TRY
	
	BEGIN CATCH
		SELECT @msg = ERROR_MESSAGE()
		SET @rcode = 1
	END CATCH
	
	RETURN @rcode
END
GO
GRANT EXECUTE ON  [dbo].[vspSMBillingFilterSave] TO [public]
GO
