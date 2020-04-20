SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
--		Author:	Lane Gresham
-- Create Date: 08/18/11
-- Description:	SM Invoice Number Validation
--	  Modified:
-- =============================================
CREATE PROCEDURE [dbo].[vspSMInvoiceNumber]
	@SMCo AS bCompany, @Invoice AS varchar(10), @msg AS varchar(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	IF @SMCo IS NULL
	BEGIN
		SET @msg = 'Missing SM Company!'
		RETURN 1
	END
	
	IF @Invoice IS NULL
	BEGIN
		SET @msg = 'Missing Invoice!'
		RETURN 1
	END
	
	IF EXISTS(SELECT 1 
			 FROM dbo.SMInvoiceSession 
			 WHERE SMCo = @SMCo AND Invoice = @Invoice)
    BEGIN
		SET @msg = 'Invoice ' + convert(varchar,@Invoice) + ' already exists in SM - record will not be saved'
		RETURN 1
    END
	
	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspSMInvoiceNumber] TO [public]
GO
