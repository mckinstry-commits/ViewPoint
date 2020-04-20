USE Viewpoint
GO

If EXISTS ( Select * From INFORMATION_SCHEMA.ROUTINES Where ROUTINE_NAME='MCKspSMRecipients' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='PROCEDURE' )
Begin
	Print 'DROP PROCEDURE dbo.MCKspSMRecipients'
	DROP PROCEDURE dbo.MCKspSMRecipients
End
GO

Print 'CREATE PROCEDURE dbo.MCKspSMRecipients'
GO


CREATE PROCEDURE [dbo].[MCKspSMRecipients]
(
  @BillToCustomer bCustomer
, @InvoiceNumber VARCHAR(10)
)
AS
 /* 
	Purpose:	Gets non-delivered recipient data for the SM Invoice VSTO solution	
	Created:	8.23.2018
	Author:		Leo Gurdian

	12.11.2018 LG - Removed InvoiceStatus and PrintStatus params
	11.07.2018 LG - Phone number format
	11.06.2018 LG - Get Service Center and Division (1st scope) from the work order not the site record
	10.31.2018 LG - Added Address2 
	09.12.2018 LG - Send From (Mckinstry email) added
	08.27.2018 LG - ud fields added
	08.24.2018 LG - 'Bill To' fields are based on DeliveryTo: AR Customer or Service Site.
	08.23.2018 LG - init. concept.
*/
 	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

BEGIN

/* TEST */

---- INVOICED - DELIVERED,			DeliverTo: Service Site
--Declare @BillToCustomer bCustomer = 200000
--Declare @InvoiceNumber varchar(10) = '  10053188'
--Declare @InvoiceStatus char =  null -- 'I'
--Declare @PrintStatus	 char(1) = 'P'			/* <-- DELIVERED */ 

---- INVOICED - NOT DELIVERED,	DeliverTo: AR Customer
--Declare @BillToCustomer bCustomer = 245204
--Declare @InvoiceNumber varchar(10) = '  10053241'
--Declare @InvoiceStatus char = null -- 'I'
--Declare @PrintStatus	 char(1) = 'N'			/* <-- NOT DELIVERED */

--Declare @PrintStatus	 char(1) = NULL	/* <-- ALL - DELIVERED / NOT DELIVERED */
;

BEGIN TRY
	/*  TEST 


	Declare @BillToCustomer bCustomer = 21753
	Declare @InvoiceNumber	varchar(10)	= '  10053281'
	Declare @InvoiceStatus char =  'I'		-- 'I'
	Declare @PrintStatus	 char(1) = NULL -- 'N'			/* <-- NOT DELIVERED */

	Declare @BillToCustomer bCustomer = 211507
	Declare @InvoiceNumber	VARCHAR(10)	= '  10057408'
	Declare @PrintStatus   CHAR(1) = NULL -- 'N'			/* <-- NOT DELIVERED */
*/	
	DECLARE @errmsg VARCHAR(800) = ''

	/* to get @sendFrom email */
	Declare @workOrders		VARCHAR(max)
	Declare @workOrder		INT 
	Declare @serviceCenter	VARCHAR(60)
	Declare @division		VARCHAR(10)
	Declare @serviceSite	VARCHAR(20)
	Declare @sendFrom		VARCHAR(128)	-- Mckinstry email will vary per division / service center combo
	DECLARE @billingPhone	VARCHAR(15)

/* Get Service Site to join Service Center and Division to eventually get McKinstry's 'Send From' email */
Begin

	/* Get Work order from Invoice */
	Select @workOrders =  SMInvoiceWorkOrders.InvoiceWorkOrders
									From dbo.SMInvoiceListDetail D
											INNER JOIN dbo.SMCustomer C ON
													C.SMCo = D.SMCo
												AND C.Customer = @BillToCustomer
												AND C.CustGroup = D.CustGroup
											OUTER APPLY dbo.vfSMGetInvoiceWorkOrders (D.SMCo, D.SMInvoiceID, D.Invoice) SMInvoiceWorkOrders
									Where C.Active = 'Y' 
										AND (RTRIM(LTRIM(ISNULL(D.InvoiceNumber,'')))) = (RTRIM(LTRIM(ISNULL(@InvoiceNumber,''))))
	
	/* get the 1st WO on the list */									
	Set @workOrder = (CASE WHEN @workOrders LIKE '%,%' THEN CAST(SUBSTRING(@workOrders,0,CHARINDEX (',',@workOrders)) AS VARCHAR(15)) 
						ELSE CAST(@workOrders AS VARCHAR(15)) 
					  END)

	/* Get Service Site from Work Order */ -- for loop below only
	Select @serviceSite = (SELECT TOP(1) W.ServiceSite
								From dbo.SMInvoiceListDetail D 
								INNER JOIN dbo.SMWorkOrder W ON
											D.SMCo = W.SMCo
									AND W.Customer = D.Customer
									AND W.WorkOrder = D.WorkOrder
								Where  D.Customer = @BillToCustomer
										AND (RTRIM(LTRIM(ISNULL(D.InvoiceNumber,'')))) = (RTRIM(LTRIM(ISNULL(@InvoiceNumber,''))))
										AND W.WorkOrder = @workOrder
								Group by W.ServiceSite
							)

	/* Get Service Center from SMWorkOrder */
	Select @serviceCenter = (SELECT TOP(1) W.ServiceCenter
									From  dbo.SMWorkOrder W 
									Where W.WorkOrder = @workOrder
							)

	--Select @division = Division From SMDivision D Where ServiceCenter = @serviceCenter
	Select @division = (SELECT TOP (1) W.Division
							FROM  dbo.SMWorkOrderScope  W 
							WHERE ServiceCenter = @serviceCenter
								AND W.WorkOrder = @workOrder
								AND W.Scope = 1 -- per Esther; grab Division from 1st scope
						)

	Select @serviceCenter = Description from dbo.SMServiceCenter C where ServiceCenter = @serviceCenter

	Select @sendFrom = Email
								From dbo.udxrefSMFromEmail x
								Where		 UPPER(x.ServiceCenter) = UPPER(@serviceCenter)
										AND UPPER(x.Division)		= UPPER(@division)

	Select @billingPhone = x.PhoneNumber
								From dbo.udxrefSMFromEmail x
								Where		 UPPER(x.ServiceCenter) = UPPER(@serviceCenter)
										AND UPPER(x.Division)		= UPPER(@division)
	/* phone number format */
	IF (@billingPhone IS NOT NULL)
		SET @billingPhone = SUBSTRING(@billingPhone, 1, 3) + '-' + 
							SUBSTRING(@billingPhone, 4, 3) + '-' + 
							SUBSTRING(@billingPhone, 7, 4)
END

--Select @workOrders	 AS WorkOrders
--Select @workOrder	 AS WorkOrder
--Select @serviceSite	 AS ServiceSite
--Select @serviceCenter As ServiceCenter
--Select @division	 As Division
--Select @sendFrom	 AS SendFrom
--Select @billingPhone AS BillingPhone

IF OBJECT_ID('tempdb..#tmpdeliver') IS NOT NULL 
		DROP TABLE #tmpdeliver

SELECT DISTINCT
	'Y'								As Bill	
	, LTRIM(RTRIM(I.InvoiceNumber))	As [Invoice Number]
	, [Send From]	= @sendFrom
	, I.DeliveredDate				As [Sent Date]
	, (Select DisplayValue from DDCIShared where ComboType = 'udDelMethod' AND DatabaseValue = C.udDelMethod) As [Delivery Method]
	, CASE WHEN C.DeliveryTo = 'A' Then 'AR Customer'
		   WHEN C.DeliveryTo = 'S' Then 'Service Site'
		   ELSE 'Other'
		END							AS [Delivery To]
	, I.Customer					AS [Customer]
	, (SELECT TOP(1) C.Name FROM dbo.ARCM C WHERE C.Customer = @BillToCustomer) AS [Customer Name]
	, I.BillToARCustomer			AS [Bill To]
	, CAST('' AS VARCHAR(120))		AS [Bill Name] --site.Description
	, I.BillEmail					AS [Bill Email]
	, NULL							As [Bill CC Email]
	, CAST('' AS VARCHAR(60))		AS [Bill Address]
	, CAST('' AS VARCHAR(60))		AS [Bill Address2]
	, CAST('' AS VARCHAR(30))		AS [Bill City]
	, CAST('' AS VARCHAR(4))		AS [Bill State]
	, CAST('' AS VARCHAR(12))		AS [Bill Zip]
	, I.InvoiceSummaryLevel			As [Invoice Summary Level]
	, C.udReqWOwithBilling			As [Required WO With Billing]
	, C.udReqInspectionRptithBilling As [Require Inspection Report With Billing]
	, C.udSignOffReq				As [Sign Off Required]
	, C.udLienRelease				As [Lien Release]
	, C.udCertifiedPayroll			As [Certified Payroll]
	, I.SMCo						As [SMCo]
	, CASE WHEN I.InvoiceType = 'A' THEN 
			(
				Select top 1 smss.ServiceSite 
				From dbo.SMAgreementExtended x
					INNER JOIN dbo.SMCustomerInfo nfo ON 
								x.SMCo		= nfo.SMCo 
						AND x.CustGroup = nfo.CustGroup 
						AND x.Customer	= nfo.Customer 
					INNER JOIN dbo.SMInvoiceDetail dt ON
							dt.SMCo = I.SMCo
						AND dt.Invoice = I.Invoice
						AND dt.SMCo = I.SMCo
					LEFT OUTER JOIN dbo.SMAgreementService a ON 
							x.Agreement = a.Agreement 
						AND x.Revision	= a.Revision 
						AND x.SMCo		= a.SMCo
					INNER JOIN dbo.SMServiceSite smss ON 
									a.SMCo			= smss.SMCo 
								AND a.ServiceSite	= smss.ServiceSite 
					WHERE  x.SMCo  =  I.SMCo
					AND x.Customer  = I.BillToARCustomer
					AND x.RevisionStatus  =  2
					AND x.AgreementStatus  =  'A'
					AND x.Agreement  = dt.Agreement 
			)
			when I.InvoiceType = 'W' then 
			(
				Select @serviceSite
			)
		End as [Service Site]					 
	, @workOrders					AS [Work Orders]
	, @division						As [Division]
	, [Billing Phone]= @billingPhone 
	, I.CustGroup					As [Customer Group]
into #tmpdeliver
From dbo.SMInvoiceList I
		JOIN dbo.SMCustomer C ON
				 C.SMCo = I.SMCo
			AND C.Customer = I.BillToARCustomer
			AND C.CustGroup = I.CustGroup
Where C.Active = 'Y'
		AND I.Customer = @BillToCustomer
		AND (RTRIM(LTRIM(ISNULL(I.InvoiceNumber,'')))) = (RTRIM(LTRIM(ISNULL(@InvoiceNumber,''))))

CREATE NONCLUSTERED INDEX IX_Customer ON #tmpdeliver (Customer, [Invoice Number])

--Select * from #tmpdeliver

Declare @DeliveredDate			bDate
Declare @Bill					CHAR(1)
Declare @DeliveryMethod			varchar(20)
Declare @DeliveryTo				varchar(12)
DECLARE @Customer				bCustomer
DECLARE @CustomerName			VARCHAR(60)
DECLARE @BillTo					bCustomer
Declare @BillToName				varchar(120)
Declare @EMail					varchar(128)
Declare @CCBillEmail			varchar(128)
DECLARE @BillingPhone			VARCHAR(15)
Declare @Address1				varchar(60)
Declare @Address2				varchar(60)
Declare @City					varchar(30)
Declare @State					varchar(4)
Declare @Zip					bZip
Declare @InvoiceSummaryLevel	CHAR(1)
Declare @udReqWOwithBilling		CHAR(1)
Declare @udReqInspectionRptithBilling CHAR(1)
Declare @udSignOffReq			CHAR(1)
Declare @udLienRelease			CHAR(1)
Declare @udCertifiedPayroll		CHAR(1)
Declare @SMCo					bCompany
Declare @CustGroup				bGroup

DECLARE delivery_cursor  CURSOR LOCAL READ_ONLY FORWARD_ONLY
		Static 
		For 
		Select * from #tmpdeliver

/* Loop through recipients to set @DeliveryTo 'Service Site' or 'AR Customer' data */
BEGIN

	OPEN delivery_cursor

	FETCH NEXT FROM delivery_cursor Into @Bill, @InvoiceNumber, @sendFrom, @DeliveredDate, @DeliveryMethod, @DeliveryTo, @Customer, @CustomerName, @BillTo, @BillToName, @EMail, @CCBillEmail, @Address1, @Address2, @City, @State, @Zip, 
										 @InvoiceSummaryLevel, @udReqWOwithBilling, @udReqInspectionRptithBilling, @udSignOffReq, @udLienRelease, @udCertifiedPayroll, @SMCo, @serviceSite, @workOrders, @division, @BillingPhone, @CustGroup
	 WHILE (@@FETCH_STATUS <> -1)
		BEGIN
			BEGIN
				IF @DeliveryTo = 'AR Customer' 
				 	Begin
						Select 
						  @BillToName	= (SELECT TOP(1) C.BillName FROM dbo.SMInvoiceList C WHERE (RTRIM(LTRIM(ISNULL(InvoiceNumber,'')))) = (RTRIM(LTRIM(ISNULL(@InvoiceNumber,'')))))
						, @EMail	= ar.EMail
						, @Address1 = ar.BillAddress
						, @Address2 = ar.BillAddress2
						, @City		= ar.City
						, @State	= ar.State
						, @Zip		= ar.Zip
						From dbo.ARCM ar
								JOIN dbo.SMInvoiceList I ON
										 I.BillToARCustomer  = ar.Customer
									AND I.CustGroup = ar.CustGroup
						Where I.BillToARCustomer = @BillTo
								AND I.CustGroup = @CustGroup
								AND (RTRIM(LTRIM(ISNULL(I.InvoiceNumber,'')))) = (RTRIM(LTRIM(ISNULL(@InvoiceNumber,''))))
					End
				ELSE IF @DeliveryTo = 'Service Site'
				 	Begin
						Select 
						  @BillToName	= (SELECT TOP(1) C.BillName FROM dbo.SMInvoiceList C WHERE (RTRIM(LTRIM(ISNULL(InvoiceNumber,'')))) = (RTRIM(LTRIM(ISNULL(@InvoiceNumber,'')))))
						, @EMail	= SS.BillingEmail
						, @Address1 = SS.Address1
						, @Address2 = SS.Address2
						, @City		= SS.City
						, @State	= SS.State
						, @Zip		= SS.Zip
						From dbo.SMServiceSite SS 
						Where	SS.ServiceSite	= @serviceSite
					End
				ELSE IF @DeliveryTo = 'Other'
					BEGIN
						SELECT 
							  @BillToName	= C.BillingName
							, @EMail	= C.BillingEmail
							, @Address1 = C.BillingAddress1
							, @Address2 = C.BillingAddress2
							, @City		= C.BillingCity
							, @State	= C.BillingState
							, @Zip		= C.BillingPostalCode
							FROM dbo.SMCustomer C
							WHERE		 C.Customer = @BillTo
									AND C.CustGroup	= @CustGroup
					END

				UPDATE #tmpdeliver
						 SET  [Bill Name]		= @BillToName
							, [Bill Email]		= COALESCE(@EMail,[Bill Email])
							, [Bill Address]	= @Address1
							, [Bill Address2]	= @Address2
							, [Bill City]		= @City
							, [Bill State]		= @State
							, [Bill Zip]		= @Zip
				WHERE (RTRIM(LTRIM(ISNULL([Invoice Number],'')))) = (RTRIM(LTRIM(ISNULL(@InvoiceNumber,''))))
			END

		FETCH NEXT FROM delivery_cursor INTO @Bill, @InvoiceNumber, @sendFrom, @DeliveredDate, @DeliveryMethod, @DeliveryTo, @Customer, @CustomerName, @BillTo, @BillTo, @EMail, @CCBillEmail, @Address1, @Address2, @City, @State, @Zip, 
											 @InvoiceSummaryLevel, @udReqWOwithBilling, @udReqInspectionRptithBilling, @udSignOffReq, @udLienRelease, @udCertifiedPayroll, @SMCo, @serviceSite, @workOrders, @division, @BillingPhone, @CustGroup
		END

	CLOSE delivery_cursor
	DEALLOCATE delivery_cursor

END

SELECT * FROM #tmpdeliver
	
END TRY

	BEGIN CATCH
		SET @errmsg =  ERROR_PROCEDURE() + ', ' + N'Line:' + CAST(ERROR_LINE() AS VARCHAR(8000)) + ' | ' + ERROR_MESSAGE();
		GOTO i_exit
	END CATCH

i_exit:

IF OBJECT_ID('tempdb..#tmpdeliver') IS NOT NULL 
		DROP TABLE #tmpdeliver

	IF (@errmsg <> '')
		BEGIN
		 RAISERROR(@errmsg, 11, -1);
		END
END


GO

Grant EXECUTE ON dbo.MCKspSMRecipients TO [MCKINSTRY\Viewpoint Users]

GO
/*

PROJECT:

exec dbo.MCKspSMRecipients 200000,'  10053200', null, null

exec dbo.MCKspSMRecipients 200000,'  10053196'

exec dbo.MCKspSMRecipients 207669,'  10053194', 'I', 'P'

exec dbo.MCKspSMRecipients 216685,'  10053250', 'P', null

exec dbo.MCKspSMRecipients 247706,'  10053260', 'I', null

exec dbo.MCKspSMRecipients 213409,'  2209517', 'I', null

exec dbo.MCKspSMRecipients 239483,'  2038917', 'I', null - PROJECT

exec dbo.MCKspSMRecipients 243814,'  10057368', 'I', null

exec dbo.MCKspSMRecipients 219564,'  10053442', 'I', null

exec dbo.MCKspSMRecipients 211507,'  10057408', 'I', null

exec dbo.MCKspSMRecipients 216082,'10061146'


PROD  

exec dbo.MCKspSMRecipients 218943,'  10060790'

exec dbo.MCKspSMRecipients 211507 ,'  10057408', null, null

*/


