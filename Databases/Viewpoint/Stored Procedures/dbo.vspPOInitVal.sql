SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE  proc [dbo].[vspPOInitVal]
/*************************************
 * Created By:		GP 4/9/12 - TK-13774
 * Modified By:
 *
 * Validates the PO field to ensure that it 
 * doesn't exist in the Pending Purchase Order form.
 *
 * Pass:
 * @POCo - PO Company
 * @PO - Purchase Order
 *
 * Returns:
 * 0 - Success
 * 1 - Failure
 * @msg - Error Message
 **************************************/
(@POCo bCompany, @PO varchar(30), @msg varchar(255) output)
as
set nocount on



--Check POUnique view (POPendingPurchaseOrder) for existing PO record
if exists(select 1 from dbo.POUnique where POCo = @POCo and PO = @PO and Source = 'vPOPendingPurchaseOrder')
begin
	select @msg = 'PO already exists in PO Pending Purchase Order.'
	return 1
end


--Return 0 if successful
return 0



GO
GRANT EXECUTE ON  [dbo].[vspPOInitVal] TO [public]
GO
