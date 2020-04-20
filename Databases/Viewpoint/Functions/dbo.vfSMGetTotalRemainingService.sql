SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		David Solheim
-- Create date: 3/9/12
-- Description:	Determines the amount of money remaining to be billed
--				for a given service
-- =============================================
CREATE FUNCTION [dbo].[vfSMGetTotalRemainingService]
(
	@SMCo bCompany,
	@Agreement varchar(15),
	@Service int,
	@Revision int	
)
RETURNS @TotalRemainingTable TABLE
	(
		TotalRemaining bDollar NULL
	)
AS
BEGIN
	DECLARE @RowsTotal bDollar
	DECLARE @TotalRemaining bDollar
	DECLARE @Price bDollar

	SELECT @Price = PricingPrice from SMAgreementService 
	where SMCo = @SMCo 
	AND [Service] = @Service 
	AND Revision = @Revision 
	AND Agreement = @Agreement

	SELECT @RowsTotal = SUM(BillingAmount) from SMAgreementBillingSchedule
	where SMCo = @SMCo 
	AND [Service] = @Service 
	AND Revision = @Revision 
	AND Agreement = @Agreement
	
	SET @TotalRemaining = @Price - ISNULL(@RowsTotal, 0)
	
	INSERT INTO @TotalRemainingTable VALUES (@TotalRemaining)
	
	RETURN

END

GO
GRANT SELECT ON  [dbo].[vfSMGetTotalRemainingService] TO [public]
GO
