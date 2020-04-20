USE [MCK_INTEGRATION]
GO

/****** Object:  StoredProcedure [dbo].[spInsertSitesToVP]    Script Date: 11/4/2015 10:15:51 AM ******/
DROP PROCEDURE [dbo].[spInsertSitesToVP]
GO

/****** Object:  StoredProcedure [dbo].[spInsertSitesToVP]    Script Date: 11/4/2015 10:15:51 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Eric Shafer
-- Create date: 2/19/2014
-- Description:	Insert Sites from Astea

-- 2014-05-19	CS	Insert HQContact and Site contact
-- 2014-06-20	CS	Set NonBillable = 'Y'
-- 2014-06-22	CS  Handle ARCM.Status & SMCustomer.Active,
--					update SMCustomer		
-- 2014-07-07   CS  RAISEERROR on failures	
-- 2014-08-27   CS  extra log info on failed cust select
-- 2014-09-30   CS  modify job-site ServiceSite numbering,
--                  set costing method
-- 2015-09-01   CS  98931: set value of mandatory Certified
-- 2015-09-29   CS  98951: handle tax code updates
-- =============================================
CREATE PROCEDURE [dbo].[spInsertSitesToVP] 
	-- Add the parameters for the stored procedure here
	@RowId int = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @SMCo TINYINT, @Type VARCHAR(30), @AsteaCustomerId VARCHAR(50), @SiteId VARCHAR(50), @CustGroup TINYINT
		, @VPSite VARCHAR(20), @VPCustomer VARCHAR(30), @msg VARCHAR(MAX) = ''
		, @ContactName VARCHAR(30), @ContactGroup TINYINT , @ContactSeq INT
		, @FirstName VARCHAR(30) , @LastName VARCHAR(30)
		, @Job VARCHAR(10), @JCCo TINYINT, @CusCo TINYINT, @TaxGroup TINYINT
		, @Description VARCHAR(60), @Address1 VARCHAR(60), @Address2 VARCHAR(60), @City VARCHAR(30)
		, @State VARCHAR(4), @Zip VARCHAR(12), @Country CHAR(2), @Phone VARCHAR(20)
		, @DefaultServiceCenter VARCHAR(10), @Active CHAR(1), @BillToARCustomer INT, @TaxCode VARCHAR(10)
		, @ProcessStatus CHAR(1), @VPJobSite VARCHAR(20)
		
	SELECT  @SMCo = ISNULL(SMCo,101), @Type = ISNULL(Type,'Customer'), @AsteaCustomerId = CustomerId
		, @SiteId = SiteId --, @VPSite = SiteId
		, @ContactName = CASE WHEN Contact = '' THEN NULL ELSE LEFT(Contact,30) END
		, @Job = Job, @JCCo = JCCo, @CusCo = CusCo
		, @Description = [Description], @Address1 = Address1, @Address2 = Address2, @City = City
		, @State = [State], @Zip = Zip, @Country = Country, @Phone = Phone
		, @DefaultServiceCenter = DefaultServiceCenter, @Active = Active, @BillToARCustomer = BillToARCustomer
		, @TaxCode = TaxCode, @ProcessStatus = ProcessStatus
		FROM MCK_INTEGRATION.dbo.Site
		WHERE RowId = @RowId
		
	-- Transact Log Variables
	DECLARE @LogTable VARCHAR(128) = 0, @LogDate DATETIME, @LogKey VARCHAR(128), @KeyValue VARCHAR(255), @LogUser VARCHAR(128), @LogUpdateInsert CHAR(1)

	-- Set logging variables
	SET @msg = ''
	SET @LogDate = GETDATE()
	SET @LogTable = 'SMServiceSite'
	SET @LogKey = 'RowId'
	SELECT @KeyValue = ISNULL(STR(@RowId),'MISSINGKEY')
	SET @LogUser = SUSER_SNAME()
	SET @LogUpdateInsert = 'N'

	-- Initial log entry
	SET @msg = 'Top of Site SP - RowId: ' + ISNULL(CONVERT(VARCHAR(10),@RowId), 'null')
	EXEC spInsertToTransactLog @Table = @LogTable, @KeyColumn = @LogKey, @KeyId = @KeyValue, @User = @LogUser, @UpdateInsert = @LogUpdateInsert, @msg = @msg

	-- check for missing MCK_INTEGRATION.dbo.Site record
	IF @SiteId IS NULL
	BEGIN
		SET @msg = 'No site returned when searching Site table for RowId ' + @KeyValue
		GOTO spexitnoprocess
	END	

	-- check for record already processed
	IF @ProcessStatus = 'Y'
	BEGIN
		SET @msg = 'Record already synchronized. No action taken. Astea site: ' + ISNULL(@SiteId, 'null') + ' | Type: ' + ISNULL(@Type, 'null')
		GOTO spexitnoprocess
	END	

	-- Validate Type
	IF @Type NOT IN ('Customer', 'Job')
	BEGIN
		SET @msg = 'Unable to process record.  Invalid Type: ' + ISNULL(@Type, 'null')
		GOTO spexitfail
	END

	IF @Type = 'Job' 
	BEGIN
		IF @Job IS NULL  
		BEGIN
			SET @msg = 'Job is null for Site table RowId ' + @KeyValue
			GOTO spexitnoprocess  
		END
		IF @JCCo IS NULL
		BEGIN
			SET @msg = 'Job Co is null for Site table RowId ' + @KeyValue
			GOTO spexitnoprocess          
		END      
	END  

	-- Get HQ "Group" columns based on Site Company
	SELECT @ContactGroup = ContactGroup, @CustGroup = CustGroup, @TaxGroup = TaxGroup
	FROM Viewpoint.dbo.HQCO
	WHERE HQCo = @SMCo
		
	-- Get Customer columns
	IF @Type = 'Customer'
	BEGIN
		-- Look for AR Customer that matches this Astea Customer ID/Cust Group
		SELECT @VPCustomer = Customer 
			FROM Viewpoint.dbo.ARCM cm
			WHERE CustGroup = @CustGroup AND udASTCust = @AsteaCustomerId	

		-- Validate Customer
		IF @VPCustomer IS NULL 
		BEGIN
			SET @msg = 'Unable to process record.  Missing AR Customer. Astea Customer=' + ISNULL(@AsteaCustomerId, 'null') + ' CustGroup=' + ISNULL(CONVERT(VARCHAR(3),@CustGroup),'null')
			GOTO spexitfail
		END
		
		IF @CustGroup IS NULL
		BEGIN
			SET @msg = 'Unable to process record.  Missing CustGroup. Astea Customer=' + ISNULL(@AsteaCustomerId, 'null')
			GOTO spexitfail
		END
		
		-- Check for Customer Service Site in VP that matches the Astea site ID.  
		SELECT TOP 1 @VPSite = ServiceSite FROM Viewpoint.dbo.SMServiceSite 
		WHERE SMCo = @SMCo 
		  AND udAsteaSiteId = @SiteId 
		  AND [Type] = @Type		
	END
	ELSE
	BEGIN	
		-- build the ServiceSite
		SELECT @VPJobSite = LEFT(LTRIM(RTRIM(@Job)) + '-' + LTRIM(RTRIM(@SiteId)), 20)

		-- see if one already exists
		SELECT TOP 1 @VPSite = ServiceSite FROM Viewpoint.dbo.SMServiceSite
		WHERE SMCo = @SMCo 
		  AND ServiceSite = @VPJobSite
		  AND Job = @Job
		  AND JCCo = @JCCo
		  AND [Type] = @Type
	END

	-- If a matching SM Service Site was found, log the info, then update the site with all values from Astea
	IF @VPSite IS NOT NULL
	BEGIN
		SET @msg = 'UPD Type: ' + ISNULL(@Type, 'null') + ' | ServiceSite: ' + @VPSite 
			+ ' | SMCo: ' + ISNULL(CAST(@SMCo AS VARCHAR(3)),'null') 
			+ ' | Description: ' + ISNULL(@Description, 'null') 
			+ ' | Address1: ' + ISNULL(@Address1, 'null') + ' | Address2: ' + ISNULL(@Address2, 'null') 
			+ ' | City: ' + ISNULL(@City, 'null') + ' | State: ' + ISNULL(@State,'null') 
			+ ' | Zip: ' + ISNULL(@Zip, 'null') + ' | Country: '+ ISNULL(@Country,'null') 
			+ ' | Phone: ' + ISNULL(@Phone, 'null') + ' | DefaultServiceCenter: ' + ISNULL(@DefaultServiceCenter,'null') 
			+ ' | Astea Contact: '+ ISNULL(@ContactName,'null')
			+ ' | ContactSeq: ' + ISNULL(CAST(@ContactSeq AS VARCHAR(30)), 'null') 
			+ ' | ContactGroup: ' + ISNULL(CAST(@ContactGroup AS VARCHAR(10)), 'null')
			+ ' | AsteaSiteId: '+ ISNULL(@SiteId, 'null') + ' | JCCo: ' + ISNULL(CAST(@JCCo AS VARCHAR(3)), 'null')
			+ ' | Job: ' + ISNULL(@Job,'null') + ' | AsteaCustomerId: ' + ISNULL(@AsteaCustomerId, 'null')
			+ ' | CustGroup: '	+ ISNULL(CONVERT(VARCHAR(3),@CustGroup),'null')
			+ ' | TaxCode: '+ ISNULL(@TaxCode,'null')
			+ ' | TaxGroup: ' + ISNULL(CONVERT(VARCHAR(3),@TaxGroup),'null') 
			+ ' | Active: ' + ISNULL(@Active, 'null') 
			+ ' | BillToARCustomer: ' + ISNULL(CONVERT(VARCHAR(30),@BillToARCustomer), 'null')
			+ ' | Message: Record already exists. Record updated.' 
		SELECT @LogUpdateInsert = 'U'

		BEGIN TRY
  			--Update Viewpoint SMServiceSite details with Astea values
			UPDATE Viewpoint.dbo.SMServiceSite 
			SET [Description] = @Description, Address1 = @Address1, Address2=@Address2, City=@City, [State]=@State
				, Zip=@Zip, Country=@Country, Phone=@Phone, DefaultServiceCenter=@DefaultServiceCenter
				, udAsteaSiteId = @SiteId, Job=@Job, JCCo=@JCCo, Customer = @VPCustomer
				, Active = @Active, BillToARCustomer = @BillToARCustomer, ContactGroup = @ContactGroup
				, TaxCode = @TaxCode
			WHERE SMCo = @SMCo AND ServiceSite = @VPSite --udAsteaSiteId = @SiteId AND vps.Type = ms.Type			
			GOTO spcontacts	
		END TRY
		BEGIN CATCH
			SET @msg = 'Failed to update SMServiceSite |' + ISNULL(@msg, 'null')
			GOTO spexitfail      
		END CATCH  
	END
  
	-- New VP Site Insert

	IF @Type = 'Customer'
	BEGIN
		-- validate @VPSite  
		SELECT @VPSite = @VPCustomer  

		-- There may already be a site where ServiceSite = @VPSite and SMCo = @SMCo
		-- (another Customer site for the same customer, or possibly a Job site).
		-- If so, append a dash-plus-sequential-counter to @VPSite.

		IF EXISTS (SELECT TOP 1 1 FROM Viewpoint.dbo.SMServiceSite
			WHERE ServiceSite = @VPSite AND SMCo = @SMCo)
		BEGIN
			-- 3. get the max numeric suffix, add one, and convert back to zero-padded, 3-character string
			DECLARE @NewSite VARCHAR(20)
			SELECT @NewSite = REPLACE(STR(MAX(Sint)+1, 3), ' ', '0') 
			FROM
			(
				---- 2. convert them all to integers (convert any non-numerics to zero)
				SELECT CASE WHEN ISNUMERIC(Sfx) = 0 THEN 0 ELSE CAST (Sfx AS INT) END Sint FROM
				(
					-- 1. get all the suffixes for this customer/job (and drop the dash)
					SELECT REPLACE(ServiceSite, (@VPSite + '-'), '') Sfx
					FROM Viewpoint.dbo.SMServiceSite 
					WHERE (ServiceSite LIKE @VPSite + '%') 
					AND SMCo = @SMCo
					AND ServiceSite <> @VPSite
				) d
			) dd
		
			IF @NewSite IS NULL
				SET @NewSite = '001'
			SET @VPSite = @VPSite + '-' + @NewSite
		END -- if ServiceSite already exists for this customer
	END  -- Customer-type site
	ELSE
	BEGIN
		-- for Job-type sites, use trimmed Job Number + Astea site id
		SELECT @VPSite = LEFT(LTRIM(RTRIM(@Job)) + '-' + LTRIM(RTRIM(@SiteId)), 20)
	END  
	
	-- build log message string
	SET @msg = 'INS Type: ' + ISNULL(@Type, 'null') + ' | ServiceSite: ' + ISNULL(@VPSite, 'null')
		+ ' | SMCo: ' + ISNULL(CAST(@SMCo AS VARCHAR(3)),'null') 
		+ ' | Description: ' + ISNULL(@Description, 'null') 
		+ ' | Address1: ' + ISNULL(@Address1, 'null') + ' | Address2: ' + ISNULL(@Address2, 'null') 
		+ ' | City: ' + ISNULL(@City, 'null') + ' | State: ' + ISNULL(@State,'null') 
		+ ' | Zip: ' + ISNULL(@Zip, 'null') + ' | Country: '+ ISNULL(@Country,'null') 
		+ ' | Phone: ' + ISNULL(@Phone, 'null') + ' | DefaultServiceCenter: ' + ISNULL(@DefaultServiceCenter,'null') 
		+ ' | Astea Contact: '+ ISNULL(@ContactName,'null')
		+ ' | ContactSeq: ' + ISNULL(CAST(@ContactSeq AS VARCHAR(30)), 'null') 
		+ ' | ContactGroup: ' + ISNULL(CAST(@ContactGroup AS VARCHAR(10)), 'null')
		+ ' | AsteaSiteId: '+ ISNULL(@SiteId, 'null') + ' | JCCo: ' + ISNULL(CAST(@JCCo AS VARCHAR(3)), 'null')
		+ ' | Job: ' + ISNULL(@Job,'null') + ' | AsteaCustomerId: ' + ISNULL(@AsteaCustomerId, 'null')
		+ ' | CustGroup: '	+ ISNULL(CONVERT(VARCHAR(3),@CustGroup),'null')
		+ ' | TaxCode: '+ ISNULL(@TaxCode,'null')
		+ ' | TaxGroup: ' + ISNULL(CONVERT(VARCHAR(3),@TaxGroup),'null') 
		+ ' | Active: ' + ISNULL(@Active, 'null') 
		+ ' | BillToARCustomer: ' + ISNULL(CONVERT(VARCHAR(30),@BillToARCustomer), 'null')
		+ ' | New record inserted to VP.'
	SELECT @LogUpdateInsert = 'I'	

	-- INSERT record to VP.SMServiceSite
	-- 98931: add Certified column
	BEGIN TRY  
		INSERT INTO Viewpoint.dbo.SMServiceSite
			(SMCo, ServiceSite, Type, CustGroup, Customer, Job, JCCo, Description, udAsteaSiteId, Address1, Address2, 
			City, State, Zip, Country, Phone, DefaultServiceCenter, Active, 
			NonBillable, TaxCode, TaxGroup, RateTemplate, BillToARCustomer,	ContactGroup, CostingMethod,
			Certified)
		SELECT @SMCo, @VPSite, @Type, @CustGroup, @VPCustomer, @Job, @JCCo, ISNULL(@Description,''), @SiteId
			, ISNULL(@Address1,''), ISNULL(@Address2,''), ISNULL(@City,''), ISNULL(@State,''), ISNULL(@Zip,'')
			, ISNULL(@Country,'US'), @Phone, @DefaultServiceCenter, ISNULL(@Active, 'Y')
			, 'Y', @TaxCode, @TaxGroup, '1', @BillToARCustomer, @ContactGroup, 'Cost', 'N';
		GOTO spcontacts;
	END TRY
	BEGIN CATCH
		SET @msg = 'Failed to insert SMServiceSite |' + ISNULL(@msg, 'null')
		GOTO spexitfail         
	END CATCH  
	
	spcontacts:
	BEGIN
		--EXEC spInsertToTransactLog @Table = @LogTable, @KeyColumn = @LogKey, @KeyId = @KeyValue, @User = @LogUser, @UpdateInsert = @LogUpdateInsert, @msg = @msg
	
		-- Check for matching HQContact (match based on First Name, Last Name, and Organization)
		IF @ContactName IS NOT NULL
		BEGIN
			-- clean up string
			SET @ContactName = LTRIM(RTRIM(@ContactName))
			SET @ContactName = REPLACE(REPLACE(REPLACE(REPLACE(@ContactName, CHAR(13),' '), CHAR(12),' '), CHAR(9),' '), CHAR(8),' ')

			-- Condense multiple spaces into a single space
			SELECT @ContactName = REPLACE(REPLACE(REPLACE(@ContactName,' ','<>'),'><',''),'<>',' ')

			-- break down contact name into first and last names 
			-- (assumes the FirstName is all of the characters up to the first space)
			IF CHARINDEX(' ', @ContactName) < 1
			BEGIN
				SET @FirstName = NULL
				SET @LastName = @ContactName
			END
			ELSE
			BEGIN
				SELECT @FirstName = SUBSTRING(@ContactName, 1, CHARINDEX(' ', @ContactName) - 1)
				 , @LastName = SUBSTRING(@ContactName, CHARINDEX(' ', @ContactName) + 1, 100)
			END		
		
			-- is there already an HQContact for this name & organization?
			IF @FirstName IS NULL
			BEGIN
				SELECT @ContactSeq = ContactSeq FROM Viewpoint.dbo.HQContact H
				WHERE H.Organization = @VPSite
				  AND @ContactName = ISNULL(H.LastName, '')
			END
			ELSE
			BEGIN
				SELECT @ContactSeq = ContactSeq FROM Viewpoint.dbo.HQContact H
					WHERE H.Organization = @VPSite
					  AND @ContactName = (ISNULL(H.FirstName, '') + ' ' + ISNULL(H.LastName, ''))
			END
			
			-- if no HQContact exists then create one
			IF @ContactSeq IS NULL 		
			BEGIN
				-- get the next ContactSeq
				SELECT @ContactSeq = MAX(ContactSeq)+1 FROM Viewpoint.dbo.HQContact
				IF @ContactSeq IS NULL
					SET @ContactSeq = 1
				
				-- Trim to fit
				SET @FirstName = LEFT(@FirstName, 30)
				SET @LastName = LEFT(@LastName, 30)
					
				SELECT @msg = 'Insert HQContact | Contact Group: ' + ISNULL(CAST(@ContactGroup AS VARCHAR(3)), 'null')
					+ ' | ContactSeq: ' + ISNULL(CAST(@ContactSeq AS VARCHAR(10)), 'null')
					+ ' | FirstName: ' + ISNULL(@FirstName, 'null')
					+ ' | LastName: ' + ISNULL(@LastName, 'null') 
					+ ' | Organization: ' + ISNULL(@VPSite, 'null')
					+ ' | Phone: ' + ISNULL(@Phone, 'null') 
				SELECT @LogUpdateInsert = 'I'						
											
				-- insert the record 
				BEGIN TRY
					INSERT INTO Viewpoint.dbo.HQContact
							( ContactGroup ,
							  ContactSeq ,
							  FirstName ,
							  LastName ,
							  Organization ,
							  Phone 
							)
					SELECT ISNULL(@ContactGroup, 101)
							  , @ContactSeq  
							  , @FirstName 
							  , @LastName  
							  , @VPSite 
							  , @Phone	                
				END TRY
				BEGIN CATCH
					SET @msg = 'Failed to insert HQContact |' + ISNULL(@msg, 'null')
					GOTO spexitfail 					              
				END CATCH              

				EXEC spInsertToTransactLog @Table = @LogTable, @KeyColumn = @LogKey, @KeyId = @KeyValue, @User = @LogUser, @UpdateInsert = @LogUpdateInsert, @msg = @msg
			END -- if HQContact does not already exist				

			-- add the Site Contact if needed
			IF NOT EXISTS (SELECT TOP 1 1 FROM Viewpoint.dbo.SMServiceSiteContact 
				WHERE ContactGroup = @ContactGroup 
				AND ContactSeq = @ContactSeq 
				AND ServiceSite = @VPSite
				AND SMCo = @SMCo)				
			BEGIN
  				SELECT @msg = 'Insert Site Contact | SMCo: ' + ISNULL(CAST(@SMCo AS VARCHAR(3)), 'null')
					+ ' | ServiceSite: ' + ISNULL(@VPSite, 'null')
					+ ' | ContactGroup: ' + ISNULL(CAST(@ContactGroup AS VARCHAR(3)), 'null')
					+ ' | ContactSeq: ' + ISNULL(CAST(@ContactSeq AS VARCHAR(10)), 'null')
				SELECT @LogUpdateInsert = 'I'
            
				BEGIN TRY
					INSERT INTO Viewpoint.dbo.SMServiceSiteContact
							( SMCo , ServiceSite , ContactGroup , ContactSeq)
					VALUES  ( @SMCo , @VPSite , @ContactGroup , @ContactSeq )					                
				END TRY
				BEGIN CATCH
					SET @msg = 'Failed to insert SMServiceSiteContact |' + ISNULL(@msg, 'null')
					GOTO spexitfail 					
				END CATCH          

				EXEC spInsertToTransactLog @Table = @LogTable, @KeyColumn = @LogKey, @KeyId = @KeyValue, @User = @LogUser, @UpdateInsert = @LogUpdateInsert, @msg = @msg
			END	 -- add site contact			
		END	  -- if Astea sent a contact name  

		SELECT @msg = 'Update Primary Contact for Site | SMCo: ' + ISNULL(CAST(@SMCo AS VARCHAR(3)), 'null') 
			+ ' | ServiceSite: ' + ISNULL(@VPSite, 'null')
			+ ' | ContactGroup: ' + ISNULL(CAST(@ContactGroup AS VARCHAR(3)), 'null') 
			+ ' | ContactSeq: ' + ISNULL(CAST(@ContactSeq AS VARCHAR(10)), 'null')
		SELECT @LogUpdateInsert = 'U'

		-- update primary contact (Contact could be null...)
		BEGIN TRY
			UPDATE Viewpoint.dbo.SMServiceSite 
				SET ContactSeq = @ContactSeq, ContactGroup = @ContactGroup
			WHERE SMCo = @SMCo AND ServiceSite = @VPSite -- AND udAsteaSiteId = @SiteId 
		END TRY
		BEGIN CATCH
			SET @msg = 'Failed to update SMServiceSite contact |' + ISNULL(@msg, 'null')
			GOTO spexitfail 
		END CATCH      
		
		EXEC spInsertToTransactLog @Table = @LogTable, @KeyColumn = @LogKey, @KeyId = @KeyValue, @User = @LogUser, @UpdateInsert = @LogUpdateInsert, @msg = @msg
		
		SELECT @msg = 'end of ServiceSite process - RowId: ' + ISNULL(CONVERT(VARCHAR(10),@RowId), 'null')
	END
						
	spexit:
	--Write back to MCK_INTEGRATION.dbo.Site
	BEGIN TRY
		UPDATE MCK_INTEGRATION.dbo.Site
		SET ProcessStatus = 'Y', Customer = @VPCustomer, ProcessTimeStamp = GETDATE()
		WHERE RowId = @RowId
		GOTO spexitnoprocess
	END TRY  
	BEGIN CATCH
		SET @msg = 'Failed to update MCK_INTEGRATION Site record'
		GOTO spexitfail 
	END CATCH
    

	spexitfail:
	UPDATE MCK_INTEGRATION.dbo.Site
	SET ProcessStatus = 'F', ProcessTimeStamp = GETDATE(), ProcessDesc = LEFT(ISNULL(@msg, ''), 250)
	WHERE RowId = @RowId
	SELECT @LogUpdateInsert = 'N'
	--GOTO spexitnoprocess
	EXEC spInsertToTransactLog @Table = @LogTable, @KeyColumn = @LogKey, @KeyId = @KeyValue, @User = @LogUser, @UpdateInsert = @LogUpdateInsert, @msg = @msg
	RAISERROR('spInsertSitesToVP failure', 16, 2)
	RETURN 1	

	spexitnoprocess:
	BEGIN
		EXEC spInsertToTransactLog @Table = @LogTable, @KeyColumn = @LogKey, @KeyId = @KeyValue, @User = @LogUser, @UpdateInsert = @LogUpdateInsert, @msg = @msg
		RETURN 0
	END
	
	spquit:
END

GRANT EXEC ON dbo.spInsertSitesToVP TO AsteaIntegration

GO


