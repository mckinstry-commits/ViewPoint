SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/**********************************************************/
CREATE procedure [dbo].[vspSMRecordRelationGetForDisplay]
/************************************************************************
* Created By:	JG 09/01/2011 
* MODIFIED By:	JG 09/12/2011 - TK-08335 - Added Service Site Invoices
*				JG 09/19/2011 - TK-08567-9 -  Added Customer to SM Work Center along with actions. 
*				JG 09/20/2011 - TK-08470 - Commented out the POs for Service Site.
*				JG 09/20/2011 - TK-08570 - Added Customer related records.
*				JG 09/21/2011 - TK-00000 - POs > 29 numbers are converted to 29 numbers
*				JG 09/21/2011 - TK-08617 - Added status to Work Order POs
*				GF 10/06/2011 - TK-08927 - changed KeyID to indentity column id where view changed
*				JG 10/18/2011 - TK-09219 - created the displayed related records for SMWorkOrderScope
*				JG 10/18/2011 - TK-09219 - created the displayed related records for SMTrip
*				JG 10/24/2011 - TK-00000 - added filter for the displayed related rocords for SMWorkOrderScope
*				JG 10/24/2011 - TK-00000 - fixed an error with SMWorkOrderScopes launching
*
* Purpose of Stored Procedure
* RETURN A RESULT SET TO USE IN THE RELATED RECORDS PANEL THAT IS 
* AVAILABLE IN THE PM DOCUMENT FORMS WHERE RELATING RECORDS IS ALLOWED.
*    
* 
* Inputs
* @FromKeyID		- KeyID of Related Document
* @FromFormName		- name of calling form
*
* Outputs
* @rcode		- 0 = successfull - 1 = error
* @errmsg		- Error Message
*
*************************************************************************/

(@Co bCompany = NULL, @FromKeyID bigint = NULL, @FromFormName NVARCHAR(128) = NULL,
 @msg varchar(255) output)

--with execute as 'viewpointcs'

AS
SET NOCOUNT ON

DECLARE @rcode	int, @APCo	int, @INCo	INT, @SQL NVARCHAR(2000),
		@FromFormTable NVARCHAR(128), @RecCount INT

SET @rcode = 0
SET @RecCount = 0

-------------------------------
-- CHECK INCOMING PARAMETERS --	
-------------------------------
IF @FromKeyID IS NULL
	BEGIN
		SET @msg = 'Missing From Form Record ID!'
		SET @rcode = 1
		GOTO vspExit
	END

---- need a from form name
IF ISNULL(@FromFormName,'') = ''
	BEGIN
	SELECT @msg = 'Missing From Form Name parameter!', @rcode = 1
	GOTO vspExit
	END

---- execute SP to get the from form table
EXEC @rcode = dbo.vspPMRecordRelationGetFormTable @FromFormName, @FromFormTable output, @msg output

---- must have a form name
IF @FromFormTable IS NULL
	BEGIN
	SELECT @msg = 'Missing From Form Table for related records!', @rcode = 1
	GOTO vspExit
	END
	


---- CREATE TEMP TABLE TO HOLD RELATED RECORDS
DECLARE @related_records TABLE
(
	RecType			NVARCHAR(60),
	KeyID			BIGINT,
	LinkID			BIGINT,
	FormKeyID		BIGINT,
	Detail			NCHAR(1),
	DocType			NVARCHAR(60),
	DocID			NVARCHAR(60),
	RecDate			NVARCHAR(30),
	RecDesc			NVARCHAR(100),
	SortID			NVARCHAR(60),
	Title			NVARCHAR(60)
)


IF @FromFormTable = 'SMCustomer'
BEGIN
	-- Related Service Sites
	INSERT INTO @related_records (
		RecType,
		KeyID,
		LinkID,
		FormKeyID,
		Detail,
		DocType,
		DocID,
		RecDate,
		RecDesc,
		SortID
	) 
	SELECT 'SMServiceSite' AS RecType,
		dbo.vfToString(@FromKeyID) AS KeyID,
		dbo.vfToString(SMServiceSiteID) AS LinkID,
		dbo.vfToString(SMServiceSiteID) AS FormKeyID,
		'N' AS Detail,
		'NotSure' AS DocType,
		ServiceSite AS DocID,
		NULL AS RecDate,
		CASE 
			WHEN [Description] IS NOT NULL THEN 
				CONVERT(VARCHAR(100),[Description])
			ELSE
				'No Description'
			END AS RecDesc,
		ServiceSite AS SortID
	FROM dbo.SMServiceSite
	WHERE SMCo = @Co
	AND EXISTS
			(
				SELECT 1 
				FROM dbo.SMCustomer 
				WHERE SMCustomerID = @FromKeyID 
				AND CustGroup = SMServiceSite.CustGroup 
				AND Customer = SMServiceSite.Customer
			)
	ORDER BY ServiceSite
	
	
	-- Related Service Items
	INSERT INTO @related_records (
		RecType,
		KeyID,
		LinkID,
		FormKeyID,
		Detail,
		DocType,
		DocID,
		RecDate,
		RecDesc,
		SortID
	) 
	SELECT 'SMServiceItems' AS RecType,
		dbo.vfToString(@FromKeyID) AS KeyID,
		dbo.vfToString(i.SMServiceItemID) AS LinkID,
		dbo.vfToString(i.SMServiceItemID) AS FormKeyID,
		'N' AS Detail,
		'NotSure' AS DocType,
		ServiceItem + ' - Site: ' + s.ServiceSite AS DocID,
		NULL AS RecDate,
		CONVERT(VARCHAR(100),i.[Description]) AS RecDesc,
		i.ServiceItem
	FROM dbo.SMServiceItems i
		JOIN SMServiceSite s
		ON s.SMCo = i.SMCo
		AND s.ServiceSite = i.ServiceSite
	WHERE i.SMCo = @Co
	AND EXISTS
			(
				SELECT 1 
				FROM dbo.SMCustomer 
				WHERE SMServiceItemID = @FromKeyID 
				AND CustGroup = s.CustGroup 
				AND Customer = s.Customer
			)
	ORDER BY i.ServiceItem
	
	
	-- Related Work Orders
	INSERT INTO @related_records (
		RecType,
		KeyID,
		LinkID,
		FormKeyID,
		Detail,
		DocType,
		DocID,
		RecDate,
		RecDesc,
		SortID
	) 
	SELECT 'SMWorkOrder' AS RecType,
		dbo.vfToString(@FromKeyID) AS KeyID,
		dbo.vfToString(o.SMWorkOrderID) AS LinkID,
		dbo.vfToString(o.SMWorkOrderID) AS FormKeyID,
		'N' AS Detail,
		'NotSure' AS DocType,
		CONVERT(VARCHAR, o.WorkOrder) + ' - Site: ' + o.ServiceSite AS DocID,
		dbo.vfDateOnlyAsStringUsingStyle(RequestedDate, @Co, DEFAULT) AS RecDate,
		CASE 
			WHEN o.[Description] IS NOT NULL THEN 
				CONVERT(VARCHAR(100), o.[Description])
			ELSE
				'No Description'
			END AS RecDesc,
		o.WorkOrder AS SortID
	FROM dbo.SMWorkOrder o
		JOIN SMServiceSite s
		ON s.SMCo = o.SMCo
		AND s.ServiceSite = o.ServiceSite
	WHERE o.SMCo = @Co
	AND EXISTS
			(
				SELECT 1 
				FROM dbo.SMCustomer 
				WHERE SMCustomerID = @FromKeyID 
				AND CustGroup = s.CustGroup 
				AND Customer = s.Customer
			)
	ORDER BY WorkOrder
	
	
	-- Related Trips
	INSERT INTO @related_records (
		RecType,
		KeyID,
		LinkID,
		FormKeyID,
		Detail,
		DocType,
		DocID,
		RecDate,
		RecDesc,
		SortID,
		Title
	) 
	SELECT DISTINCT 'SMTrip' AS RecType,
		dbo.vfToString(@FromKeyID) AS KeyID,
		dbo.vfToString(t.SMTripID) AS LinkID,
		dbo.vfToString(t.SMTripID) AS FormKeyID,
		'N' AS Detail,
		'NotSure' AS DocType,
		'WO: ' + CONVERT(VARCHAR, t.WorkOrder) + ' - Site: ' + s.ServiceSite AS DocID,
		dbo.vfDateOnlyAsStringUsingStyle(RequestedDate, CONVERT(VARCHAR(3),@Co) , DEFAULT) AS RecDate,
		CONVERT(VARCHAR(100), NewDesc) AS RecDesc,
		t.WorkOrder AS SortID,
		'Open Trips' AS Title
	FROM SMTripOpen t
		JOIN dbo.SMWorkOrder o
		ON t.SMCo = o.SMCo
		AND t.WorkOrder = o.WorkOrder
		JOIN SMServiceSite s
		ON s.SMCo = t.SMCo
		AND s.ServiceSite = o.ServiceSite
	WHERE t.SMCo = @Co
	AND EXISTS
			(
				SELECT 1 
				FROM dbo.SMCustomer 
				WHERE SMCustomerID = @FromKeyID 
				AND CustGroup = s.CustGroup 
				AND Customer = s.Customer
			)
	ORDER BY t.WorkOrder
	
	
	--Related Invoices
	INSERT INTO @related_records (
		RecType,
		KeyID,
		LinkID,
		FormKeyID,
		Detail,
		DocType,
		DocID,
		RecDate,
		RecDesc,
		SortID,
		Title
	) 

	SELECT 'SMCustomer' AS RecType,
		SMCustomer.SMCustomerID AS KeyID,
		SMCustomer.SMCustomerID AS LinkID,
		SMCustomer.SMCustomerID AS FormKeyID,
		'N' AS Detail,
		'NotSure' AS DocType,
		SMInvoiceList.Invoice AS DocID,
		dbo.vfDateOnlyAsStringUsingStyle(SMInvoiceList.InvoiceDate, @Co, DEFAULT) AS RecDate,
		'$' + dbo.vfToString(TotalAmount) + ' - ' +
		 dbo.vfDateOnlyAsStringUsingStyle(SMInvoiceList.InvoiceDate, @Co, DEFAULT) + ' - ' +
		SMInvoiceList.InvoiceStatus RecDesc,
		SMInvoiceList.Invoice AS SortID,
		'Invoices' AS Title
	FROM dbo.SMCustomer
		INNER JOIN dbo.SMInvoiceList ON SMInvoiceList.SMCo = SMCustomer.SMCo AND SMInvoiceList.CustGroup = SMCustomer.CustGroup AND SMInvoiceList.Customer = SMCustomer.Customer
	WHERE SMCustomer.SMCustomerID = @FromKeyID
	ORDER BY SMInvoiceList.Invoice
	
	
END
ELSE IF @FromFormName = 'SMServiceSite'
BEGIN
	-- Related Work Orders
	INSERT INTO @related_records (
		RecType,
		KeyID,
		LinkID,
		FormKeyID,
		Detail,
		DocType,
		DocID,
		RecDate,
		RecDesc,
		SortID
	) 
	SELECT 'SMWorkOrder' AS RecType,
		dbo.vfToString(@FromKeyID) AS KeyID,
		dbo.vfToString(SMWorkOrderID) AS LinkID,
		dbo.vfToString(SMWorkOrderID) AS FormKeyID,
		'N' AS Detail,
		'NotSure' AS DocType,
		WorkOrder AS DocID,
		dbo.vfDateOnlyAsStringUsingStyle(RequestedDate, @Co, DEFAULT) AS RecDate,
		CASE 
			WHEN [Description] IS NOT NULL THEN 
				CONVERT(VARCHAR(100),[Description])
			ELSE
				'No Description'
			END AS RecDesc,
		WorkOrder AS SortID
	FROM dbo.SMWorkOrder
	WHERE SMCo = @Co
	AND dbo.SMWorkOrder.ServiceSite = (SELECT ServiceSite FROM SMServiceSite WHERE SMServiceSiteID = @FromKeyID)
	ORDER BY WorkOrder


	-- Related Trips
	INSERT INTO @related_records (
		RecType,
		KeyID,
		LinkID,
		FormKeyID,
		Detail,
		DocType,
		DocID,
		RecDate,
		RecDesc,
		SortID,
		Title
	) 
	SELECT DISTINCT 'SMTrip' AS RecType,
		dbo.vfToString(@FromKeyID) AS KeyID,
		dbo.vfToString(t.SMTripID) AS LinkID,
		dbo.vfToString(t.SMTripID) AS FormKeyID,
		'N' AS Detail,
		'NotSure' AS DocType,
		'WO: ' + CONVERT(VARCHAR, t.WorkOrder) AS DocID,
		dbo.vfDateOnlyAsStringUsingStyle(RequestedDate, CONVERT(VARCHAR(3),@Co) , DEFAULT) AS RecDate,
		--'Work Order - ' + CONVERT(VARCHAR, t.Trip) AS RecDesc,
		CONVERT(VARCHAR(100), NewDesc) AS RecDesc,
		t.WorkOrder AS SortID,
		'Open Trips' AS Title
	FROM SMTripOpen t
		JOIN dbo.SMWorkOrder o
		ON t.SMCo = o.SMCo
		AND t.WorkOrder = o.WorkOrder
	WHERE t.SMCo = @Co
	AND o.ServiceSite = (SELECT ServiceSite FROM SMServiceSite WHERE SMServiceSiteID = @FromKeyID)
	ORDER BY t.WorkOrder
	
	
	-- Related Service Items
	INSERT INTO @related_records (
		RecType,
		KeyID,
		LinkID,
		FormKeyID,
		Detail,
		DocType,
		DocID,
		RecDate,
		RecDesc,
		SortID
	) 
	SELECT 'SMServiceItems' AS RecType,
		dbo.vfToString(@FromKeyID) AS KeyID,
		dbo.vfToString(SMServiceItemID) AS LinkID,
		dbo.vfToString(SMServiceItemID) AS FormKeyID,
		'N' AS Detail,
		'NotSure' AS DocType,
		ServiceItem AS DocID,
		--dbo.vfDateOnlyAsStringUsingStyle(RequestedDate, @Co, DEFAULT) AS RecDate,
		NULL AS RecDate,
		CONVERT(VARCHAR(100),[Description]) AS RecDesc,
		ServiceItem
	FROM dbo.SMServiceItems i
	WHERE SMCo = @Co
	AND i.ServiceSite = (SELECT ServiceSite FROM SMServiceSite WHERE SMServiceSiteID = @FromKeyID)
	ORDER BY ServiceItem
	

	--Related Invoices
	INSERT INTO @related_records (
		RecType,
		KeyID,
		LinkID,
		FormKeyID,
		Detail,
		DocType,
		DocID,
		RecDate,
		RecDesc,
		SortID,
		Title
	) 

	SELECT 'SMServiceSite' AS RecType,
		SMServiceSite.SMServiceSiteID AS KeyID,
		SMServiceSite.SMServiceSiteID AS LinkID,
		SMServiceSite.SMServiceSiteID AS FormKeyID,
		'N' AS Detail,
		'NotSure' AS DocType,
		SMInvoiceList.Invoice AS DocID,
		dbo.vfDateOnlyAsStringUsingStyle(SMInvoiceList.InvoiceDate, @Co, DEFAULT) AS RecDate,
		'$' + dbo.vfToString(TotalAmount) + ' - ' +
		 dbo.vfDateOnlyAsStringUsingStyle(SMInvoiceList.InvoiceDate, @Co, DEFAULT) + ' - ' +
		SMInvoiceList.InvoiceStatus RecDesc,
		SMInvoiceList.Invoice AS SortID,
		'Invoices' AS Title
	FROM dbo.SMServiceSite
		CROSS APPLY dbo.vfSMGetServiceSiteInvoices(SMServiceSite.SMCo, SMServiceSite.ServiceSite) RelatedInvoices
		INNER JOIN dbo.SMInvoiceList ON RelatedInvoices.SMInvoiceID = SMInvoiceList.SMInvoiceID
	WHERE SMServiceSite.SMServiceSiteID = @FromKeyID
	ORDER BY SMInvoiceList.Invoice
	
	
	----Related POs
	--INSERT INTO @related_records (
	--	RecType,
	--	KeyID,
	--	LinkID,
	--	FormKeyID,
	--	Detail,
	--	DocType,
	--	DocID,
	--	RecDate,
	--	RecDesc,
	--	SortID,
	--	Title
	--) 

	--SELECT DISTINCT 'SMWorkOrder' AS RecType,
	--	CONVERT(NVARCHAR(30),@FromKeyID) AS KeyID,
	--	CONVERT(NVARCHAR(30), wo.KeyID) AS LinkID,
	--	CONVERT(NVARCHAR(30), wo.KeyID) AS FormKeyID,
	--	'N' AS Detail,
	--	'NotSure' AS DocType,
	--	RTRIM(list.PO) + ' - WO: ' + CONVERT(VARCHAR, wo.WorkOrder) AS DocID,
	--	dbo.vfDateOnlyAsStringUsingStyle(list.OrderDate, CONVERT(VARCHAR(3),@Co), DEFAULT) AS RecDate,
	--	dbo.vfDateOnlyAsStringUsingStyle(list.OrderDate, CONVERT(VARCHAR(3),@Co), DEFAULT) AS RecDesc,
	--	CONVERT(VARCHAR(29), RTRIM(list.PO)) AS SortID,
	--	'Purchase Orders' AS Title
	--FROM dbo.SMPurchaseOrderList list
	--	JOIN SMWorkOrder wo
	--	ON wo.SMCo = list.SMCo
	--	AND wo.WorkOrder = list.WorkOrder
	--WHERE list.SMCo = @Co
	--AND wo.ServiceSite = (SELECT ServiceSite FROM SMServiceSite WHERE KeyID = @FromKeyID)
	--AND ServiceSite = (SELECT ServiceSite FROM SMServiceSite WHERE KeyID = @FromKeyID)
	
END
ELSE IF @FromFormName = 'SMWorkOrder' OR @FromFormName = 'SMWorkOrderScope'
BEGIN
	IF @FromFormName = 'SMWorkOrderScope'
	BEGIN
		DECLARE @scopeID BIGINT
		SELECT @scopeID = @FromKeyID
		
		SELECT @FromKeyID = SMWorkOrderID
		FROM dbo.SMWorkOrderScope S
			LEFT JOIN SMWorkOrder O
			ON S.SMCo = O.SMCo
		AND S.WorkOrder = O.WorkOrder
		WHERE SMWorkOrderScopeID = @scopeID
	END


	-- Related Trips
	INSERT INTO @related_records (
		RecType,
		KeyID,
		LinkID,
		FormKeyID,
		Detail,
		DocType,
		DocID,
		RecDate,
		RecDesc,
		SortID,
		Title
	) 
	SELECT DISTINCT 'SMTrip' AS RecType,
		dbo.vfToString(@FromKeyID) AS KeyID,
		dbo.vfToString(t.SMTripID) AS LinkID,
		dbo.vfToString(t.SMTripID) AS FormKeyID,
		'N' AS Detail,
		'NotSure' AS DocType,
		t.Trip AS DocID,
		dbo.vfDateOnlyAsStringUsingStyle(ScheduledDate, CONVERT(VARCHAR(3),@Co) , DEFAULT) AS RecDate,
		CONVERT(VARCHAR(100), NewDesc) AS RecDesc,
		t.Trip AS SortID,
		'Open Trips' AS Title
	FROM SMTripOpen t
	WHERE t.SMCo = @Co
	AND t.WorkOrder = (SELECT WorkOrder FROM SMWorkOrder WHERE SMWorkOrderID = @FromKeyID)
	ORDER BY t.Trip
	
	
	-- Related Scopes
	INSERT INTO @related_records (
		RecType,
		KeyID,
		LinkID,
		FormKeyID,
		Detail,
		DocType,
		DocID,
		RecDate,
		RecDesc,
		SortID,
		Title
	) 
	SELECT DISTINCT 'SMWorkOrderScope' AS RecType,
		dbo.vfToString(@FromKeyID) AS KeyID,
		dbo.vfToString(SMWorkOrderScopeID) AS LinkID,
		dbo.vfToString(SMWorkOrderScopeID) AS FormKeyID,
		'N' AS Detail,
		'NotSure' AS DocType,
		Scope AS DocID,
		NULL AS RecDate,
		CONVERT(VARCHAR(100), WorkScope + ' - ' + [Description]) AS RecDesc,
		Scope AS SortID,
		'Work Order Scopes'
	FROM SMWorkOrderScope
	WHERE SMCo = @Co 
	AND WorkOrder = (SELECT WorkOrder FROM SMWorkOrder WHERE SMWorkOrderID = @FromKeyID)
	AND (@FromFormName <> 'SMWorkOrderScope' OR SMWorkOrderScopeID <> @scopeID)
	ORDER BY Scope
	
	--Related Invoices
	INSERT INTO @related_records (
		RecType,
		KeyID,
		LinkID,
		FormKeyID,
		Detail,
		DocType,
		DocID,
		RecDate,
		RecDesc,
		SortID,
		Title
	) 

	SELECT 'SMWorkOrder' AS RecType,
		SMWorkOrder.SMWorkOrderID AS KeyID,
		SMWorkOrder.SMWorkOrderID AS LinkID,
		SMWorkOrder.SMWorkOrderID AS FormKeyID,
		'N' AS Detail,
		'NotSure' AS DocType,
		SMInvoiceList.Invoice AS DocID,
		dbo.vfDateOnlyAsStringUsingStyle(SMInvoiceList.InvoiceDate, @Co, DEFAULT) AS RecDate,
		'$' + dbo.vfToString(TotalAmount) + ' - ' +
		 dbo.vfDateOnlyAsStringUsingStyle(SMInvoiceList.InvoiceDate, @Co, DEFAULT) + ' - ' +
		SMInvoiceList.InvoiceStatus RecDesc,
		SMInvoiceList.Invoice AS SortID,
		'Invoices' AS Title
	FROM SMWorkOrder
		CROSS APPLY dbo.vfSMGetWorkOrderInvoices(SMWorkOrder.SMCo, SMWorkOrder.WorkOrder) RelatedInvoice
		INNER JOIN SMInvoiceList ON RelatedInvoice.SMInvoiceID = SMInvoiceList.SMInvoiceID
	WHERE SMWorkOrder.SMWorkOrderID = @FromKeyID
	ORDER BY SMInvoiceList.Invoice
	
	--Related POs
	INSERT INTO @related_records (
		RecType,
		KeyID,
		LinkID,
		FormKeyID,
		Detail,
		DocType,
		DocID,
		RecDate,
		RecDesc,
		SortID,
		Title
	) 

	SELECT DISTINCT 'SMWorkOrder' AS RecType,
		CONVERT(NVARCHAR(30), @FromKeyID) AS KeyID,
		CONVERT(NVARCHAR(30), @FromKeyID) AS LinkID,
		CONVERT(NVARCHAR(30), @FromKeyID) AS FormKeyID,
		'N' AS Detail,
		'NotSure' AS DocType,
		RTRIM(list.PO) AS DocID,
		NULL AS RecDate,
		dbo.vfDateOnlyAsStringUsingStyle(list.OrderDate, CONVERT(VARCHAR(3),@Co), DEFAULT) 
		+ ' - ' 
		+ CASE 
			WHEN POHD.KeyID IS NULL 
				THEN 'Reserved' 
			ELSE 
				SUBSTRING(DDCI.DisplayValue , 5, 10)
			END AS RecDesc,
		CASE WHEN ISNUMERIC(list.PO) = 1 THEN CONVERT(VARCHAR(29), RTRIM(list.PO)) ELSE RTRIM(list.PO) END AS SortID,
		'Purchase Orders' AS Title
	FROM dbo.SMPurchaseOrderList list
		LEFT JOIN dbo.DDCI 
		ON DDCI.ComboType='POEntryStatus' 
		AND list.[Status] = DDCI.DatabaseValue
		LEFT JOIN dbo.POHD 
		ON list.POCo = POHD.POCo 
		AND list.PO = POHD.PO
	WHERE list.SMCo = @Co
	AND WorkOrder = (SELECT WorkOrder FROM SMWorkOrder WHERE SMWorkOrderID = @FromKeyID)
END
ELSE IF @FromFormName = 'SMTrip'
BEGIN

	-- Related Trips
	INSERT INTO @related_records (
		RecType,
		KeyID,
		LinkID,
		FormKeyID,
		Detail,
		DocType,
		DocID,
		RecDate,
		RecDesc,
		SortID,
		Title
	) 
	SELECT DISTINCT 'SMTrip' AS RecType,
		dbo.vfToString(@FromKeyID) AS KeyID,
		dbo.vfToString(t.SMTripID) AS LinkID,
		dbo.vfToString(t.SMTripID) AS FormKeyID,
		'N' AS Detail,
		'NotSure' AS DocType,
		t.Trip AS DocID,
		dbo.vfDateOnlyAsStringUsingStyle(ScheduledDate, CONVERT(VARCHAR(3),@Co) , DEFAULT) AS RecDate,
		CONVERT(VARCHAR(100),
		ISNULL(ti.FullName, 'Unassigned') 
		+ ' - '
		+ ISNULL(CONVERT(VARCHAR(11), t.ScheduledDate), 'Unscheduled')
		+ CASE
			WHEN t.[Description] IS NOT NULL THEN ' - ' 
			ELSE '' END 
		+ ISNULL(t.[Description], '')) AS RecDesc,
		t.Trip AS SortID,
		'Trips' AS Title
	FROM SMTrip t
	LEFT JOIN dbo.SMTechnicianInfo ti
	ON ti.SMCo = t.SMCo
	AND ti.Technician = t.Technician
	WHERE t.SMCo = @Co
	AND t.WorkOrder = (SELECT WorkOrder FROM SMTrip WHERE SMTripID = @FromKeyID)
	AND SMTripID <> @FromKeyID
	ORDER BY t.Trip
END


---- RETURN RESULTS
---- FORM HEADINGS: Record Type	KeyID	LinkID	FormKeyID	Detail	Doc Type	Doc ID	Date	Description	DDFH.Title
SELECT a.RecType AS [Record Type], a.KeyID AS [KeyID], a.LinkID AS [LinkID], a.FormKeyID AS [FormKeyID],
		a.Detail AS [Detail], a.DocType AS [Doc Type], a.DocID AS [Doc ID], a.RecDate AS [Date], a.RecDesc AS [Description],
		ISNULL(a.Title, b.Title) AS [Title]
		, CASE WHEN ISNUMERIC(a.SortID) = 1 THEN CONVERT(NUMERIC(29, 0), a.SortID) END AS [Value]
FROM @related_records a
LEFT JOIN dbo.DDFHShared b ON b.Form=a.RecType
ORDER BY a.Title, [Value]


vspExit:
	RETURN @rcode
	
	
	

GO
GRANT EXECUTE ON  [dbo].[vspSMRecordRelationGetForDisplay] TO [public]
GO
