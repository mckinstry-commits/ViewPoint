SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 9/30/13
-- Description:	Date Time stamp for Job Request
-- =============================================
CREATE PROCEDURE [dbo].[mckspJobCreate] 
	(@Company int,
	@VPUserName bVPUserName 
	,@JRNum INT,
	@rcode int,
	@ReturnMessage VARCHAR(255)=null output)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	
	DECLARE @Contract varchar(30) = NULL,
	@ProjName varchar(255),
	@ProjWorkstream varchar(255),
	@POC int,
	@Customer INT = NULL,
	@JCDepartment VARCHAR(30),
	@CertPR varchar(1),
	@Public varchar(1),
	--@NTP varchar(1), 
	@NewProjectNum VARCHAR(30) = NULL, 
	@TaxGroup bGroup,
	@CustGroup bGroup,
	@OurFirm INT,
	@JobStatus INT,
	@ApplyTemplate VARCHAR(10), 
	@ConChannel TINYINT,
	@PrevWage CHAR(1),
	@GovntYN bYN,
	@GovntOwnYN bYN,
	@WorkRecYN bYN,
	@RiskProfile CHAR(1),
	@ProjSuffix VARCHAR(3),
	/*Building Address*/
	@BAdd1 VARCHAR(60),
	@BAdd2 VARCHAR(60),
	@BCity VARCHAR(30),
	@BState bState, 
	@BZip bZip,
	/*Project Mail Addresses*/
	@ProjAddress1 VARCHAR(60),
	@ProjAddress2 VARCHAR(60),
	@ProjCity VARCHAR(30),
	@ProjState VARCHAR(2),
	@ProjZip bZip,
	@ProjCountry VARCHAR(2),
	/*Project Ship Addresses*/
	@ProjShipAddress1 VARCHAR(60),
	@ProjShipAddress2 VARCHAR(60),
	@ProjShipCity VARCHAR(30),
	@ProjShipState VARCHAR(2),
	@ProjShipZip bZip,
	@ProjShipCountry VARCHAR(2),
	@PRState VARCHAR(2),
	--@Validate TINYINT,
	@NCustName VARCHAR(60),
	@NCustAdd1 VARCHAR(30),
	@NCustAdd2 VARCHAR(30),
	@NCustCity VARCHAR(30),
	@NCustState VARCHAR(2),
	@NCustZip bZip,
	@NCustContactName VARCHAR(60),
	@NCustPhone VARCHAR(20),
	@NCustEmail NVARCHAR(30),
	@NCustFax VARCHAR(20),
	@NCustCountry VARCHAR(2),
	@UseShipAddress bYN,
	@UseMailAddress bYN,
	--@AuditJCActuals bYN,
	@AuthType bDesc,
	@InsTemplate SMALLINT,
	@ExistingBuild bYN,
	@OCCIPYN bYN,
	@Substantiation bDesc,
	@VendorGroup bGroup,
	@HistoricalBuild bYN,
	@DefltRetn bRate,
	@PrimeYN bYN,
	@ConMethod SMALLINT,
	@CRMNum bDesc,
	@ProjIns VARCHAR(3),
	@ProjSummary bNotes,
	@msg VARCHAR(255)
	
	--SET @Validate = 0
	SELECT VendorGroup FROM PMCO
	SELECT @TaxGroup = ISNULL(HQCO.TaxGroup,1), @CustGroup=ISNULL(HQCO.CustGroup,1), @VendorGroup = ISNULL(HQCO.VendorGroup,1), @OurFirm=PMCO.OurFirm
		FROM HQCO 
			JOIN PMCO ON HQCo=PMCo
		WHERE HQCo=@Company 

	SET @DefltRetn= 0.1
	--SELECT @OurFirm = OurFirm FROM PMCO WHERE PMCo = @Company

	SELECT 
		@Contract = Contract, 
		@ProjName = Description, 
		@ProjWorkstream = Workstream, 
		@POC = POC,
		@Customer = Customer,
		@JCDepartment = CONVERT(VARCHAR(30),Department) , 
		@CertPR = CertifiedPRYN,
		@Public = PublicYN,
		--@NTP = NTPYN,
		@ApplyTemplate = Template,
		@ConChannel = ContractChannel,
		@PrevWage = PrevWageYN,
		@GovntYN = GovntOccOwnYN,
		@GovntOwnYN = GovntOwnYN,
		@WorkRecYN = WorkRecYN,
		@RiskProfile = RiskProfile,

		/*Set Building Address*/
		@BAdd1 = ProjAdd1,
		@BAdd2 = ProjAdd2, 
		@BCity = ProjCity,
		@BState = ProjState,
		@BZip = ProjZip,

		/*Set Project Mail Address*/
		@ProjAddress1 = CASE WHEN SameMailAddYN = 'Y' THEN ProjAdd1 ELSE '' END, 
		@ProjAddress2 = CASE WHEN SameMailAddYN = 'Y' THEN ProjAdd2 ELSE '' END, 
		@ProjCity = CASE WHEN SameMailAddYN = 'Y' THEN ProjCity ELSE '' END,
		@ProjState = CASE WHEN SameMailAddYN = 'Y' THEN ProjState ELSE '' END,
		@ProjZip = CASE WHEN SameMailAddYN = 'Y' THEN ProjZip ELSE '' END,
		@ProjCountry = ProjCountry,

		/*Set Project Ship Address*/
		@ProjShipAddress1 = CASE WHEN SameShipAddYN = 'Y' THEN ProjAdd1 ELSE '' END, 
		@ProjShipAddress2 = CASE WHEN SameShipAddYN = 'Y' THEN ProjAdd2 ELSE '' END, 
		@ProjShipCity = CASE WHEN SameShipAddYN = 'Y' THEN ProjCity ELSE '' END,
		@ProjShipState = CASE WHEN SameShipAddYN = 'Y' THEN ProjState ELSE '' END,
		@ProjShipZip = CASE WHEN SameShipAddYN = 'Y' THEN ProjZip ELSE '' END,
		@ProjShipCountry = ProjCountry,

		@PRState = ProjState,
		@NCustName = NCustName,
		@NCustAdd1 = NCustAdd1,
		@NCustAdd2 = NCustAdd2,
		@NCustCity = NCustCity,
		@NCustState = NCustState, 
		@NCustZip = NCustZip,
		@NCustContactName = NCustContact,
		@NCustEmail = NCustEmail,
		@NCustPhone = NCustPhone,
		@NCustFax = NCustFax,
		@NCustCountry = 'US',
		@UseMailAddress = SameMailAddYN,
		@UseShipAddress = SameShipAddYN,
		@AuthType = AuthorizType,
		--@AuditJCActuals = AuditedJCActualsYN,
		--populate @InsTemplate using the following logic.  This is hard coded and will rely on those insurance templates existing.
		@InsTemplate = CASE 
			WHEN ProjState <> 'WA' AND ProjIns IS NULL THEN 2 
			WHEN ProjState = 'WA' AND ProjIns IS NULL THEN 1 
			WHEN ProjIns IS NOT NULL THEN 3
				ELSE '' END,
		@ExistingBuild = ExistingBuildingYN
		, @OCCIPYN = OCCIPCCIPYN
		,@Substantiation = Substantiation
		, @HistoricalBuild = HistoricalBuildingYN
		, @PrimeYN = PrimeYN
		, @ConMethod = ConMethod
		, @CRMNum = CRMNum
		, @ProjIns = ProjIns
		, @ProjSummary = Scope
		FROM udPIF 
		WHERE Co = @Company AND RequestNum = @JRNum AND UserName = @VPUserName 
	
	--SELECT @VendorGroup = VendorGroup FROM HQCO WHERE HQCo = @Company

	DECLARE @MissingField NVARCHAR(255)


	--Validation variable set
		--Validate Missing Fields
	IF (@ProjName IS NULL) 
	BEGIN 
		SET @MissingField = '4'
	END 

	IF (@POC IS NULL)
	BEGIN
		SET @MissingField = CASE WHEN @MissingField IS NULL THEN '5' ELSE @MissingField + ', 5' END
	END

	IF (@ProjWorkstream IS NULL)
	BEGIN
		SET @MissingField = CASE WHEN @MissingField IS NULL THEN '6' ELSE @MissingField + ', 6' END
	END

	IF (@BAdd1 IS NULL OR @BCity IS NULL OR @BState IS NULL OR @BZip IS NULL)
	BEGIN
		SET @MissingField = CASE WHEN @MissingField IS NULL THEN '7' ELSE @MissingField + ', 7' END
	END

	IF (@ConChannel IS NULL)
	BEGIN
		SET @MissingField = CASE WHEN @MissingField IS NULL THEN '8' ELSE @MissingField + ', 8' END
	END
	IF (@AuthType IS NULL)
	BEGIN
		SET @MissingField = CASE WHEN @MissingField IS NULL THEN '9' ELSE @MissingField + ', 9' END
	END
	IF NOT EXISTS (SELECT TOP 1 1 FROM dbo.udPIFOffering WHERE ReqNum = @JRNum AND UserName=@VPUserName AND Co=@Company)
	BEGIN
		SET @MissingField = CASE WHEN @MissingField IS NULL THEN '10' ELSE @MissingField + ', 10' END
	END
	IF (@Contract IS NULL OR @Contract = '') AND (@Customer IS NULL OR @Customer = '') AND (@NCustName IS NULL OR @NCustAdd1 IS NULL OR @NCustCity IS NULL)
	BEGIN
		SET @MissingField = CASE WHEN @MissingField IS NULL THEN '11' ELSE @MissingField + ', 11' END
	END
	IF (@Contract IS NULL) AND (@JCDepartment IS NULL)
	BEGIN
		SET @MissingField = CASE WHEN @MissingField IS NULL THEN '12' ELSE @MissingField + ', 12' END
	END
	IF @JRNum NOT IN (SELECT RequestNum FROM dbo.udPIF)
	BEGIN
		SET @ReturnMessage = 'Project Request not ready.  Please save before submitting.'
		SET @rcode = 1
		GOTO spexit
	END
	--DECLARE @ReturnMessage VARCHAR(255)
	--, @MissingField NVARCHAR(255), @msg VARCHAR(255)
	--SET @MissingField = '4,5,6'
	IF @MissingField IS NOT NULL --AND @MissingField <> ''
	BEGIN
		SET @msg = CASE WHEN @MissingField LIKE '%4%' THEN 'Project Name, ' ELSE '' END
		SET @msg = CASE WHEN @MissingField LIKE '%5%' THEN @msg + 'POC, ' ELSE @msg END
		SET @msg = CASE WHEN @MissingField LIKE '%6%' THEN @msg + 'Workstream, ' ELSE @msg END
		SET @msg = CASE WHEN @MissingField LIKE '%7%' THEN @msg + 'Address, ' ELSE @msg END
		SET @msg = CASE WHEN @MissingField LIKE '%8%' THEN @msg + 'Contract Channel, ' ELSE @msg END
		SET @msg = CASE WHEN @MissingField LIKE '%9%' THEN @msg + 'Authorization Type, ' ELSE @msg END
		SET @msg = CASE WHEN @MissingField LIKE '%10%' THEN @msg + 'Project Scope, ' ELSE @msg END
		SET @msg = CASE WHEN @MissingField LIKE '%11%' THEN @msg + 'Customer, ' ELSE @msg END
		SET @msg = CASE WHEN @MissingField LIKE '%12%' THEN @msg + 'Department, ' ELSE @msg END
		
		SELECT @ReturnMessage = @msg + ' is missing.  Please correct and try again.'
		
		IF @MissingField LIKE '%12%'
		BEGIN
			SET @ReturnMessage = ISNULL(@ReturnMessage,'') + 'Unable to process request.  Please supply an Existing Contract Number or a Department.'
		END
		IF @MissingField LIKE '%11%' AND (@NCustName IS NULL OR @NCustAdd1 IS NULL OR @NCustCity IS NULL OR @NCustZip IS NULL)
		BEGIN
			SET @ReturnMessage = ISNULL(@ReturnMessage, '')+'Unable to process request. No Existing Contract or Customer Selected and New Customer fields are blank.'
		END
		ELSE
		BEGIN
			IF @MissingField IS NULL OR @MissingField=''
			BEGIN
				SET @rcode=0
				GOTO beginprocessing
			END
		END
		SET @rcode = 1
		--SELECT @msg
		--SELECT @ReturnMessage
		GOTO spexit
	END
	--BEGIN 2ND VALIDATE
	--IF (@Contract IS NULL OR @Contract = '') AND (@Customer IS NULL OR @Customer = '') AND (@NCustName IS NULL OR @NCustAdd1 IS NULL OR @NCustPhone IS NULL)
	--BEGIN
	--	SET @Validate = 3
	--END

	--IF (@Contract IS NULL) AND (@JCDepartment IS NULL)
	--BEGIN
	--	SET @Validate = 2
	--END

	--IF @JRNum NOT IN (SELECT RequestNum FROM dbo.udPIF)
	--BEGIN
	--	SET @Validate = 1
	--END

	
	--IF @Validate = 2
	--BEGIN
	--	SELECT @ReturnMessage = 'Unable to process request.  Please supply an Existing Contract Number or a Department.', @rcode = 1
	--	GOTO spexit
	--END
	--IF @Validate = 1
	--BEGIN
	--	SELECT @ReturnMessage = 'Unable to process request. Please save the record and try again', @rcode=1
	--	GOTO spexit
	--END
	beginprocessing:
	--Declare Send mail variables.
	DECLARE @To VARCHAR(100), @subject VARCHAR(255), @tableHTML NVARCHAR(MAX), @MessageImportance VARCHAR(6) = NULL
		--, @IncludeCustomerMessage BIT

	DECLARE @VPUserEmail VARCHAR(128), @POCEmail VARCHAR(128)
		SELECT @VPUserEmail= ISNULL(EMail, 'erptest@mckinstry.com') FROM DDUP WHERE VPUserName = @VPUserName
		SELECT @POCEmail = ISNULL(pm.Email,'')
			FROM dbo.JCMP pm
				JOIN dbo.udPIF pif ON pif.Co = pm.JCCo AND pif.POC = pm.ProjectMgr
			WHERE pif.Co=@Company AND pif.RequestNum = @JRNum AND pif.UserName = @VPUserName
		
		--SWITCH COMMENT ON GO LIVE
		--SET @To = @VPUserEmail+';'+@POCEmail+'; erptest@mckinstry.com'
		SET @To = @VPUserEmail+'; erptest@mckinstry.com'

	IF EXISTS(SELECT 1 FROM udPIF r WHERE r.RequestNum = @JRNum AND  r.UserName = @VPUserName AND Co = @Company AND r.Project IS NULL)
		BEGIN
			IF EXISTS(SELECT 1 FROM udPIF r WHERE r.RequestNum = @JRNum AND r.UserName = @VPUserName AND Co = @Company AND r.Contract IS NULL)
			BEGIN--Create Contract and Project
				
				SET @NewProjectNum = (SELECT NewProjectID FROM [Viewpoint].[dbo].[fnMckNewProjectID](@Company))
				SET @NewProjectNum = CASE WHEN LEN(@NewProjectNum) = 5 THEN ' '+CONVERT(VARCHAR(30),@NewProjectNum) ELSE @NewProjectNum END
				BEGIN TRY
					BEGIN TRAN mckPIFTempJob
					INSERT INTO mckPIFJCJobTemp(JCCo, Job)
					VALUES (@Company, @NewProjectNum)
					COMMIT TRAN
				END TRY
				BEGIN CATCH
					SELECT @rcode=1, @ReturnMessage='ERROR: Unable to get new Project ID'
					ROLLBACK TRAN mckPIFTempJob
					GOTO spexit
				END CATCH
				
				
				
				SET @NewProjectNum = CONVERT(VARCHAR(30),@NewProjectNum) + '-'
				
					--Create Contract
				
				DECLARE @NewContractNum VARCHAR(30)
				,@Month bMonth
				SET @NewContractNum = @NewProjectNum
				SET @NewProjectNum = @NewProjectNum+'001'
				
				SELECT @Month = dbo.vfFirstDayOfMonth(GETDATE())
				
					BEGIN TRY
						BEGIN TRAN JCCMInsert
							INSERT INTO bJCCM (JCCo ,Contract, CustGroup, Customer, Description, Department, 
									ContractStatus, StartMonth, RecType, TaxInterface, RetainagePCT,
									DefaultBillType, TaxGroup, udPOC, udConChannel, PayTerms, udSubstantiation
									, udPrimeYN, udConMethod)
							VALUES(@Company ,@NewContractNum, @CustGroup, @Customer, @ProjName, @JCDepartment, 
									0, @Month, 1,'N',@DefltRetn,
									'B',@TaxGroup, @POC, @ConChannel,'30', @Substantiation
									, @PrimeYN, @ConMethod)
						COMMIT TRAN JCCMInsert
						BEGIN TRAN JCJMInsert
							INSERT INTO JCJM(JCCo,Job, Description, Contract, ProjectMgr, LiabTemplate, 
								PRStateCode,udProjWrkstrm, OurFirm, Certified, udPrevailWage, udGovntYN, udGovtOwnYN, udWorkRecYN,
								MailAddress, MailAddress2, MailCity, MailState, MailZip, MailCountry,
								ShipAddress, ShipAddress2, ShipCity, ShipState, ShipZip, ShipCountry, LockPhases, Notes, RateTemplate
								, InsTemplate, udExistingBuildYN, udRiskProfile 
								--, udOCCIPCCIPYN
								, udAuthType, VendorGroup, TaxGroup, udCRMNum, udProjIns, udProjSummary)
							VALUES (@Company,@NewProjectNum,@ProjName,@NewContractNum,@POC,1,
								@PRState ,@ProjWorkstream,@OurFirm, @CertPR,@PrevWage, @GovntYN, @GovntOwnYN, @WorkRecYN,
								@ProjAddress1, @ProjAddress2, @ProjCity, @ProjState, @ProjZip, @ProjCountry,
								@ProjShipAddress1, @ProjShipAddress2, @ProjShipCity, @ProjShipState, @ProjShipZip, @ProjShipCountry, 'Y', 'Project Created on '+CONVERT(VARCHAR(11),GETDATE())+' via the Project Initiation form.', '1'
								, @InsTemplate, @ExistingBuild, @RiskProfile
								--, @OCCIPYN
								, @AuthType, @VendorGroup, @TaxGroup, @CRMNum,@ProjIns, @ProjSummary)
						COMMIT TRAN JCJMInsert
					END TRY
					BEGIN CATCH
						SELECT @rcode=1,@ReturnMessage = 'ERROR: Unable to create Contract/Job.'
						ROLLBACK TRAN JCCMInsert;
						ROLLBACK TRAN JCJMInsert;
						ROLLBACK TRAN mckPIFTempJob;
						GOTO spexit	
					END CATCH



				--DELETE THE TEMP JOB NUMBER
				DELETE FROM mckPIFJCJobTemp
				WHERE JCCo = @Company AND Job LIKE LEFT(@NewProjectNum,6)

				--Insert Building Info
				INSERT INTO budProjectBuildings(Co, Project, BuildingNum, HistoricalYN)
				VALUES (@Company, @NewProjectNum, 1,@HistoricalBuild)

				UPDATE budProjectBuildings
				SET Add1 = @BAdd1, Add2 = @BAdd2, City = @BCity, State = @BState, Zip = @BZip
				WHERE Co = @Company AND Project = @NewProjectNum AND BuildingNum = 1

				--Insert McK Offering records to ProjOffering

				INSERT INTO dbo.udProjOffering
					( Co 
					, Project 
					, Amount 
					, Offering 
					, ProjHours 
					, ProjStart 
					, Taxable )
				SELECT @Company
					, @NewProjectNum
					, Amount
					, Offering
					, ProjHours
					, ProjStart
					, 'N' 
					FROM dbo.udPIFOffering
					WHERE Co = @Company AND ReqNum = @JRNum AND UserName = @VPUserName
				
				/**/
				--CREATE NEW 'ON HOLD' CUSTOMER
				IF (@Customer IS NULL AND @Contract IS NULL)
				BEGIN
					
					SET @To = 'erptest@mckinstry.com'  --COMMENT OUT AFTER GO LIVE
					SET @subject = 'New Customer requested from PIF.'
					SET @tableHTML = 
						N'<H3>' + @subject + ' Please review and update when ready.</H3>' +
						N'<font size="-2">' +
						N'<table border="1">' +
						N'<tr bgcolor=silver>' +
						N'<th>Co</th>' +
						N'<th>New Customer Name</th>' +
						N'<th>New Customer Contact Name</th>' +
						N'<th>New Customer Address 1</th>' +
						N'<th>New Customer Address 2</th>' +
						N'<th>New Customer City</th>' +
						N'<th>New Customer State</th>' +
						N'<th>New Customer Zip</th>' +
						N'<th>New Customer Phone</th>' +
						N'<th>New Customer Fax</th>' +
						N'<th>New Customer Email</th>' +
							N'</tr>' +
						CAST 
						( 
							( 
								SELECT
									td = COALESCE(@Company,' '), ''
								,	td = COALESCE(p.NCustName,' '), ''
								,	td = COALESCE(p.NCustContact,' '), ''
								,	td = COALESCE(p.NCustAdd1,' '), ''
								,	td = COALESCE(p.NCustAdd2,' '), ''
								,	td = COALESCE(p.NCustCity,' '), ''
								,	td = COALESCE(p.NCustState,' '), ''
								,	td = COALESCE(p.NCustZip,' '), ''
								,	td = COALESCE(p.NCustPhone,' '), ''
								,	td = COALESCE(p.NCustFax,' '), ''
								,	td = COALESCE(p.NCustEmail,' '), ''
								FROM 
									dbo.udPIF p
								WHERE p.Co = @Company AND p.UserName = @VPUserName AND p.RequestNum = @JRNum 
								ORDER BY 2	
								FOR XML PATH('tr'), TYPE 
							) AS NVARCHAR(MAX) ) + N'</table>' + N'<br/><br/>'
							SELECT @tableHTML = @tableHTML + '<i>'+ISNULL(@msg,'')+'</i>'

							SET @MessageImportance = 'Normal'

					EXEC msdb.dbo.sp_send_dbmail 
						@profile_name = 'Viewpoint',
						@recipients = @To,
						@subject = @subject,
						@body = @tableHTML,
						@body_format = 'HTML',
						@importance = @MessageImportance

					/*Commented Out to exclude Auto Customer Create.  Replaced with Send mail(above).*/
					--SET @IncludeCustomerMessage = 1

					--SELECT 
					--	@NewCustomerNum = MAX(Customer)+1, 
					--	@ARCustSortName = LEFT(REPLACE(@NCustName,' ', ''),15-LEN(CONVERT(VARCHAR(30),@NewCustomerNum))) + CONVERT(VARCHAR(30),@NewCustomerNum)
					--	FROM ARCM
					--SELECT @ARCustSortName = LEFT(REPLACE(@NCustName,' ', ''),9)+CONVERT(VARCHAR(30),@NewCustomerNum) 
				
				
					--SELECT LEFT(REPLACE(Name,' ', ''),9)+CONVERT(VARCHAR(30),Customer) FROM ARCM

						--INSERT INTO ARCM(CustGroup, Customer, Name,SortName, 
						--	Address, Address2, City, State, Zip, Country, 
						--	Contact, EMail, Phone, Fax, 
						--	BillAddress, BillAddress2, BillCity, BillState, BillZip, BillCountry,
						--	Status, FCType, StmtType, TempYN, SelPurge, StmntPrint)
						--VALUES(@ARCustGroup,@NewCustomerNum, @NCustName,@ARCustSortName, 
						--	@NCustAdd1, @NCustAdd2, @NCustCity, @NCustState, @NCustZip, @NCustCountry, 
						--	@NCustName, @NCustEmail, @NCustPhone, @NCustFax, 
						--	@NCustAdd1, @NCustAdd2, @NCustCity, @NCustState, @NCustZip, @NCustCountry,
						--	'H', 'N', 'O', 'N', 'N', 'N')

						--UPDATE budPIF 
						--SET Customer = @NewCustomerNum
						--WHERE RequestNum = @JRNum 
						--AND Co = @Company
						--AND UserName = @VPUserName

						--UPDATE dbo.JCCM
						--SET Customer = @NewCustomerNum
						--WHERE @Company = JCCo AND @NewContractNum = Contract
				
				END
					

					--Apply Phase Template to Project
					
				--SET @ApplyTemplate = ISNULL(@ApplyTemplate,'T0')
				----IF @ApplyTemplate IS NOT NULL
				--BEGIN TRY
				--	BEGIN TRAN TemplateCopy
				--	EXEC dbo.bspPMTemplateCopy @pmco = @Company, -- bCompany
				--		@template = @ApplyTemplate, -- varchar(10)
				--		@project = @NewProjectNum, -- bJob
				--		@msg = @msg OUT -- varchar(255)
				--		--SELECT @msg = @msg
				--	COMMIT TRAN TemplateCopy
				--END TRY
				--BEGIN CATCH
				--	SELECT @rcode=1,@ReturnMessage = ISNULL(@msg,'')+'Failed to apply Phase Template.'
				--	ROLLBACK TRAN TemplateCopy
				--	GOTO spexit
				--END CATCH

				

				

					--Return new job number to form.
				UPDATE budPIF
				SET Project = @NewProjectNum, QueueDate = GETDATE()
				WHERE RequestNum = @JRNum
				AND Co = @Company
				AND UserName = @VPUserName
								
				SELECT @ReturnMessage = --'Thank you for your request.'
									'New Contract: "'+ @NewContractNum+ '" and Project: "' +@NewProjectNum 
									+'" have been created. ', @rcode = 0
				GOTO sendmessage
			END
			ELSE
			BEGIN --Create only Project
				
				SET @NewProjectNum = LEFT(@Contract,7)
				SET @NewContractNum = NULL
				--DECLARE @ProjSuffix VARCHAR(3)
				--DECLARE @Contract VARCHAR(30)
				--SET @Contract = '654321-002'
				SELECT @JobStatus = ContractStatus FROM JCCM WHERE Contract = @Contract

				IF EXISTS(SELECT * FROM JCJM WHERE Job LIKE @NewProjectNum+'%')
				BEGIN
					SET @ProjSuffix = RIGHT((SELECT MAX(Project) FROM JCJMPM WHERE Contract LIKE LEFT(@Contract, 6)+'%'),3) 
				
					SET @ProjSuffix = @ProjSuffix + 1
					SELECT @ProjSuffix = dbo.fnMckFormatWithLeading(@ProjSuffix, '0', 3)
				END
				ELSE
				BEGIN
					SET @ProjSuffix = '001'
				END
				
				SET @NewProjectNum = @NewProjectNum + @ProjSuffix
					--Create Project
				BEGIN TRY
					BEGIN TRAN JCJMInsertOnly
					INSERT INTO JCJM(	JCCo, Job, Description,	Contract,	ProjectMgr,		LiabTemplate,	PRStateCode,	udProjWrkstrm,		OurFirm,	JobStatus,		Certified,	udPrevailWage,	udGovntYN, udGovtOwnYN, udWorkRecYN,
							MailAddress,	MailAddress2,	MailCity,	MailState,		MailZip,	MailCountry 
							, ShipAddress, ShipAddress2, ShipCity, ShipState, ShipZip, ShipCountry, LockPhases, Notes, RateTemplate
							, InsTemplate, udExistingBuildYN, udRiskProfile, udOCCIPCCIPYN, udAuthType, VendorGroup, TaxGroup, udCRMNum, udProjIns, udProjSummary)
					VALUES (			@Company,	@NewProjectNum,	@ProjName,		@Contract,	@POC,			1,				@PRState,		@ProjWorkstream,	@OurFirm,	@JobStatus,		@CertPR,	@PrevWage,		@GovntYN,	@GovntOwnYN,@WorkRecYN,
							@ProjAddress1,	@ProjAddress2,	@ProjCity,	@ProjState,		@ProjZip,	@ProjCountry
							, @ProjShipAddress1, @ProjShipAddress2, @ProjShipCity, @ProjShipState, @ProjShipZip, @ProjShipCountry, 'Y', 'Project Created on '+CONVERT(VARCHAR(11),GETDATE())+' via the Project Initiation form.', '1'
							, @InsTemplate, @ExistingBuild, @RiskProfile, @OCCIPYN, @AuthType, @VendorGroup, @TaxGroup, @CRMNum, @ProjIns,@ProjSummary)
					COMMIT TRAN JCJMInsertOnly
				END TRY
				BEGIN CATCH
					SELECT @rcode =1, @ReturnMessage = 'ERROR: Unable to create Job.'
					ROLLBACK TRAN JCJMInsertOnly
					GOTO spexit
				END CATCH
								
				--Insert Building Info
				INSERT INTO budProjectBuildings(Co, Project, BuildingNum, HistoricalYN)
				VALUES (@Company, @NewProjectNum, 1, @HistoricalBuild)
				
				UPDATE budProjectBuildings
				SET Add1 = @BAdd1, Add2 = @BAdd2, City = @BCity, State = @BState, Zip = @BZip
				WHERE Co = @Company AND Project = @NewProjectNum AND BuildingNum = 1
					
				
				


				INSERT INTO dbo.udProjOffering
					( Co 
					, Project 
					, Amount 
					, Offering 
					, ProjHours 
					, ProjStart 
					, Taxable )
				SELECT @Company
					, @NewProjectNum
					, Amount
					, Offering
					, ProjHours
					, ProjStart
					, 'N' 
					FROM dbo.udPIFOffering
					WHERE Co = @Company AND ReqNum = @JRNum AND UserName = @VPUserName


					--Return new job number to form.
				UPDATE budPIF
				SET Project = @NewProjectNum, QueueDate = GETDATE()
				WHERE RequestNum = @JRNum
					AND Co = @Company
					AND UserName = @VPUserName
								
				SELECT @ReturnMessage = --'Thank you for your request.'
						'Project: '+ @NewProjectNum 
						+ ' has been created. and assigned to Contract '
						+ @Contract+'". '
						, @rcode = 0



				--Apply Phase Template to Project	
				--SET @ApplyTemplate = ISNULL(@ApplyTemplate,'T0')
				----IF @ApplyTemplate IS NOT NULL
				--BEGIN TRY
				--	BEGIN TRAN TemplateCopy2
				--	EXEC dbo.bspPMTemplateCopy @pmco = @Company, -- bCompany
				--		@template = @ApplyTemplate, -- varchar(10)
				--		@project = @NewProjectNum, -- bJob
				--		@msg = @msg OUT -- varchar(255)
				--		--SELECT @msg = @msg
				--	COMMIT TRAN TemplateCopy2
				--END TRY
				--BEGIN CATCH
				--	SELECT @rcode=1,@ReturnMessage = ISNULL(@msg,'')+'Failed to apply Phase Template.'
				--	ROLLBACK TRAN TemplateCopy2
				--	GOTO spexit
				--END CATCH


				GOTO sendmessage
			END
		END
		ELSE
		BEGIN
			SELECT @ReturnMessage = 'This request has already been submitted.' 
					--+ 'Project ' 
					--+ r.Project 
					--+ ' has already been created'
					, @rcode = 1
			--FROM udPIF r WHERE @JRNum = r.RequestNum
			goto spexit
		END	
	
	sendmessage:
	BEGIN
		--Send alert message to appropriate groups for new project setup checks
		

		IF @ProjWorkstream = 'HC'
		BEGIN
			SET @MessageImportance = 'High'
		END
		ELSE 
		BEGIN
			SET @MessageImportance = 'Normal'
		END

		
		SELECT @subject = CASE WHEN @NewContractNum IS NOT NULL 
					THEN 'New Contract and Project: ' + @NewContractNum +' & '+ @NewProjectNum + ' have been created.'
					ELSE 'New Project: '+ @NewProjectNum + ' has been created.' END
		SET @tableHTML =
			N'<H3>' + @subject + ' Please review and update when ready.</H3>' +
			N'<font size="-2">' +
			N'<table border="1">' +
			N'<tr bgcolor=silver>' +
			N'<th>Co</th>' +
			N'<th>Contract</th>' +
			N'<th>Project</th>' +
			N'<th>Description</th>' +
			N'<th>POC Name</th>' +
				N'</tr>' +
			CAST 
			( 
				( 
					SELECT
						td = COALESCE(@Company,' '), ''
					,	td = COALESCE(j.Contract,' '), ''
					,	td = COALESCE(j.Job,' '), ''
					,	td = COALESCE(j.Description,' '), ''
					,	td = COALESCE(p.Name,' '), ''
					FROM 
						JCJM j 
						INNER JOIN JCCM c ON c.JCCo = j.JCCo AND c.Contract = j.Contract
						INNER JOIN JCMP p ON p.JCCo = c.JCCo AND c.udPOC = p.ProjectMgr
					WHERE j.JCCo = @Company AND j.Job = @NewProjectNum 
					ORDER BY 2	
					FOR XML PATH('tr'), TYPE 
				) AS NVARCHAR(MAX) ) + N'</table>' + N'<br/><br/>'
				SELECT @tableHTML = @tableHTML + '<i>'+ISNULL(@msg,'')+'</i>'

				
		EXEC msdb.dbo.sp_send_dbmail 
			@profile_name = 'Viewpoint',
			@recipients = @To,
			@subject = @subject,
			@body = @tableHTML,
			@body_format = 'HTML',
			@importance = @MessageImportance

		GOTO spexit
		--end message alert

	END

	spexit:
	BEGIN
		
		return @rcode
END
	end


GO
GRANT EXECUTE ON  [dbo].[mckspJobCreate] TO [public]
GO
