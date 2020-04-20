SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[mckspPONotification]
(
	@Co TINYINT = 101
	,@Po varchar(30) = null
	,@To	varchar(100) = 'erptest@mckinstry.com'
	,@rcode TINYINT = 0
	,@ReturnMessage VARCHAR(255) OUTPUT
)
AS

DECLARE @Approved CHAR(1) 
SET @Approved = (SELECT Approved FROM POHD WHERE @Co=POCo AND @Po=PO)

IF EXISTS (SELECT 1 
				FROM POHDPM poh INNER JOIN PMMF m ON m.POCo = poh.POCo AND m.PO = poh.PO
				WHERE (poh.POCo = @Co AND poh.PO=@Po) AND poh.Approved='Y' AND m.InterfaceDate IS NULL AND m.SendFlag='Y' AND m.MaterialOption='P')
BEGIN

	DECLARE @subject NVARCHAR(100)

	SELECT @subject = N'Approved Purchase Order'
	SELECT @subject = COALESCE(@subject + N' : ' + @Po,@subject + N's')

	DECLARE @tableHTML  NVARCHAR(MAX) 

	SET @tableHTML =
		N'<H3>' + @subject + N'</H3>' +
		N'<font size="-2">' +
		N'<table border="1">' +
		N'<tr bgcolor=silver>' +
		N'<th>Co</th>' +
		N'<th>PO</th>' +
		N'<th>Description</th>' +
		N'<th>Vendor</th>' +
		N'<th>VendorName</th>' +
		N'<th>Job</th>' +
		N'<th>JobName</th>' +
		N'<th>POS tatus</th>' +
		N'<th>Order Date</th>' +
		N'<th>Value</th>' +
		N'<th>Approved</th>' +
		N'<th>Approved By</th>' +
		 N'</tr>' +
		CAST 
		( 
			( 
				SELECT
					td = COALESCE(poh.JCCo,' '), ''
				,	td = COALESCE(poh.PO,' '), ''
				,	td = COALESCE(poh.Description,' '), ''
				,	td = COALESCE(poh.Vendor,' '), ''
				,	td = COALESCE(v.Name,' '), '' AS VendorName
				,	td = COALESCE(poh.Job,' '), ''
				,	td = COALESCE(j.Description,' '), '' AS JobName
				,	td = COALESCE(CASE poh.Status
						WHEN 0 THEN N'Open'
						WHEN 1 THEN N'Complete'
						WHEN 2 THEN N'Closed'
						WHEN 3 THEN N'Pending'
						ELSE N'Unknown'
					END,' '), '' AS POStatus
				,	td = COALESCE(CONVERT(VARCHAR(10),poh.OrderDate,101),' '), ''
				,	td = COALESCE(CASE
						WHEN (pot.POTotal + 	pot.POTotalTax) > 0 THEN (pot.POTotal + 	pot.POTotalTax)
						ELSE (pot.PMPOAmt + pot.PMPOAmtTax)
					END,' '), '' AS POValue
				,	td = COALESCE(poh.Approved,' '), ''
				,	td = COALESCE(poh.ApprovedBy,' '), ''
				FROM 
					POHDPM poh LEFT JOIN
					JCJM j ON 
						poh.JCCo=j.JCCo
					AND	poh.Job=j.Job LEFT JOIN
					APVM v ON
						poh.Vendor=v.Vendor JOIN
					dbo.PMPOTotal pot ON
						poh.POCo=pot.POCo
					AND poh.PO=pot.PO
				WHERE
					poh.Approved='Y'
				AND	((poh.POCo = @Co AND poh.PO=@Po) OR @Po IS NULL)
				ORDER BY 2	
				FOR XML PATH('tr'), TYPE 
			) AS NVARCHAR(MAX) ) + N'</table>' + N'<br/><br/>'

	SELECT  @tableHTML=@tableHTML+N'<i>PO Value is calculated as  the total of either Interfaced Items + Tax or Non-Interfaced Items + Tax</i></font>'
		
	EXEC msdb.dbo.sp_send_dbmail 
		@profile_name = 'Viewpoint',
		@recipients = @To,
		@subject = @subject,
		@body = @tableHTML,
		@body_format = 'HTML' 
	
	SELECT @ReturnMessage='Request sent to Purchasing Department', @rcode=0
	GOTO spexit
END
ELSE
BEGIN
	IF @Approved = 'N'
	BEGIN
	SELECT @ReturnMessage='No Purchase Order(s) with "RTE to Purch" checked. Request has not been sent', @rcode=1
	GOTO spexit
	END
	ELSE
	IF NOT EXISTS(SELECT 1 FROM PMMF m WHERE POCo=@Co AND PO = @Po AND m.InterfaceDate IS NULL AND m.SendFlag='Y' AND m.MaterialOption='P')
	BEGIN
		SELECT @ReturnMessage= 'No Items found. Please add items, save the record and try again.', @rcode=1
		GOTO spexit
	END
end	

spexit:
BEGIN
	RETURN @rcode
END	

GO
GRANT EXECUTE ON  [dbo].[mckspPONotification] TO [public]
GO
