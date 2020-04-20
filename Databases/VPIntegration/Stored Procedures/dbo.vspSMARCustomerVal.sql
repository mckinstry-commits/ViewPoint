SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jeremiah Barkley
-- Create date: 8/5/2011
-- Description:	Validation for the AR Customer (BillTo) on the work order.  This is essentially a wrapper around the bspARCustomerVal.
-- Modifications:  TRL 10/25/2011 TK-88966 Renamed @IsOnHoldYN parameter to @Status to return actual AR Custumer Status
-- =============================================
CREATE PROCEDURE [dbo].[vspSMARCustomerVal]
	@CustomerGroup tinyint,
	@Customer bSortName, 
   	@CustomerOutput bCustomer = NULL OUTPUT,
   	@Status char(1) = 'I' OUTPUT,
   	@msg varchar(255) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @rcode int 
	EXEC @rcode = dbo.bspARCustomerVal @CustomerGroup, @Customer, 'A', @CustomerOutput OUTPUT, @msg OUTPUT
	
	IF (@rcode = 0)
	BEGIN
		SELECT @Status = [Status] FROM dbo.ARCM WHERE CustGroup = @CustomerGroup AND Customer = @CustomerOutput
	END
	
	RETURN @rcode
END

GO
GRANT EXECUTE ON  [dbo].[vspSMARCustomerVal] TO [public]
GO
