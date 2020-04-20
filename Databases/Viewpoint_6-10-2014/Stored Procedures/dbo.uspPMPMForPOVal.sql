SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 1/27/2014
-- Description:	Validation for PO Firm Contact 'Ordered By'
-- =============================================
CREATE PROCEDURE [dbo].[uspPMPMForPOVal] 
	-- Add the parameters for the stored procedure here
	@Company bCompany = 0, 
	@Contact bEmployee = 0
	,@ReturnMessage VARCHAR(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @rcode TINYINT = 0
	
    -- Insert statements for procedure here

	IF NOT EXISTS(SELECT TOP 1 1 FROM PMPM p 
			WHERE FirmNumber = (SELECT TOP 1 OurFirm FROM PMCO WHERE PMCo = @Company)
				AND ContactCode = @Contact)
	BEGIN
		SELECT @ReturnMessage = 'Not a valid PM Firm Contact for Company '+@Company+'.', @rcode = 1
		GOTO uspexit
	END
	ELSE
	BEGIN
		SELECT @ReturnMessage = FullContactName , @rcode = 0
			FROM PMPM1 
			WHERE ContactCode = @Contact AND FirmNumber = (SELECT TOP 1 OurFirm FROM PMCO WHERE PMCo = @Company)
		GOTO uspexit
	END

	uspexit:
	RETURN @rcode

END
GO
