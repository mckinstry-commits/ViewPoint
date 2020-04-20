USE [Viewpoint]
GO
/****** Object:  Trigger [dbo].[mcktrShipToJob]    Script Date: 11/13/2014 12:42:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 11/13/13
-- Description:	Trigger for Address Updates
-- UPDATE: 11/13/2014 Reset @Batch to an INT
-- =============================================
ALTER TRIGGER [dbo].[mcktrShipToJob] 
   ON  [dbo].[bPOHB] 
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	IF UPDATE(udShipToJobYN) AND (SELECT udShipToJobYN FROM INSERTED) = 'Y'
		AND (SELECT Job FROM INSERTED) IS NOT NULL
	BEGIN
		DECLARE @Batch INT, @BatchMonth bDate, @Seq TINYINT
		DECLARE @ShipAddress VARCHAR(60)
		SELECT @Batch = BatchId, @BatchMonth= Mth, @Seq = BatchSeq FROM INSERTED
		
		--Variable to determine availability of a Job Shipping Address
		--If null or '' then routine will use Job Mailing Address
		SELECT 
			@ShipAddress=LTRIM(RTRIM(j.ShipAddress))
		FROM 
			JCJM j
		INNER JOIN inserted i ON j.JCCo = i.JCCo AND j.Job = i.Job
		WHERE i.BatchId=@Batch AND i.Mth=@BatchMonth AND i.BatchSeq=@Seq
		
		--New Logic Block for updating batch address.  ShipTo or MailTo addresses need to be updated
		--as a whole, not and intermixed comparison field by field.
		IF @ShipAddress IS NULL OR @ShipAddress = ''
		BEGIN
			UPDATE bPOHB
			SET Address = j.MailAddress, 
				Address2 = j.MailAddress2, 
				City = j.MailCity, 
				State = j.MailState, 
				Zip = j.MailZip, 
				Country = j.MailCountry
			FROM JCJM j 
				INNER JOIN inserted i ON j.JCCo = i.JCCo AND j.Job = i.Job
			WHERE i.BatchId=@Batch AND i.Mth=@BatchMonth AND i.BatchSeq=@Seq	
		END
		ELSE
        BEGIN
			UPDATE bPOHB
			SET Address = j.ShipAddress, 
				Address2 = j.ShipAddress2, 
				City = j.ShipCity, 
				State = j.ShipState, 
				Zip = j.ShipZip, 
				Country = j.ShipCountry
			FROM JCJM j 
				INNER JOIN inserted i ON j.JCCo = i.JCCo AND j.Job = i.Job
			WHERE i.BatchId=@Batch AND i.Mth=@BatchMonth AND i.BatchSeq=@Seq	
		END

		/*
		[2014.11.11 - LWO - Replaced with above logic to correct error (Address2=j.MailAddress) and to ensure
							entire Address is updated from same set of fields ( Ship or Mail)
		*/
		--UPDATE bPOHB
		--SET Address = CASE WHEN j.ShipAddress IS NULL THEN j.MailAddress ELSE j.ShipAddress END, 
		--	Address2 = CASE WHEN j.ShipAddress2 IS NULL THEN j.MailAddress ELSE j.ShipAddress2 END, 
		--	City = CASE WHEN j.ShipCity IS NULL  THEN j.MailCity ELSE j.ShipCity END, 
		--	State = CASE WHEN j.ShipState IS NULL THEN j.MailState ELSE j.ShipState END, 
		--	Zip = CASE WHEN j.ShipZip IS NULL THEN j.MailZip ELSE j.ShipZip END, 
		--	Country = CASE WHEN j.ShipCountry IS NULL THEN j.MailCountry ELSE j.ShipCountry END
		--FROM JCJM j 
		--	INNER JOIN inserted i ON j.JCCo = i.JCCo AND j.Job = i.Job
		--WHERE i.BatchId=@Batch AND i.Mth=@BatchMonth AND i.BatchSeq=@Seq		
	END
	ELSE
	IF (SELECT Job FROM INSERTED) IS NULL AND (SELECT udShipToJobYN FROM INSERTED) = 'Y'
	BEGIN
		RAISERROR('Ship to Job has been checked but no Job has been selected.  Please select a Job and try again.',16,11)
		ROLLBACK TRAN
	END
END

