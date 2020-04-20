SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 1/12/12
-- Description:	Creates a Generic Entity record and returns the SMGenericEntityID
-- Mod: DKS 3/26/2013 Added default value for OverrideBase insert which can no longer be null
--		JVH 4/10/13 Modified to support the other entities that need to be added.
--		SKA 05/06/2013 removed final insert statement, replaced with a proc call 
-- =============================================
CREATE PROCEDURE [dbo].[vspSMEntityCreate]
	@SMEntityType int, @SMCo bCompany,
	@CustGroup bGroup = NULL, @Customer bCustomer = NULL,
	@ServiceSite varchar(20) = NULL,
	@RateTemplate varchar(10) = NULL, @EffectiveDate bDate = NULL,
	@StandardItem varchar(20) = NULL,
	@WorkOrder int = NULL, @WorkOrderScope int = NULL,
	@Agreement varchar(15) = NULL, @AgreementRevision int = NULL, @AgreementService int = NULL,
	@WorkOrderQuote varchar(15) = NULL, @WorkOrderQuoteScope int = NULL,
	@EntitySeq int = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SET @EntitySeq = ISNULL((SELECT MAX(EntitySeq)FROM dbo.SMEntity WHERE SMCo = @SMCo), 0) + 1

	INSERT dbo.SMEntity (SMCo, EntitySeq, [Type], CustGroup, Customer, ServiceSite, RateTemplate, EffectiveDate, StandardItem, WorkOrder, WorkOrderScope, Agreement, AgreementRevision, AgreementService, WorkOrderQuote, WorkOrderQuoteScope)
	VALUES (@SMCo, @EntitySeq, @SMEntityType, @CustGroup, @Customer, @ServiceSite, @RateTemplate, @EffectiveDate, @StandardItem, @WorkOrder, @WorkOrderScope, @Agreement, @AgreementRevision, @AgreementService, @WorkOrderQuote, @WorkOrderQuoteScope)

	IF @SMEntityType IN (1,2,11)
	BEGIN
		EXEC dbo.vspSMRateOverrideEntityCreate @SMCo, @EntitySeq, 'N'
	END
	
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMEntityCreate] TO [public]
GO
