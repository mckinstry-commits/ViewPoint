USE Viewpoint
GO

If EXISTS ( Select * From INFORMATION_SCHEMA.ROUTINES Where ROUTINE_NAME='MCKspDeliverInvoice' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='PROCEDURE' )
Begin
	Print 'DROP PROCEDURE dbo.MCKspDeliverInvoice'
	DROP PROCEDURE dbo.MCKspDeliverInvoice
End
GO

Print 'CREATE PROCEDURE dbo.MCKspDeliverInvoice'
GO


CREATE PROCEDURE [dbo].MCKspDeliverInvoice
(
  @SMCo				bCompany
, @InvoiceNumber	VARCHAR(10)
)
AS
 /* 
	Purpose:	Mark invoice as "Delivered" in SMInvoice and creates record in vSMDelivery so that it appears in Viewpoint's SM Delivery tab of the SM Invoice Review form 	
	Created:	12.12.2018
	Author:		Leo Gurdian
	12.12.2018 LG - created #3782
*/
 	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

BEGIN 

	--DECLARE @SMCo TINYINT = 1
	--DECLARE @InvoiceNumber  VARCHAR(10) = '  10061222'
	DECLARE @SMSessionID INT 
	DECLARE @SMInvoiceID BIGINT --= 47335
	DECLARE @Prebilling BIT = NULL
	DECLARE @SMDeliveryGroupID INT = NULL
	DECLARE @DeliveryID BIGINT 
	DECLARE @SMDeliveryMethod CHAR(1)
	DECLARE @ReportID INT
	DECLARE @msg VARCHAR(256) 
	DECLARE @removeSession AS BIT = 0 -- false
	DECLARE @DeliveredBy VARCHAR(128)
	DECLARE @DateSent DATETIME
	DECLARE @Error INT

BEGIN TRY

	SELECT @SMInvoiceID = SMInvoiceID FROM	dbo.SMInvoice WHERE (RTRIM(LTRIM(ISNULL(InvoiceNumber,'')))) = (RTRIM(LTRIM(ISNULL(@InvoiceNumber,''))))

	IF @SMInvoiceID IS NULL
	BEGIN	
		SET @msg = 'Cannot find associated SMInvoiceID with invoice number: ' + @InvoiceNumber
		GOTO i_exit
	END	

	/* translate ud delivery methods to varchar(1) */
	SET @SMDeliveryMethod = (SELECT TOP (1)
								CASE WHEN CHARINDEX('Emails and Mails', DisplayValue)> 0 THEN 'B'
									 WHEN CHARINDEX('Emails', DisplayValue)> 0 THEN 'E'
									 WHEN CHARINDEX('Mails', DisplayValue)> 0 THEN 'P'
									 ELSE 'O' --other e.g. Customer Delivery Portal
								END AS SMDeliveryMethod
							FROM DDCIShared 
							WHERE ComboType = 'udDelMethod' 
								AND DatabaseValue = (SELECT udDelMethod From dbo.SMInvoiceList I
														JOIN dbo.SMCustomer C ON
																 C.SMCo = I.SMCo
															AND C.Customer = I.BillToARCustomer
															AND C.CustGroup = I.CustGroup
														Where (RTRIM(LTRIM(ISNULL(I.InvoiceNumber,'')))) = (RTRIM(LTRIM(ISNULL(@InvoiceNumber,''))))))

	IF @SMDeliveryMethod IS NULL
	BEGIN	
		SET @msg = 'Cannot find SMDeliveryMethod for Invoice ' + @InvoiceNumber
		GOTO i_exit
	END	

	/* is the invoice open in Viewpoint's SM Invoice Review form?  if so, we won't tear it down session when finished*/
	SELECT @SMSessionID = SMSessionID FROM dbo.vSMInvoiceSession WHERE SMInvoiceID = @SMInvoiceID
	if @SMSessionID IS NULL SET @removeSession = 1

	BEGIN TRAN

	/* GET OR START SESSION AND ADD INVOICE TO IT */
	EXEC dbo.vspSMSessionStart @SMSessionID=@SMSessionID OUT, @SMInvoiceID=@SMInvoiceID, @SMCo=@SMCo, @Prebilling=@Prebilling, @msg=@msg OUT	
	
	SELECT @SMSessionID = SMSessionID FROM dbo.vSMInvoiceSession WHERE SMInvoiceID = @SMInvoiceID

	IF @SMSessionID IS NULL
	BEGIN	
		SET @msg = 'Unable to get SMSessionID for Invoice ' + @InvoiceNumber
		GOTO i_exit
	END	

	EXEC dbo.vspSMSessionAddInvoice @SMCo = @SMCo,               
	                                @SMSessionID = @SMSessionID,             
	                                @SMInvoiceID = @SMInvoiceID,             
	                                @ReportID = @ReportID OUTPUT, 
	                                @msg = @msg OUTPUT         
	
	/* is invoice in session with another user? */
	IF @msg IS NOT NULL
	BEGIN
		IF CHARINDEX(SUSER_SNAME(), @msg) = 1 -- if yes, does invoice session belong to user?
		BEGIN
			--Yes, ignore and continue
			GOTO create_delivery
		END 

		/* another user might be on a session with invoice */
		GOTO i_exit
	END

create_delivery:

	SET @msg=NULL
	EXEC dbo.vspSMDeliveryGroupGet @SMSessionID = @SMSessionID,                    
								   @SMDeliveryGroupID = @SMDeliveryGroupID OUTPUT, 
								   @msg = @msg OUTPUT                             -- is never set
	
	IF (@SMDeliveryGroupID IS NOT NULL)
	BEGIN
		SET @msg=NULL

		/* Insert invoice into SMRecipients */
		EXEC @Error = vspSMRecipients @SMSessionID = @SMSessionID, @msg=@msg
		IF @msg IS NOT NULL
		BEGIN
			GOTO i_exit
		END	

		SET @DateSent = GETDATE();

		/*	Create DeliveryID.
			@SMDeliveryMethod = P-rinted, E-mail 
			@SMDeliveryStatus = D-elivered, R-eady, F-ailed  
		*/
		INSERT INTO vSMDelivery (SMCo, SMDeliveryGroupID, Recipient, Email, Address1, Address2, City, [State], Country, PostalCode, DateSent, Bill, SMDeliveryStatus, SMDeliveryMethod, SMInvoiceID, UniqueAttchID, DeliveryTo)
		SELECT SMCo, @SMDeliveryGroupID, RecipientName, RecipientEmail, RecipientAddress1, RecipientAddress2, RecipientCity, RecipientState, RecipientCountry, RecipientPostalCode, @DateSent, Bill, 'D', @SMDeliveryMethod, vSMInvoiceSession.SMInvoiceID, UniqueAttchID, DeliveryTo
		FROM		vSMRecipients
		INNER JOIN	vSMInvoiceSession
		ON		
					vSMInvoiceSession.SMInvoiceID = vSMRecipients.SMInvoiceID
		WHERE	
					SMCo = @SMCo
		AND		
					vSMInvoiceSession.SMSessionID = @SMSessionID
			

		INSERT INTO vSMDeliveryGroupInvoice (SMDeliveryGroupID, SMInvoiceID)
		SELECT @SMDeliveryGroupID, vSMInvoiceSession.SMInvoiceID
		FROM		vSMRecipients
		INNER JOIN	vSMInvoiceSession
		ON			vSMInvoiceSession.SMInvoiceID = vSMRecipients.SMInvoiceID
		WHERE		SMCo = @SMCo
		AND			vSMInvoiceSession.SMSessionID = @SMSessionID
		GROUP BY	vSMInvoiceSession.SMInvoiceID

		SELECT @DeliveryID = DeliveryID FROM dbo.vSMDelivery WHERE vSMDelivery.SMInvoiceID = @SMInvoiceID

		/* MARK AS DELIVERED */
		SET @DeliveredBy = SUSER_SNAME()

		SET @SMInvoiceID  = (SELECT SMInvoiceID FROM SMDelivery WHERE SMDelivery.DeliveryID = @DeliveryID)

		UPDATE dbo.SMInvoice 
		SET 
			DeliveredBy				= @DeliveredBy, 
			DeliveredDate			= @DateSent -- to match vSMDelivery
		FROM 
			dbo.SMInvoice
		WHERE
			SMInvoice.SMInvoiceID	= @SMInvoiceID
	END	

  COMMIT TRAN

END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRAN
		Set @msg =  ERROR_PROCEDURE() + ', ' + N'Line:' + CAST(ERROR_LINE() as VARCHAR(MAX)) + ' | ' + ERROR_MESSAGE();
		Goto i_exit
	END CATCH

i_exit:
	if (@msg IS NOT NULL)
		BEGIN
		 IF @@TRANCOUNT > 0 ROLLBACK TRAN
		 PRINT CAST(@msg AS VARCHAR(800))
		 RAISERROR(@msg, 11, -1);
		END
        
	IF @removeSession = 1
	BEGIN
		/* invoice not open in VP form so remove session*/
		DELETE dbo.vSMInvoiceSession WHERE SMInvoiceID = @SMInvoiceID AND SMSessionID = @SMSessionID 
	END
	ELSE
		BEGIN
			DELETE dbo.vSMDeliveryGroupInvoice	WHERE SMInvoiceID = @SMInvoiceID AND SMDeliveryGroupID = @SMDeliveryGroupID
		END	

	/* executed on SM Invoice Review form close; removes invoice from vSMDelivery if left on 'R'eady status.  */
	EXEC dbo.vspSMDeliveryGroupCleanup @SMDeliveryGroupID=@SMDeliveryGroupID, @msg = @msg OUTPUT -- @msg is never set

	SELECT DeliveredDate AS SentDate, DeliveredBy AS SentBy FROM dbo.SMInvoice WHERE SMInvoiceID = @SMInvoiceID-- success
End


GO

Grant EXECUTE ON dbo.MCKspDeliverInvoice TO [MCKINSTRY\Viewpoint Users]

-- exec dbo.MCKspDeliverInvoice 1, '  10060949'

--SELECT DeliveredDate AS SentDate, DeliveredBy AS SentBy FROM dbo.SMInvoice WHERE SMInvoiceID = 47601