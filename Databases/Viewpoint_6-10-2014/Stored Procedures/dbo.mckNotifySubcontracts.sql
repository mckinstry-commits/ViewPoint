SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 3/14/2014
-- Description:	Notify subcontracts group of routed Master Subcontract.
-- =============================================
CREATE PROCEDURE [dbo].[mckNotifySubcontracts] 
	-- Add the parameters for the stored procedure here
	@VendorGroup bGroup = 0
	, @Vendor bVendor = 0
	, @Seq INT = 0
	, @To VARCHAR(128) = 'erptest@mckinstry.com'--Need to update for GO LIVE
	, @rcode INT = 0
	, @ReturnMessage VARCHAR(MAX) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @subject NVARCHAR(100)
		,@tableHTML  NVARCHAR(MAX)
		, @Type VARCHAR(30)

	SELECT @Type = ISNULL(DDCIc.DisplayValue,'Master/Sample')
	FROM udMSA 
		LEFT OUTER JOIN DDCIc ON DDCIc.ComboType='SampleMaster' AND DDCIc.DatabaseValue=udMSA.Sample
	WHERE VendorGroup=@VendorGroup AND Vendor=@Vendor AND udMSA.Seq = @Seq
	

    -- Insert statements for procedure here
	SET @ReturnMessage = ''
	
	IF EXISTS(SELECT 1 FROM udMSA WHERE VendorGroup = @VendorGroup AND Vendor = @Vendor AND Seq = @Seq AND Requestor IS NOT NULL AND RteToSubC = 'N')
	BEGIN  --Record found but not ready
		SELECT @ReturnMessage = 'Rte to Subcontracts is not checked.  When the record is ready, check the box, save and try again.', @rcode = 1
	END
		
		
	IF EXISTS (SELECT 1 FROM udMSA WHERE VendorGroup = @VendorGroup AND Vendor = @Vendor AND Seq = @Seq AND Requestor IS NULL)
	BEGIN
		SELECT @ReturnMessage = CASE WHEN @ReturnMessage = '' THEN '' ELSE @ReturnMessage + CHAR(13) + ' ' END +'No Requestor selected.  Please fill in that field and try again.', @rcode = 1
	END
		
	IF NOT EXISTS(SELECT 1 FROM udMSA WHERE VendorGroup = @VendorGroup AND Vendor = @Vendor AND Seq = @Seq)
	BEGIN  --No Record Found
		SELECT @ReturnMessage =CASE WHEN @ReturnMessage = '' THEN '' ELSE @ReturnMessage + CHAR(13) + ' ' END + 'Not a valid Master/Sample Subcontract.  Please save the record and try again.', @rcode = 1	
	END
	
	IF EXISTS(SELECT 1 FROM udMSA WHERE VendorGroup = @VendorGroup AND Vendor = @Vendor AND Seq = @Seq AND RequestDate IS NOT NULL)
	BEGIN
		SELECT @ReturnMessage = CASE WHEN @ReturnMessage = '' THEN '' ELSE @ReturnMessage + CHAR(13) + ' ' END + 'This request was already submitted on ' + CONVERT(VARCHAR(11),RequestDate)+ '  It cannot be submitted again.' , @rcode = 1
		FROM udMSA WHERE VendorGroup = @VendorGroup AND Vendor = @Vendor AND Seq = @Seq
	END

	IF @rcode = 1
	BEGIN
	GOTO spexit
	END
	ELSE
	BEGIN
		

		IF @To IS NULL OR @To = ''
		BEGIN
			SET @To = 'erptest@mckinstry.com; erics@mckinstry.com'
		END

		SET @subject = @Type+' Subcontract Requested'

		SET @tableHTML =
				N'<H3>' + @subject + '</H3>' +
				N'<font size="-2">' +
				N'<table border="1">' +
				N'<tr bgcolor=silver>' +
				N'<th>Vendor Group</th>' + --1
				N'<th>Vendor</th>' + --2
				N'<th>Sequence</th>' + --3
				N'<th>Requestor</th>' + --4
					N'</tr>' +
				CAST 
				( 
					( 
						SELECT
							td = COALESCE(@VendorGroup,' '), '' --1
						,	td = COALESCE(@Vendor,' '), '' --2
						,	td = COALESCE(@Seq,' '), '' --3
						,	td = COALESCE(msa.Requestor,' '), ''--4
						FROM dbo.udMSA msa
						WHERE VendorGroup = @VendorGroup AND Vendor = @Vendor AND Seq = @Seq
						FOR XML PATH('tr'), TYPE 
					) AS NVARCHAR(MAX) ) + N'</table>' + N'<br/><br/>'

		EXEC msdb.dbo.sp_send_dbmail 
			@profile_name = 'Viewpoint',
			@recipients = @To,
			@subject = @subject,
			@body = @tableHTML,
			@body_format = 'HTML' 

		SELECT @ReturnMessage = @Type+ ' Subcontract Request has been sent.'

		UPDATE dbo.udMSA
		SET RequestDate = GETDATE()
		WHERE VendorGroup = @VendorGroup AND Vendor = @Vendor AND Seq = @Seq

	END

	spexit:
	BEGIN
		RETURN @rcode
	END

END
GO
GRANT EXECUTE ON  [dbo].[mckNotifySubcontracts] TO [public]
GO
