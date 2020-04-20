USE [MCK_INTEGRATION]
GO

/****** Object:  StoredProcedure [dbo].[spInsertCustomersToVP]    Script Date: 11/4/2015 10:14:49 AM ******/
DROP PROCEDURE [dbo].[spInsertCustomersToVP]
GO

/****** Object:  StoredProcedure [dbo].[spInsertCustomersToVP]    Script Date: 11/4/2015 10:14:49 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Eric Shafer
-- Create date: 2/18/2014
-- Description:	Copy Customers to Viewpoint DB
/*
-- 2014-05-15 CS select PayTerms from Astea db
-- 2014-05-16 CS remove Billing Address fields
-- 2014-05-19 CS Insert HQContact and SMCustomerContact
-- 2014-06-22 CS Always non-billable=Y, 
				 fix ARCM.Status & Customer.Active
-- 2014-06-22 CS fix SM Customer SMCo value
-- 2014-06-27 CS Update SM Customer	
-- 2014-09-16 CS Get NewVPCustID value before checking;
-- this allows us to create an SM Cust even if there's already
-- an AR Cust	 
-- 2014-10-10 CS add GOTO checkSM for 1-time convert
-- 2014-12-15 CS  set StmntPrint to "Y" on insert
-- 2015-04-28 CS  set Billing Address = Mailing Address
-- 2015-06-04 CS 98737: disconnect Astea on-hold from VP on-hold
*/
-- =============================================
CREATE PROCEDURE [dbo].[spInsertCustomersToVP] 
	-- Add the parameters for the stored procedure here
	@RowId int = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @CustGroup TINYINT = 101, @Customer VARCHAR(60), @NewVPCustID INT, @TaxGroup TINYINT, @msg VARCHAR(MAX), @ARCustSortName VARCHAR(60)
		, @LogDate DATETIME, @LogTable VARCHAR(128), @LogKey VARCHAR(128), @InsertedValues VARCHAR(MAX)
		, @KeyValue VARCHAR(255), @LogUser VARCHAR(128), @SMCo TINYINT, @rcode INT, @ERRORMsg VARCHAR(MAX)
		, @ContactName VARCHAR(30)
		, @ContactGroup TINYINT, @ContactSeq INT, @FirstName VARCHAR(30), @LastName VARCHAR(30)
		, @Active CHAR(1), @AsteaStatus CHAR(1), @VPStatus CHAR(1), @NewVPCustStr VARCHAR(30)
		
	SELECT @CustGroup = co.CustGroup, @Customer = CustomerId, @TaxGroup = co.TaxGroup, @SMCo = ISNULL(c.AsteaCompany, 101)
		, @ContactName = CASE WHEN c.Contact = '' THEN NULL ELSE LEFT(c.Contact,30) END 
		, @ContactGroup = co.ContactGroup
		, @Active = c.Active, @AsteaStatus = c.Status
		FROM MCK_INTEGRATION.dbo.Customer c 
		JOIN Viewpoint.dbo.HQCO co ON ISNULL(c.AsteaCompany, 101) = HQCo
		WHERE RowId = @RowId 
	
	SET @msg = ''
	SET @LogDate = GETDATE()
	SET @LogTable = 'Customer'
	SET @LogKey = 'RowId'
	SET @LogUser = SUSER_SNAME()
	
	-- 98737 comment this out; handle differently depending on whether a new or existing customer
	-- Astea "status" = On Hold (Y/N)
	-- Combine Astea status and Active flag to build VP Status flag (A/I/H=active,inactive,hold)
	--SELECT @VPStatus = (CASE WHEN @Active = 'N' THEN 'I' 
	--					  WHEN @Active = 'Y' AND @AsteaStatus = 'Y' THEN 'H'
	--					  ELSE 'A'
	--				  END)

	/*Check VP For matching ASTEA Customer ID*/
	SELECT TOP 1 @NewVPCustID = Customer FROM Viewpoint.dbo.ARCM WHERE CustGroup = @CustGroup AND udASTCust = @Customer
	
	IF NOT EXISTS(SELECT TOP 1 1 FROM Viewpoint.dbo.ARCM WHERE CustGroup = @CustGroup AND udASTCust = @Customer)
	BEGIN
    
		-- begin 98737 
		-- set VP customer status to Active or Inactive, based on Astea setting
		SET @VPStatus = (CASE WHEN @Active = 'N' THEN 'I' ELSE 'A' END)
		-- end 98737

		SELECT @NewVPCustID=MAX(Customer)+1 FROM Viewpoint.dbo.ARCM WHERE CustGroup = @CustGroup
		IF @NewVPCustID IS NULL
			SET @NewVPCustID = 1

		SELECT @NewVPCustStr = ISNULL(CONVERT(VARCHAR(30), @NewVPCustID), 'null')
		
		SELECT @ARCustSortName = LEFT(REPLACE(Name,' ', ''),15-LEN(@NewVPCustStr)) + @NewVPCustStr
		FROM Customer WHERE RowId = @RowId

		--INSERT NEW CUSTOMER RECORD TO VP.ARCM
		-- (we can insert Contact here because it's just a text field)
		BEGIN TRY
			SET @LogTable = 'Viewpoint.dbo.ARCM'
			
			INSERT INTO Viewpoint.dbo.ARCM
					(CustGroup, TaxGroup, Customer, Name, SortName, Address, Address2, City, State, Zip
					, Country, EMail, Phone, Fax, udASTCust
					,BillAddress, BillAddress2, BillCity,BillState, BillZip, BillCountry
					, Contact, URL
					, TempYN, Status, StmtType, StmntPrint, SelPurge, MiscOnInv, MiscOnPay, FCType, MarkupDiscPct, CreditLimit, PayTerms
					, HaulTaxOpt, InvLvl, PrintLvl, SubtotalLvl, SepHaul)
			SELECT @CustGroup, @TaxGroup, @NewVPCustID, Name, @ARCustSortName, Address, Address2, City, State, Zip
					, Country, EMail, Phone, Fax, CustomerId
					, COALESCE(BillAddress, Address,''), COALESCE(BillAddress2, Address2,''), COALESCE(BillCity, City,''), COALESCE(BillState, State,''), COALESCE(BillZip, Zip,''), COALESCE(BillCountry, Country, 'US')
					, @ContactName, URL
					, 'N', @VPStatus, 'O', 'Y', 'N', 'N', 'N', 'N', 0.00, 9999999.00, PayTerms
					, '0', '0', '1','1', 'N'
				FROM MCK_INTEGRATION.dbo.Customer
				WHERE RowId = @RowId
				
			--WRITE BACK TO MCK_INT
			IF (SELECT ProcessStatus FROM MCK_INTEGRATION.dbo.Customer WHERE RowId = @RowId)='N'
			BEGIN
				SET @LogTable = 'MCK_INTEGRATION.dbo.Customer'
				
				UPDATE MCK_INTEGRATION.dbo.Customer
				SET CustGroup = @CustGroup,TaxGroup=@TaxGroup, Customer= @NewVPCustID, SortName = @ARCustSortName ,ProcessStatus = 'Y'
				WHERE RowId = @RowId
			END
		END TRY
		BEGIN CATCH
			SET @ERRORMsg = 'Error: '+ISNULL(ERROR_MESSAGE(),'')
			SET @ERRORMsg = @ERRORMsg + ' | Severity: '+ISNULL(CONVERT(VARCHAR(10),ERROR_SEVERITY()),'')

			EXEC dbo.spInsertToTransactLog @Table = @LogTable, -- varchar(128)
			    @KeyColumn = 'Customer', -- varchar(128)
			    @KeyId = @NewVPCustStr, -- varchar(255)
			    @User = @LogUser, -- varchar(128)
			    @UpdateInsert = 'I', -- char(1)
			    @msg = @ERRORMsg -- varchar(max)
			GOTO spexit
		END CATCH

		-- LOG THE TRANSACTION
		SELECT @KeyValue = CONVERT(VARCHAR(3),ISNULL(@CustGroup,000)) + @NewVPCustStr

		SELECT @InsertedValues =  'AR Customer record added | CustGroup:'+CONVERT(VARCHAR(3),ISNULL(@CustGroup,101))+ ' | TaxGroup:' + CONVERT(VARCHAR(3),ISNULL(@TaxGroup,101))
			+ ' | Customer:' + @NewVPCustStr + ' | Name:' + ISNULL(Name,'')+ ' | SortName:'+ISNULL(@ARCustSortName,'')
			+ ' | Address1:' + ISNULL(Address,'') + ' | Address2:' + ISNULL(Address2,'') + ' | City:'+ ISNULL(City,'') + '| State:' + ISNULL(State,'')
			+ ' | Zip:' + ISNULL(Zip,'') + ' | Country:'+ ISNULL(Country,'US') + ' | Email:' + ISNULL(EMail,'') + ' | Phone:' + ISNULL(Phone,'')
			+ ' | Fax:' + ISNULL(Fax,'') + ' | AsteaId:'+ ISNULL(CustomerId,'') + ' | BillAddress1:' + COALESCE(BillAddress, Address,'')
			--+ ' | BillAddress2:' + COALESCE(BillAddress2, Address2,'') + ' | BillCity:' + COALESCE(BillCity, City,'') + ' | BillState:' + COALESCE(BillState, State,'') + ' | BillZip:'+ COALESCE(BillZip, Zip,'') + ' | BillCountry:' + COALESCE(BillCountry, Country, 'US')
			+ ' | Contact:' + ISNULL(Contact,'') + ' | ContactExt:' + ISNULL(ContactExt,'') + ' | URL:'+ ISNULL(URL,'')
			+ ' | TempYN:' + 'N' + ' | Status:' + ISNULL(@VPStatus, '') + ' | StmtType:' + 'O' + ' | StmtType:' + 'N'+ ' | SelPurge:' + 'N' + ' | MiscOnInvoice:' + 'N' 
			+ ' | MiscOnPay:' + 'N' + ' | FCType:'+ 'N' + ' | MarkupDiscPct:' + CONVERT(VARCHAR(10),0.00) 
			+ ' | CreditLimit:' + CONVERT(VARCHAR(12),9999999.00) + ' | PayTerms:' + ISNULL(PayTerms, '') + ' | HaulTaxOpt:' + '0' 
			+ ' | InvLvl:'+ '0' +' | PrintLvl:' + '1' + ' | SubtotalLvl:' + '1' + ' | SepHaul:' + 'N' + ' | Message: ' + ISNULL(@msg, '')
		FROM MCK_INTEGRATION.dbo.Customer
		WHERE RowId = @RowId
			
		EXEC dbo.spInsertToTransactLog @Table = 'Viewpoint.dbo.ARCM', 
		    @KeyColumn = 'ARCM.CustGroup+ARCM.Customer', 
		    @KeyId = @KeyValue, 
		    @User = @LogUser, 
		    @UpdateInsert = 'I', 
		    @msg = @InsertedValues 
		
		GOTO checkSM
	END
	ELSE
	BEGIN

		--Already Exists in Viewpoint.  Update and Write back sync status.
		
		DECLARE @VPBeforeStatus CHAR(1) -- 98737 holds old VP active/inactive/onhold status

		-- 98737 add @VPBeforeStatus to SELECT
		SELECT @NewVPCustID= Customer, @VPBeforeStatus=[Status] FROM Viewpoint.dbo.ARCM WHERE CustGroup = @CustGroup AND udASTCust = @Customer

		SELECT @NewVPCustStr = ISNULL(CONVERT(VARCHAR(30), @NewVPCustID), 'null')
		
		IF (SELECT ProcessStatus FROM MCK_INTEGRATION.dbo.Customer WHERE RowId = @RowId)='Y'
		BEGIN
			SET @msg = 'RowId '+CONVERT(VARCHAR(30),@RowId) +'has already been processed.  No action taken.'
			EXEC dbo.spInsertToTransactLog @Table = 'MCK_INTEGRATION.dbo.Customer', 
			    @KeyColumn = 'RowId', 
			    @KeyId = @RowId, 
			    @User = @LogUser , 
			    @UpdateInsert = 'N',
			    @msg = @msg 
			
			GOTO checkSM
		END
		ELSE
		BEGIN
			-- uncomment this for one-time conversion      
			--GOTO checkSM:
						      
			--UPDATE EXISTING CUSTOMER RECORD TO VP.ARCM
			-- (we can update Contact here because it's just a text field)
			BEGIN TRY
				SET @LogTable = 'Viewpoint.dbo.ARCM'
				
				-- begin 98737 
				-- set VP customer status to Active or Inactive, based on Astea setting and VP "before" setting
				-- Astea values: Y=active, N=inactive --- VP values: (A)ctive, (I)nactive, (H)old
				-- ASTEA     VP BEFORE   VP AFTER
				-- Y         A           A
				-- Y         H           H
				-- Y         I           A
				-- N         A           I
				-- N         H           I
				-- N         I           I

				SET @VPStatus = 
					CASE 
						WHEN @Active = 'Y' AND @VPBeforeStatus = 'A' THEN 'A' 
						WHEN @Active = 'Y' AND @VPBeforeStatus = 'H' THEN 'H'
						WHEN @Active = 'Y' AND @VPBeforeStatus = 'I' THEN 'A'
						WHEN @Active = 'N' THEN 'I'
						ELSE 'A' 
					END
				-- end 98737

				UPDATE Viewpoint.dbo.ARCM
				SET Name = c.Name, Address = c.Address, Address2 = c.Address2, City=c.City, State=c.State, Zip=c.Zip, Country=c.Country
					, BillAddress=ISNULL(c.BillAddress, c.Address), BillAddress2 = ISNULL(c.BillAddress2, c.Address2), BillCity=ISNULL(c.BillCity, c.City), BillState=ISNULL(c.BillState, c.State), BillZip=ISNULL(c.BillZip, c.Zip), BillCountry=COALESCE(c.BillCountry, c.Country,'US')
					, Phone = c.Phone, Fax=c.Fax, Contact=c.Contact, ContactExt=c.ContactExt, EMail=c.EMail, URL=c.URL
					, udASTCust = @Customer
					, PayTerms = c.PayTerms
					, [Status] = @VPStatus
				FROM MCK_INTEGRATION.dbo.Customer c
					JOIN Viewpoint.dbo.ARCM cm ON cm.udASTCust = c.CustomerId AND cm.CustGroup=@CustGroup
				WHERE c.RowId = @RowId AND cm.CustGroup=@CustGroup AND cm.Customer = @NewVPCustID
				
				SET @LogTable = 'MCK_INTEGRATION.dbo.Customer'
				
				--WRITE BACK TO MCK_INT			
				UPDATE MCK_INTEGRATION.dbo.Customer
				SET	CustGroup=@CustGroup, TaxGroup = @TaxGroup, Customer = @NewVPCustID, ProcessStatus = 'Y'
				WHERE RowId = @RowId
			END TRY
			BEGIN CATCH
				SET @ERRORMsg = 'Error: '+ISNULL(ERROR_MESSAGE(),'')
				SET @ERRORMsg = @ERRORMsg + ' | Severity: '+ISNULL(CONVERT(VARCHAR(10),ERROR_SEVERITY()),'')
				EXEC dbo.spInsertToTransactLog @Table = @LogTable, -- varchar(128)
					@KeyColumn = 'Customer', -- varchar(128)
					@KeyId = @NewVPCustStr, -- varchar(255)
					@User = @LogUser, -- varchar(128)
					@UpdateInsert = 'U', -- char(1)
					@msg = @ERRORMsg -- varchar(max)
				GOTO spexit 
			END CATCH

			-- LOG THE TRANSACTION
			SET @KeyValue = CONVERT(VARCHAR(3),@CustGroup) + '+' +@NewVPCustStr
			
			SELECT @InsertedValues = 'AR Customer updated | Name: '+ ISNULL(cc.Name,'') 
				+ ' | Address: ' + ISNULL(cc.Address,'') + ' | Address2: '+ ISNULL(cc.Address2,'')
				+ ' | City: ' + ISNULL(cc.City,'') + ' | State: ' + ISNULL(cc.State,'')+ ' | Zip: '+ISNULL(cc.Zip,'') + ' | Country: ' + ISNULL(cc.Country,'')
			--	+ ' | BillAddress: '+COALESCE(cc.BillAddress, cc.Address,'') + ' | BillAddress2: ' + COALESCE(cc.BillAddress2, cc.Address2,'') + '|BillCity: ' + COALESCE(cc.BillCity, cc.City,'') + '|BillState: ' + COALESCE(cc.BillState, cc.State,'') + '|BillZip: ' + COALESCE(cc.BillZip, cc.Zip,'') + '|BillCountry: ' + COALESCE(cc.BillCountry, cc.Country,'US')
				+ ' | Phone: ' + ISNULL(cc.Phone,'') + ' | Fax: ' + ISNULL(cc.Fax,'') + ' | Contact: ' + ISNULL(cc.Contact,'') 
				+ ' | ContactExt: '	+ ISNULL(cc.ContactExt,'') + ' | EMail: ' + ISNULL(cc.EMail,'') + ' | URL: ' + ISNULL(cc.URL,'')
				+ ' | udASTCust: ' + ISNULL(@Customer, '') + ' | Payment Terms: ' + ISNULL(cc.PayTerms,'') 
				+ ' | Status: ' + ISNULL(@VPStatus, '') + ' | Message: ' + ISNULL(@msg, '')
				FROM MCK_INTEGRATION.dbo.Customer cc
				JOIN Viewpoint.dbo.ARCM cm ON cm.udASTCust = cc.CustomerId AND cm.CustGroup=@CustGroup
				WHERE cc.RowId = @RowId AND cm.udASTCust = cc.CustomerId AND cm.CustGroup=@CustGroup

			EXEC dbo.spInsertToTransactLog @Table = 'Viewpoint.dbo.ARCM', 
			    @KeyColumn = 'CustGroup+Customer', 
			    @KeyId = @KeyValue, 
			    @User = @LogUser, 
			    @UpdateInsert ='U', 
			    @msg = @InsertedValues 	
		END		-- else Customer record already processed
	END		-- else update the existing ARCM record


	--Check and Insert record to SMCustomer
	checkSM:
	IF NOT EXISTS (SELECT TOP 1 1 FROM Viewpoint.dbo.SMCustomer WHERE CustGroup = @CustGroup AND Customer = @NewVPCustID AND SMCo = @SMCo)
	BEGIN
		DECLARE @SMCustomer INT
		
		BEGIN TRY
			SET @LogTable = 'Viewpoint.dbo.SMCustomer' 
			
			INSERT INTO Viewpoint.dbo.SMCustomer 
				(CustGroup, Customer, SMCo, NonBillable, Active, udConvertedYN, CustomerPOSetting, InvoiceGrouping, InvoiceSummaryLevel)
			VALUES (@CustGroup, @NewVPCustID, @SMCo, 'Y', @Active, 'N','N', 'C', 'L')		
			
		END TRY
		BEGIN CATCH
			SET @ERRORMsg = 'Error: '+ISNULL(ERROR_MESSAGE(),'')
			SET @ERRORMsg = @ERRORMsg + ' | Severity: '+ISNULL(CONVERT(VARCHAR(10),ERROR_SEVERITY()),'')
			EXEC dbo.spInsertToTransactLog @Table = @LogTable, -- varchar(128)
				@KeyColumn = 'Customer', -- varchar(128)
				@KeyId = @NewVPCustStr, -- varchar(255)
				@User = @LogUser, -- varchar(128)
				@UpdateInsert = 'I', -- char(1)
				@msg = @ERRORMsg -- varchar(max)
			GOTO spexit
		END CATCH
		
		-- get the newly-minted SMCustomerID and log it
		SELECT @SMCustomer = SMCustomerID 
			FROM Viewpoint.dbo.SMCustomer
			WHERE CustGroup = @CustGroup AND SMCo = @SMCo AND Customer = @NewVPCustID
		
		EXEC dbo.spInsertToTransactLog @Table = 'Viewpoint.dbo.SMCustomer', -- varchar(128)
		    @KeyColumn = 'SMCustomerID', -- varchar(128)
		    @KeyId = @SMCustomer, -- varchar(255)
		    @User = @LogUser, -- varchar(128)
		    @UpdateInsert = 'I', -- char(1)
		    @msg = 'SM Customer record added.' -- varchar(max)	
		
		GOTO pmfirmadd
	END
	ELSE 
	BEGIN
	--	SET @msg = @msg + CHAR(13)+'SM Customer already exists in Viewpoint database. No action taken'
	--	SELECT @SMCustomer = SMCustomerID FROM Viewpoint.dbo.SMCustomer WHERE CustGroup = @CustGroup AND Customer = @NewVPCustID

		--UPDATE EXISTING CUSTOMER RECORD TO VP.SMCustomer
		BEGIN TRY
			SET @LogTable = 'Viewpoint.dbo.SMCustomer'
			
			UPDATE Viewpoint.dbo.SMCustomer
				SET Active = @Active 
				WHERE CustGroup = @CustGroup AND SMCo = @SMCo AND Customer = @NewVPCustID
			
		END TRY
		BEGIN CATCH
			SET @ERRORMsg = 'Error: '+ISNULL(ERROR_MESSAGE(),'')
			SET @ERRORMsg = @ERRORMsg + ' | Severity: '+ISNULL(CONVERT(VARCHAR(10),ERROR_SEVERITY()),'')
			EXEC dbo.spInsertToTransactLog @Table = @LogTable, -- varchar(128)
				@KeyColumn = 'Customer', -- varchar(128)
				@KeyId = @NewVPCustStr, -- varchar(255)
				@User = @LogUser, -- varchar(128)
				@UpdateInsert = 'U', -- char(1)
				@msg = @ERRORMsg -- varchar(max)
			GOTO spexit 
		END CATCH	
		
		SET @InsertedValues = 'SM Customer updated | Customer: ' + @NewVPCustStr
						+ ' | SMCo: ' + ISNULL(CAST(@SMCo AS VARCHAR(3)), 'null') + ' | Active: ' + ISNULL(@Active, 'null')
						
		EXEC dbo.spInsertToTransactLog @Table = 'Viewpoint.dbo.SMCustomer', -- varchar(128)
		    @KeyColumn = 'Customer', -- varchar(128)
		    @KeyId = @NewVPCustStr, -- varchar(255)
		    @User = @LogUser, -- varchar(128)
		    @UpdateInsert = 'U', -- char(1)
		    @msg = @InsertedValues -- varchar(max)   	
	END		-- else SM Customer record already exists
	
	pmfirmadd:
	IF NOT EXISTS(SELECT 1 FROM Viewpoint.dbo.PMFM WHERE VendorGroup = @CustGroup AND FirmNumber = @NewVPCustID)
	BEGIN
		SET @msg =''
		BEGIN TRY
			SET @LogTable = 'Viewpoint.dbo.PMFM'
			
			EXEC @rcode=Viewpoint.dbo.vspPMFirmInitializeCustomer @vendorgroup = @CustGroup, -- bGroup
				@custgroup = @CustGroup, -- bGroup
				@begincustomer = @NewVPCustID, -- bCustomer
				@endcustomer = @NewVPCustID, -- bCustomer
				@firmtype = 'CLIENT', -- bFirmType
				@copybilladdrtoshipaddr = 'Y', -- bYN
				@errmsg = @msg out-- varchar(255)
		END TRY
		BEGIN CATCH
			SET @ERRORMsg = 'Error: '+ISNULL(ERROR_MESSAGE(),'')
			SET @ERRORMsg = @ERRORMsg + ' | Severity: '+ISNULL(CONVERT(VARCHAR(10),ERROR_SEVERITY()),'')
			SET @ERRORMsg = @ERRORMsg + ' | SP Return Message: ' + ISNULL(@msg,'')
			EXEC dbo.spInsertToTransactLog @Table = @LogTable, -- varchar(128)
				@KeyColumn = 'Customer', -- varchar(128)
				@KeyId = @NewVPCustStr, -- varchar(255)
				@User = @LogUser, -- varchar(128)
				@UpdateInsert = 'I', -- char(1)
				@msg = @ERRORMsg -- varchar(max)
			GOTO spexit
		END CATCH

		EXEC dbo.spInsertToTransactLog @Table = 'Viewpoint.dbo.PMFM', -- varchar(128)
		    @KeyColumn = 'FirmNumber', -- varchar(128)
		    @KeyId = @NewVPCustStr, -- varchar(255)
		    @User = @LogUser, -- varchar(128)
		    @UpdateInsert = 'N', -- char(1)
		    @msg = @msg -- varchar(max)
		--PRINT @msg
		--RETURN @rcode

	END
	ELSE
	BEGIN
		DECLARE @PMFirm INT
		SET @msg = @msg + CHAR(13)+'PM Firm already exists in Viewpoint database. No action taken'
		SELECT @PMFirm = FirmNumber FROM Viewpoint.dbo.PMFM WHERE VendorGroup = @CustGroup AND FirmNumber = @NewVPCustID

		EXEC dbo.spInsertToTransactLog @Table = 'Viewpoint.dbo.PMFM', -- varchar(128)
		    @KeyColumn = 'FirmNumber', -- varchar(128)
		    @KeyId = @PMFirm, -- varchar(255)
		    @User = @LogUser, -- varchar(128)
		    @UpdateInsert = 'N', -- char(1)
		    @msg = @msg -- varchar(max)
		--PRINT @msg
		--RETURN 1

	END
	
	-- CONTACTS

	-- Did Astea send a contact name?
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
			WHERE H.Organization = CAST(@NewVPCustID AS VARCHAR(30))
			  AND @ContactName = ISNULL(H.LastName, '')
		END
		ELSE
		BEGIN
			SELECT @ContactSeq = ContactSeq FROM Viewpoint.dbo.HQContact H
				WHERE H.Organization = CAST(@NewVPCustID AS VARCHAR(30))
				  AND @ContactName = (ISNULL(H.FirstName, '') + ' ' + ISNULL(H.LastName, ''))
		END
				
		-- if no HQContact exists then create one
		IF @ContactSeq IS NULL 
		BEGIN TRY	
			BEGIN TRAN
				SET @LogTable = 'Viewpoint.dbo.HQContact'
			
				-- get the next ContactSeq
				SELECT @ContactSeq = MAX(ContactSeq)+1 FROM Viewpoint.dbo.HQContact
				IF @ContactSeq IS NULL
					SET @ContactSeq = 1			

				-- Trim to fit
				SET @FirstName = LEFT(@FirstName, 30)
				SET @LastName = LEFT(@LastName, 30)

				-- insert the record
				INSERT INTO Viewpoint.dbo.HQContact
						( ContactGroup ,
						  ContactSeq ,
						  FirstName ,
						  LastName ,
						  Organization ,
						  Phone ,
						  Email
						)
				SELECT ISNULL(@ContactGroup, 101)
						  , @ContactSeq  
						  , @FirstName 
						  , @LastName  
						  , CAST(@NewVPCustID AS VARCHAR(30))
						  , cu.Phone
						  , cu.EMail
				FROM MCK_INTEGRATION.dbo.Customer cu
				WHERE RowId = @RowId		
			COMMIT TRAN								
		END TRY
		BEGIN CATCH
			
			SET @KeyValue = ISNULL(CAST(@ContactSeq AS VARCHAR(255)), 'null')
			SET @ERRORMsg = 'Error: '+ISNULL(ERROR_MESSAGE(),'')
			SET @ERRORMsg = @ERRORMsg + ' | Severity: '+ISNULL(CONVERT(VARCHAR(10),ERROR_SEVERITY()),'')
			SET @ERRORMsg = @ERRORMsg + ' | SP Return Message: ' + ISNULL(@msg,'')
			ROLLBACK TRAN
			EXEC dbo.spInsertToTransactLog @Table = @LogTable, -- varchar(128)
				@KeyColumn = 'ContactSeq', -- varchar(128)
				@KeyId = @KeyValue, -- varchar(255)
				@User = @LogUser, -- varchar(128)
				@UpdateInsert = 'I', -- char(1)
				@msg = @ERRORMsg -- varchar(max)
			GOTO spexit
		END CATCH	
		
		-- add the Customer Contact if needed
		IF NOT EXISTS (SELECT TOP 1 1 FROM Viewpoint.dbo.SMCustomerContact 
			WHERE ContactGroup = @ContactGroup 
			  AND ContactSeq = @ContactSeq
			  AND Customer = @NewVPCustID)
		BEGIN TRY
			BEGIN TRAN
				SET @LogTable = 'Viewpoint.dbo.SMCustomerContact'
				INSERT INTO Viewpoint.dbo.SMCustomerContact
						( SMCo , CustGroup , Customer , ContactGroup , ContactSeq)
				VALUES  ( @SMCo , @CustGroup , @NewVPCustID , @ContactGroup , @ContactSeq )
			COMMIT TRAN
		END TRY
		BEGIN CATCH
			SET @KeyValue = ISNULL(CAST(@ContactSeq AS VARCHAR(255)), 'null')
			SET @ERRORMsg = 'Error: '+ISNULL(ERROR_MESSAGE(),'')
			SET @ERRORMsg = @ERRORMsg + ' | Severity: '+ISNULL(CONVERT(VARCHAR(10),ERROR_SEVERITY()),'')
			SET @ERRORMsg = @ERRORMsg + ' | SP Return Message: ' + ISNULL(@msg,'')
			ROLLBACK TRAN
			EXEC dbo.spInsertToTransactLog @Table = @LogTable, -- varchar(128)
				@KeyColumn = 'ContactSeq', -- varchar(128)
				@KeyId = @KeyValue, -- varchar(255)
				@User = @LogUser, -- varchar(128)
				@UpdateInsert =  'I', -- char(1)
				@msg = @ERRORMsg -- varchar(max)
			GOTO spexit
		END CATCH		
	END		
		
	spexit:
END
GO


