SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 12/30/2013
-- Description:	JB Billing Interface Notifier
-- =============================================
CREATE PROCEDURE [dbo].[mckspJBInterfaceRequest] 
	-- Add the parameters for the stored procedure here
	@JBCo TINYINT = 0, 
	@BillMonth bDate = 0,
	@BillNumber INT = 0
	, @To VARCHAR(255) = 'erptest@mckinstry.com'
	, @rcode INT =0
	, @ReturnMessage VARCHAR(255) = '' OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF EXISTS(SELECT 1 FROM JBIN WHERE @JBCo = JBCo AND @BillMonth = BillMonth AND @BillNumber = BillNumber)
	BEGIN
		DECLARE @subject NVARCHAR(100), @SumBillAmount bDollar, @SumBillToDateAmount bDollar

		SELECT @subject = 'JB Interface Request'
		SELECT @subject = COALESCE(@subject + ': ' + CONVERT(VARCHAR(3),@JBCo) +' - '+ REPLACE(RIGHT(CONVERT(VARCHAR(11), @BillMonth, 106), 8), ' ', '-') +' - Bill Number: '+ CONVERT(VARCHAR(30),@BillNumber), @subject)
		SELECT @SumBillAmount = SUM(AmtBilled), @SumBillToDateAmount = SUM(ToDateAmt) FROM JBITProgGrid WHERE @JBCo = JBCo AND @BillMonth = BillMonth AND @BillNumber = BillNumber

		DECLARE @tableHTML NVARCHAR(MAX)
		SET @tableHTML =
			N'<H3>' + @subject + '</H3>' +
			N'<font size="-2">' +
			N'<table border="1">' +
			N'<tr bgcolor=silver>' +
			N'<th>Co</th>' + --1
			N'<th>Bill Month</th>' + --2
			N'<th>Bill Number</th>' + --3
			N'<th>Invoice Number</th>' + --4
			N'<th>Customer</th>' + --5
			N'<th>Contract</th>' + --6
			N'<th>Created By</th>' + --7
			N'<th>Bill Amount</th>' + --8
			N'<th>Bill To Date Amount</th>' + --9
			 N'</tr>' +
			CAST 
			( 
				( 
					SELECT
						td = COALESCE(b.JBCo,' '), '' --1
					,	td = COALESCE(REPLACE(RIGHT(CONVERT(VARCHAR(11), @BillMonth, 106), 8), ' ', '-'),' '), '' --2
					,	td = COALESCE(b.BillNumber,' '), '' --3
					,	td = COALESCE(b.Invoice,' '), '' --4
					,	td = COALESCE(CONVERT(VARCHAR(30),b.Customer) + ' - ' + c.Name,' '), '' --5
					,	td = COALESCE(b.Contract + ' - ' + cc.Description,' '), '' --6
					,	td = COALESCE(b.CreatedBy,' '), '' --7
					,	td = COALESCE(@SumBillAmount,' '), '' AS BillAmount --8
					,	td = COALESCE(@SumBillToDateAmount,' '), '' AS BillToDateAmount --9
					
					FROM JBIN b
					JOIN ARCM c ON c.CustGroup = b.CustGroup AND c.Customer = b.Customer 
					JOIN JCCM cc ON b.JBCo = cc.JCCo AND b.Contract = cc.Contract
					WHERE b.JBCo=@JBCo AND b.BillMonth = @BillMonth AND b.BillNumber = @BillNumber						
					FOR XML PATH('tr'), TYPE 
				) AS NVARCHAR(MAX) ) + N'</table>' + N'<br/><br/>'

			EXEC msdb.dbo.sp_send_dbmail 
			@profile_name = 'Viewpoint',
			@recipients = @To,
			@subject = @subject,
			@body = @tableHTML,
			@body_format = 'HTML' 

			SELECT @ReturnMessage = 'Request to interface has been sent', @rcode = 0
			GOTO spexit
	END
	ELSE
	BEGIN
		SELECT @ReturnMessage = 'The Bill does not exist yet.  Please save and try again', @rcode = 1
		GOTO spexit
	END

	--SELECT @JBCo, @BillMonth


	spexit: 
	BEGIN
	RETURN @rcode
	END
END
GO
GRANT EXECUTE ON  [dbo].[mckspJBInterfaceRequest] TO [public]
GO
