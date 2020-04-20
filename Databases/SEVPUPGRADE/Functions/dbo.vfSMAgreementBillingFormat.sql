SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Lane Gresham
-- Create date: 04-17-12
-- Description:	Formants a description for the SM Agreements Invoice Review form.
-- =============================================
CREATE FUNCTION [dbo].[vfSMAgreementBillingFormat]
(
	-- Add the parameters for the function here
	@Agreement varchar(15),
	@Service int,
	@Date bDate
)
RETURNS varchar(240)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @ResultVar varchar(240)
	
	SET @ResultVar = 'Agreement ' + dbo.vfToString(@Agreement) + CASE WHEN @Service IS NOT NULL THEN ' Service ' + dbo.vfToString(@Service) ELSE '' END + ' for ' + dbo.vfToString(CONVERT(VARCHAR(8), @Date, 1))
	
	-- Return the result of the function
	RETURN @ResultVar

END
GO
GRANT EXECUTE ON  [dbo].[vfSMAgreementBillingFormat] TO [public]
GO
