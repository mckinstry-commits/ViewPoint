SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  proc [dbo].[vspPOPendingPurchaseOrderVal]
/*************************************
 * Created By:		GP 4/3/12 - TK-13774
 * Modified By:
 *
 * Validates the PO field on the PO Pending Purchase Order form.
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



--Check POUnique view (POHD, POHB) for existing PO record
if exists(select 1 from dbo.POUnique where POCo = @POCo and PO = @PO and Source in ('bPOHD','bPOHB'))
begin
	select @msg = 'PO already exists in PO Entry.'
	return 1
end

--Get Pending PO description
select @msg = [Description] from dbo.vPOPendingPurchaseOrder where POCo = @POCo and PO = @PO



--Return 0 if successful
return 0

GO
GRANT EXECUTE ON  [dbo].[vspPOPendingPurchaseOrderVal] TO [public]
GO
