SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 1/12/12
-- Description:	Creates a Generic Entity record and returns the SMGenericEntityID
-- =============================================
CREATE PROCEDURE [dbo].[vspSMGenericEntityCreate]
	@SMCo bCompany, @CustGroup bGroup = NULL, @Customer bCustomer = NULL, @ServiceSite varchar(20) = NULL, @RateTemplate varchar(10) = NULL, @EffectiveDate bDate = NULL,
	@CreateRateOverrideBaseRate bit = 0,
	@SMGenericEntityID bigint = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @Type tinyint
	
	SET @Type = CASE WHEN @RateTemplate IS NOT NULL THEN 1 WHEN @Customer IS NOT NULL THEN 2 WHEN @ServiceSite IS NOT NULL THEN 3 END

	INSERT dbo.SMGenericEntity ([Type], SMCo, CustGroup, Customer, ServiceSite, RateTemplate, EffectiveDate)
	VALUES (@Type, @SMCo, @CustGroup, @Customer, @ServiceSite, @RateTemplate, @EffectiveDate)

	SET @SMGenericEntityID = SCOPE_IDENTITY()
	
	IF @SMGenericEntityID IS NULL
	BEGIN
		RETURN 1
	END
	
	IF @CreateRateOverrideBaseRate = 1
	BEGIN
		INSERT dbo.SMRateOverrideBaseRate (SMRateOverrideID)
		VALUES (@SMGenericEntityID)
	END
	
	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspSMGenericEntityCreate] TO [public]
GO
