USE Viewpoint
GO

If EXISTS ( Select * From INFORMATION_SCHEMA.ROUTINES Where ROUTINE_NAME='McKspSMInvoiceDeliverySearch' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='PROCEDURE' )
	Begin
		Print 'DROP PROCEDURE dbo.McKspSMInvoiceDeliverySearch'
		DROP PROCEDURE dbo.McKspSMInvoiceDeliverySearch
	End
GO

Print 'CREATE PROCEDURE dbo.McKspSMInvoiceDeliverySearch'
GO

CREATE PROCEDURE [dbo].[McKspSMInvoiceDeliverySearch](
  @SMCo					bCompany
, @InvoiceStatus		char(1) = NULL
, @PrintStatus			char(1) = NULL 
, @BillToCustomer		bCustomer = NULL
, @InvoiceStart			VARCHAR(10) = NULL
, @InvoiceEnd			varchar(10) = NULL
, @InvoiceList			McKtyInvoiceList READONLY
, @Division				varchar(10) = NULL
, @ServiceCenter		varchar(10) = NULL
)
AS
 /* 
	Purpose:	Get SM invoice header information				
	Created:	01.12.2018
	Author:		Leo Gurdian

	HISTORY:
	12.17.2018 LG - rename columns: Printed By > Sent By
									Date Sent  > Sent Date
*/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET NOCOUNT ON;

BEGIN

	Declare @errmsg varchar(8000) = ''

	-- re-declares for optimization per Ben Wilson
	Declare @smco				bCompany	= @SMCo
	Declare @invoiceStatus		CHAR(1)		= @InvoiceStatus
	Declare @printStatus		CHAR(1)		= @PrintStatus
	Declare @billToCustomer		bCustomer	= @BillToCustomer
	Declare @invoiceStart		varchar(10)	= @InvoiceStart
	Declare @invoiceEnd			varchar(10)	= @InvoiceEnd
	Declare @division			varchar(10) = @Division
	Declare @serviceCenter		varchar(20) = @ServiceCenter

	--Declare @WorkOrder			INT
	--Declare @ServiceSite		varchar(20)
	--DECLARE @InvoiceList		McKtyInvoiceList 

Begin Try

	If (Select TOP (1) 1 From @InvoiceList) > 0

		Begin
		 --set @errmsg = (select top 1 InvoiceNumber From @InvoiceList)
		 --RAISERROR(@errmsg, 11, -1);

			SELECT DISTINCT
					Case when IL.InvoiceType = 'A' then 'Agreement' 
							when IL.InvoiceType = 'W' then 'Work Order' 
					End AS [Invoice Type]
				, IL.SMCo
				, dbo.Trim(IL.InvoiceNumber)			AS [Invoice Number]
				, IL.InvoiceDate						AS [Invoice Date]
				, A.Agreement							AS [Agreement]
				, SMInvoiceWorkOrders.InvoiceWorkOrders AS [Work Orders]
				, IL.Customer							AS [Customer]
				, (SELECT TOP(1) C.Name FROM dbo.SMCustomerInfo C WHERE C.Customer = IL.Customer ) AS [Customer Name]
				, IL.BillToARCustomer			AS [Bill To]
				, NFO.Name						AS [Bill To Name]
				, IL.DeliveredDate				AS [Sent Date]
				, IL.DeliveredBy				AS [Sent By]
				, IL.TotalAmount				As [Invoice Amt]
				, ARTH.Paid						AS [Total Paid]
				, IL.VoidDate					AS [Void Date]
				, IL.VoidedBy					AS [Voided By]
				, IL.SMInvoiceID				As [SMInvoiceID]
				, Case when IL.InvoiceType = 'A' then 
						(
							Select top (1) smss.ServiceSite 
							From dbo.SMAgreementExtended x
								INNER JOIN dbo.SMCustomerInfo NFO ON 
											x.SMCo		= NFO.SMCo 
									AND x.CustGroup = NFO.CustGroup 
									AND x.Customer	= NFO.Customer 
								LEFT OUTER JOIN dbo.SMAgreementService smas ON 
										x.Agreement = smas.Agreement 
									AND x.Revision	= smas.Revision 
									AND x.SMCo		= smas.SMCo
								INNER JOIN dbo.SMServiceSite smss ON 
												smas.SMCo			= smss.SMCo 
											AND smas.ServiceSite	= smss.ServiceSite 
								WHERE   x.SMCo  =  @smco
									AND x.Customer  = IL.BillToARCustomer
									AND x.RevisionStatus  =  2
									AND x.AgreementStatus  =  'A'
									AND x.Agreement  = D.Agreement 
						)
						when IL.InvoiceType = 'W' then 
						(
							WO.ServiceSite
						)
					End as [Service Site]
			FROM dbo.SMInvoice I
					INNER JOIN dbo.SMInvoiceDetail D       
						ON I.SMCo = D.SMCo
								AND I.Invoice = D.Invoice
					INNER JOIN dbo.SMInvoiceList IL on
							D.SMCo = IL.SMCo
						AND D.Invoice = IL.Invoice
					INNER JOIN dbo.SMInvoiceLine L
						ON I.SMCo = L.SMCo
								AND I.Invoice = L.Invoice
								AND L.InvoiceDetail = D.InvoiceDetail 
								AND L.Invoice IS NOT NULL 
					INNER JOIN dbo.SMWorkOrderScope S
						ON I.SMCo = S.SMCo
								AND D.WorkOrder = S.WorkOrder
								AND ISNULL(D.Scope,1) = S.Scope  
								--AND S.Agreement IS NULL
					INNER JOIN	dbo.SMWorkOrder WO
						ON WO.SMCo = S.SMCo
								AND WO.WorkOrder = S.WorkOrder
					INNER JOIN @InvoiceList ii  ON 
							LTRIM(RTRIM(I.InvoiceNumber)) = LTRIM(RTRIM(ii.InvoiceNumber)) -- Get these Invoices
					LEFT OUTER JOIN dbo.SMWorkCompleted WC 
						ON	WC.WorkOrder	 = D.WorkOrder
							AND WC.WorkCompleted = D.WorkCompleted
					LEFT JOIN dbo.SMCustomerInfo NFO  ON 
								I.SMCo = NFO.SMCo
							AND I.CustGroup		= NFO.CustGroup
							AND I.BillToARCustomer	= NFO.Customer
					LEFT JOIN dbo.SMInvoiceSession  ON 
							I.SMInvoiceID = SMInvoiceSession.SMInvoiceID
					LEFT JOIN dbo.ARTH ON IL.ARCo	= ARTH.ARCo 
							AND IL.ARPostedMth		= ARTH.Mth 
							AND IL.ARTrans			= ARTH.ARTrans
					LEFT JOIN dbo.SMAgreementExtended A  ON
								A.SMCo = I.SMCo
							AND A.CustGroup = I.CustGroup
							AND A.Customer = I.BillToARCustomer
							AND A.AgreementStatus = 'A'
							AND A.RevisionStatus = 2
							AND A.Agreement = D.Agreement
					OUTER APPLY dbo.vfSMGetInvoiceWorkOrders (IL.SMCo, IL.SMInvoiceID, IL.Invoice) SMInvoiceWorkOrders
			WHERE IL.SMCo = @smco
				AND NFO.Active = 'Y'
				AND (IL.Prebilling = 0 OR IL.Prebilling IS NULL)
				AND IL.InvoiceStatus = CASE WHEN @invoiceStatus = 'I' THEN 'Invoiced'
										   WHEN @invoiceStatus = 'P' THEN 'Pending Invoice'
										   WHEN @invoiceStatus = 'V' THEN 'Voided'
										END
				AND
				(
					(@printStatus IS NULL) OR
					(@printStatus = 'N' AND IL.DeliveredDate IS NULL) OR
					(@printStatus = 'P' AND IL.DeliveredDate IS NOT NULL) 
				) 
				AND
				(
					(@billToCustomer IS NULL) OR
					(IL.BillToARCustomer = @billToCustomer)
				)
				AND
				(
					(@division IS NULL) OR
					(S.Division = @division )
				)
				AND
				(
					(@serviceCenter IS NULL) OR
					(WO.ServiceCenter = @serviceCenter)
				)
				AND
				(
					(IL.InvoiceType = 'A' AND A.Agreement IS NOT NULL)

					OR

					(IL.InvoiceType = 'W' AND A.Agreement IS NULL) -- ONLY SHOW BILLABLE WOs
				)
		Order by 1 desc, 3

		END

		ELSE 

		Begin
				SELECT DISTINCT
					Case when IL.InvoiceType = 'A' then 'Agreement' 
						 WHEN IL.InvoiceType = 'W' then 'Work Order' 
					End									AS [Invoice Type]
				, IL.SMCo
				, dbo.Trim(IL.InvoiceNumber)						AS [Invoice Number]
				, IL.InvoiceDate						AS [Invoice Date]
				, A.Agreement							AS [Agreement]
				, SMInvoiceWorkOrders.InvoiceWorkOrders AS [Work Orders]
				, IL.Customer							AS [Customer]
				, (SELECT TOP(1) C.Name FROM dbo.SMCustomerInfo C WHERE C.Customer = IL.Customer ) AS [Customer Name]
				, IL.BillToARCustomer			AS [Bill To]
				, NFO.Name						AS [Bill To Name]
				, IL.DeliveredDate				AS [Sent Date]
				, IL.DeliveredBy				AS [Sent By]
				, IL.TotalAmount				As [Invoice Amt]
				, ARTH.Paid						AS [Total Paid]
				, IL.VoidDate					AS [Void Date]
				, IL.VoidedBy					AS [Voided By]
				, IL.SMInvoiceID				As [SMInvoiceID]
				, Case when IL.InvoiceType = 'A' then 
						(
							Select top (1) smss.ServiceSite 
							From dbo.SMAgreementExtended x
								INNER JOIN dbo.SMCustomerInfo NFO ON 
											x.SMCo		= NFO.SMCo 
									AND x.CustGroup = NFO.CustGroup 
									AND x.Customer	= NFO.Customer 
								LEFT OUTER JOIN dbo.SMAgreementService smas ON 
										x.Agreement = smas.Agreement 
									AND x.Revision	= smas.Revision 
									AND x.SMCo		= smas.SMCo
								INNER JOIN dbo.SMServiceSite smss ON 
												smas.SMCo			= smss.SMCo 
											AND smas.ServiceSite	= smss.ServiceSite 
								WHERE   x.SMCo  =  @smco
									AND x.Customer  = IL.BillToARCustomer
									AND x.RevisionStatus  =  2
									AND x.AgreementStatus  =  'A'
									AND x.Agreement  = D.Agreement 
						)
						when IL.InvoiceType = 'W' then 
						(
							WO.ServiceSite
						)
					End as [Service Site]
			FROM dbo.SMInvoice I
					INNER JOIN dbo.SMInvoiceDetail D       
						ON I.SMCo = D.SMCo
								AND I.Invoice = D.Invoice
					INNER JOIN dbo.SMInvoiceList IL on
							D.SMCo = IL.SMCo
						AND D.Invoice = IL.Invoice
					INNER JOIN dbo.SMInvoiceLine L
						ON I.SMCo = L.SMCo
								AND I.Invoice = L.Invoice
								AND L.InvoiceDetail = D.InvoiceDetail 
								AND L.Invoice IS NOT NULL 
					LEFT JOIN dbo.SMWorkOrderScope S
						ON I.SMCo = S.SMCo
								AND D.WorkOrder = S.WorkOrder
								AND ISNULL(D.Scope,1) = S.Scope  
								--AND S.Agreement IS NULL
					LEFT JOIN	dbo.SMWorkOrder WO
						ON WO.SMCo = S.SMCo
								AND WO.WorkOrder = S.WorkOrder
					LEFT OUTER JOIN dbo.SMWorkCompleted WC 
						ON	WC.WorkOrder	 = D.WorkOrder
							AND WC.WorkCompleted = D.WorkCompleted
					LEFT JOIN dbo.SMCustomerInfo NFO 
						ON 	I.SMCo = NFO.SMCo
							AND I.CustGroup		= NFO.CustGroup
							AND I.BillToARCustomer	= NFO.Customer
					LEFT JOIN dbo.SMInvoiceSession 
						ON 	I.SMInvoiceID = SMInvoiceSession.SMInvoiceID
					LEFT JOIN dbo.ARTH 
						ON		IL.ARCo	= ARTH.ARCo 
							AND IL.ARPostedMth		= ARTH.Mth 
							AND IL.ARTrans			= ARTH.ARTrans
					LEFT JOIN dbo.SMAgreementExtended A 
						ON		A.SMCo = I.SMCo
							AND A.CustGroup = I.CustGroup
							AND A.Customer = I.BillToARCustomer
							AND A.AgreementStatus = 'A'
							AND A.RevisionStatus = 2
							AND A.Agreement = D.Agreement
					OUTER APPLY dbo.vfSMGetInvoiceWorkOrders (IL.SMCo, IL.SMInvoiceID, IL.Invoice) SMInvoiceWorkOrders
			WHERE I.SMCo = @smco 
				AND NFO.Active = 'Y'
				AND (IL.Prebilling = 0 OR IL.Prebilling IS NULL)
				AND IL.InvoiceStatus = CASE WHEN @invoiceStatus  = 'I' THEN 'Invoiced'
										   WHEN @invoiceStatus  = 'P' THEN 'Pending Invoice'
										   WHEN @invoiceStatus  = 'V' THEN 'Voided'
									   END
				AND
				(
					(@printStatus  IS NULL) OR
					(@printStatus  = 'N' AND I.DeliveredDate IS NULL) OR
					(@printStatus  = 'P' AND I.DeliveredDate IS NOT NULL)
				) 
				AND
				(
					@billToCustomer IS NULL OR
					(I.BillToARCustomer = @billToCustomer)
				)
				AND
				(
					@invoiceStart  IS NULL OR
					(RTRIM(LTRIM(ISNULL(I.InvoiceNumber,' '))) >= RTRIM(LTRIM(ISNULL(@invoiceStart , ' '))))
				) 
				AND
				(
					@invoiceEnd  IS NULL OR
					(RTRIM(LTRIM(ISNULL(I.InvoiceNumber,' '))) <= RTRIM(LTRIM(ISNULL(@invoiceEnd  ,RTRIM(LTRIM(ISNULL( @invoiceStart , ' ')))))))
				) 
				AND
				(
					(@division IS NULL) OR
					(S.Division = @division COLLATE SQL_Latin1_General_CP1_CI_AS) -- case insensitive
				)
				AND
				(
					(@serviceCenter IS NULL) OR
					(WO.ServiceCenter = @serviceCenter)
				)
				AND
				(
					(I.InvoiceType = 'A' AND A.Agreement IS NOT NULL)
					OR
					(I.InvoiceType = 'W' AND A.Agreement IS NULL) -- ONLY SHOW BILLABLE WOs
				)
		Order by 1 desc, 3
		End
End try

Begin Catch
	Set @errmsg =  ERROR_PROCEDURE() + ', ' + N'Line:' + CAST(ERROR_LINE() as VARCHAR(800)) + ' | ' + ERROR_MESSAGE();
	Goto i_exit
End Catch

i_exit:

	if (@errmsg <> '')
		Begin
		 RAISERROR(@errmsg, 11, -1)
		End
End

GO

Grant EXECUTE ON dbo.McKspSMInvoiceDeliverySearch TO [MCKINSTRY\Viewpoint Users]

GO


/* TEST 


Declare @invoiceList As McKtyInvoiceList

exec McKspSMInvoiceDeliverySearch
  @SMCo					= 1
, @InvoiceStatus	   = 'I'
, @PrintStatus			= 'N'
, @BillToCustomer		= NULL
, @InvoiceStart			= NULL -- '10059703' --10057262
, @InvoiceEnd			= NULL --'10059712' --10057262
, @InvoiceList			= @invoiceList
, @Division				= NULL -- 'PLUMBING'
, @ServiceCenter		= NULL -- 101


*/

--sp_help McKtyInvoiceList
