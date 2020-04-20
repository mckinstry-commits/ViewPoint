USE Viewpoint
GO

If EXISTS ( Select * From INFORMATION_SCHEMA.ROUTINES Where ROUTINE_NAME='MCKspSetDelivered' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='PROCEDURE' )
Begin
	Print 'DROP PROCEDURE dbo.MCKspSetDelivered'
	DROP PROCEDURE dbo.MCKspSetDelivered
End
GO

Print 'CREATE PROCEDURE dbo.MCKspSetDelivered'
GO


CREATE Procedure [dbo].MCKspSetDelivered
(
  @SMCo				bCompany
, @BillToCustomer bCustomer
, @InvoiceNumber	varchar(10)
--, @WorkOrder		int
)
AS
 /* 
	Purpose:			Set Delivered Date to mark SM Invoice as Delivered
	Created:			9.18.2018
	Author:			Leo Gurdian

	09.18.2018 LG - Init concept.
*/
 	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
Begin

/* TEST */

Begin Try

	Declare @errmsg varchar(800) = ''

/*  TEST
Declare @BillToCustomer bCustomer = 245204
Declare @InvoiceNumber	varchar(10)	= '  10053241'
Declare @WorkOrder		int  = 9523973
*/

	--UPDATE SMInvoiceList 
	--Set DeliveredDate  = GETDATE()
	----Select 
	----		Customer					 
	----	, InvoiceNumber 
	----	, WorkOrder 
	----	, DeliveredDate
	----From  SMInvoiceList
	--Where SMCo = @SMCo
	--		AND Customer = @BillToCustomer 
	--		AND (RTRIM(LTRIM(ISNULL(InvoiceNumber,'')))) = (RTRIM(LTRIM(ISNULL(@InvoiceNumber,''))))

	UPDATE upd 
	Set upd.DeliveredDate  = GETDATE()
	FROM SMInvoiceList upd
	INNER JOIN (
			Select 
				  i.SMCo
				, i.Customer					 
				, i.InvoiceNumber 
				--, w.WorkOrder 
				, i.DeliveredDate
			From SMInvoice i
					INNER JOIN SMCustomer c ON
								c.SMCo = i.SMCo
						AND c.Customer = @BillToCustomer
						AND c.CustGroup = i.CustGroup
					INNER JOIN SMWorkOrder w ON
								i.SMCo = w.SMCo
						AND i.CustGroup = w.CustGroup
						AND w.Customer = @BillToCustomer
			Where c.Active = 'Y'
					AND i.Customer = @BillToCustomer 
					AND (RTRIM(LTRIM(ISNULL(i.InvoiceNumber,'')))) = (RTRIM(LTRIM(ISNULL(@InvoiceNumber,''))))
					--AND w.WorkOrder = @WorkOrder
			) x
			ON upd.SMCo = x.SMCo
				AND upd.Customer = x.Customer
				AND upd.InvoiceNumber = x.InvoiceNumber

End try

Begin Catch
	Set @errmsg =  ERROR_PROCEDURE() + ', ' + N'Line:' + cast(ERROR_LINE() as varchar) + ' | ' + ERROR_MESSAGE();
	Goto i_exit
End Catch

i_exit:
	SET NOCOUNT OFF;

	if (@errmsg != '')
		Begin
		 RAISERROR(@errmsg, 11, -1);
		End
	
	Select 1 -- success
End

GO


Grant EXECUTE ON dbo.MCKspSetDelivered TO [MCKINSTRY\Viewpoint Users]

GO
/*

exec dbo.MCKspSetDelivered 200000,'  10053196'

*/


