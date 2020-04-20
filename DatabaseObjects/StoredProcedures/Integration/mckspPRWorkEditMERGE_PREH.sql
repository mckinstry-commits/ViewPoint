USE [Viewpoint]
GO
/****** Object:  StoredProcedure [dbo].[mckspPRWorkEditMERGE_PREH]    Script Date: 11/19/2014 2:59:58 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 10/14/2014
-- Description:	MERGE statement to update/insert PREH records from PRWorkEdit.
-- =============================================
ALTER PROCEDURE [dbo].[mckspPRWorkEditMERGE_PREH] 
	-- Add the parameters for the stored procedure here
	@ImportID VARCHAR(10) = '', 
	@ReturnMessage varchar(8000) = '' OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


	-- Insert statements for procedure here
	--IF EXISTS(
	--		SELECT TOP 1 1 
	--		FROM dbo.mvwPREmpWorkEditValidation we
	--		WHERE ImportID = @ImportID
	--			AND we.PRDept IS NOT NULL AND we.PRGroup IS NOT NULL AND 
	--	)

	DECLARE @MergeOutput TABLE (ActionType NVARCHAR(10), PRCo bCompany, Employee bEmployee)
	DECLARE @ValErrors TABLE (ImportID VARCHAR(10), PRCo bCompany, Employee bEmployee, ErrorMessage VARCHAR(1000)) 
	DECLARE @rowcount BIGINT, @rcode INT = 0


	BEGIN TRY



		--WITH we AS
		--(
		--	SELECT *
		--	FROM dbo.mvwPREmpWorkEditValidation
		--	WHERE ApprovedYN = 'Y' AND ImportID = @ImportID AND PRCo IS NOT NULL
		--	AND PRDept IS NOT NULL AND PRGroup IS NOT NULL AND Craft IS NOT NULL AND Class IS NOT NULL AND InsCode IS NOT NULL
		--)
		--MERGE INTO dbo.PREH e
		--USING we 
		--ON e.Employee = we.Employee 
		----WHEN MATCHING EMPLOYEE - No invalid; Dept, PRGroup, Craft, Class, InsCode
		----UPDATE ALL WITH IMPORTED VALUE UNLESS NULL, THEN ACCEPT THE EXISTING VALUE
		--WHEN MATCHED --AND we.ImportID = @ImportID AND we.ApprovedYN = 'Y'
		--	--AND we.PRDept IS NOT NULL AND we.PRGroup IS NOT NULL AND we.Craft IS NOT NULL AND we.Class IS NOT NULL AND we.InsCode IS NOT NULL
		--	AND e.PRCo = we.PRCo
		--THEN
		--	UPDATE 
		--		SET e.ActiveYN = ISNULL(we.ActiveYN,e.ActiveYN)
		--			, e.[AUAccountNumber] =ISNULL(we.[AUAccountNumber], e.[AUAccountNumber]),
		--			e.[AUBSB] =ISNULL(we.[AUBSB], e.[AUBSB]),
		--			e.[AUEFTYN] =ISNULL(we.[AUEFTYN], e.[AUEFTYN]),
		--			e.[AUReference] =ISNULL(we.[AUReference], e.[AUReference]),
		--			e.[AcctType] =ISNULL(we.[AcctType], e.[AcctType]),
		--			e.[Address] =ISNULL(we.[Address], e.[Address]),
		--			e.[Address2] =ISNULL(we.[Address2], e.[Address2]),
		--			e.[ArrearsActiveYN] =ISNULL(we.[ArrearsActiveYN], e.[ArrearsActiveYN]),
		--			e.[AuditYN] =ISNULL(we.[AuditYN], e.[AuditYN]),
		--			e.[BankAcct] =ISNULL(we.[BankAcct], e.[BankAcct]),
		--			e.[BirthDate] =ISNULL(we.[BirthDate], e.[BirthDate]),
		--			e.[CPPQPPExempt] =ISNULL(we.[CPPQPPExempt], e.[CPPQPPExempt]),
		--			e.[CSAllocMethod] =ISNULL(we.[CSAllocMethod], e.[CSAllocMethod]),
		--			e.[CSGarnGroup] =ISNULL(we.[CSGarnGroup], e.[CSGarnGroup]),
		--			e.[CSLimit] =ISNULL(we.[CSLimit], e.[CSLimit]),
		--			e.[CatStatus] =ISNULL(we.[CatStatus], e.[CatStatus]),
		--			e.[CellPhone] =ISNULL(we.[CellPhone], e.[CellPhone]),
		--			e.[CertYN] =ISNULL(we.[CertYN], e.[CertYN]),
		--			e.[ChkSort] =ISNULL(we.[ChkSort], e.[ChkSort]),
		--			e.[City] = ISNULL(we.[City], e.[City]),
		--			e.[Class] = we.[Class],
		--			e.[Country] =ISNULL(we.[Country], e.[Country]),
		--			e.[Craft] = we.[Craft],
		--			e.[Crew] =ISNULL(we.[Crew], e.[Crew]),
		--			e.[DDPaySeq] =ISNULL(we.[DDPaySeq], e.[DDPaySeq]),
		--			e.[DefaultPaySeq] =ISNULL(we.[DefaultPaySeq], e.[DefaultPaySeq]),
		--			e.[DirDeposit] =ISNULL(we.[DirDeposit], e.[DirDeposit]),
		--			e.[EIExempt] =ISNULL(we.[EIExempt], e.[EIExempt]),
		--			e.[EMCo] =ISNULL(we.[EMCo], e.[EMCo]),
		--			e.[EMFixedRate] =ISNULL(we.[EMFixedRate], e.[EMFixedRate]),
		--			e.[EMGroup] =ISNULL(we.[EMGroup], e.[EMGroup]),
		--			e.[EarnCode] =ISNULL(we.[EarnCode], e.[EarnCode]),
		--			e.[Email] =ISNULL(we.[Email], e.[Email]),
		--			--e.[Employee] = e.[Employee],
		--			e.[Equipment] =ISNULL(we.[Equipment], e.[Equipment]),
		--			e.[F1Amt] =ISNULL(we.[F1Amt], e.[F1Amt]),
		--			e.[FirstName] =ISNULL(we.[FirstName], e.[FirstName]),
		--			e.[GLCo] =ISNULL(we.[GLCo], e.[GLCo]),
		--			e.[HDAmt] =ISNULL(we.[HDAmt], e.[HDAmt]),
		--			e.[HireDate] =ISNULL(we.[HireDate], e.[HireDate]),
		--			e.[HrlyRate] =ISNULL(we.[HrlyRate], e.[HrlyRate]),
		--			--e.[ImportID] =ISNULL(we.[ImportID], e.[ImportID]),
		--			--e.[ImportSequence] =ISNULL(we.[ImportSequence], e.[ImportSequence]),
		--			e.[InsCode] = we.[InsCode],
		--			e.[InsState] =ISNULL(we.[InsState], e.[InsState]),
		--			e.[JCCo] =ISNULL(we.[JCCo], e.[JCCo]),
		--			e.[JCFixedRate] =ISNULL(we.[JCFixedRate], e.[JCFixedRate]),
		--			e.[Job] =ISNULL(we.[Job], e.[Job]),
		--			e.[LCFStock] =ISNULL(we.[LCFStock], e.[LCFStock]),
		--			e.[LCPStock] =ISNULL(we.[LCPStock], e.[LCPStock]),
		--			e.[LastName] =ISNULL(we.[LastName], e.[LastName]),
		--			e.[LastUpdated] =ISNULL(we.[LastUpdated], GETDATE()),
		--			e.[LocalCode] =ISNULL(we.[LocalCode], e.[LocalCode]),
		--			e.[MidName] =ISNULL(we.[MidName], e.[MidName]),
		--			e.[NAICS] =ISNULL(we.[NAICS], e.[NAICS]),
		--			e.[NewHireActEndDate] =ISNULL(we.[NewHireActEndDate], e.[NewHireActEndDate]),
		--			e.[NewHireActStartDate] =ISNULL(we.[NewHireActStartDate], e.[NewHireActStartDate]),
		--			e.[NonResAlienYN] =ISNULL(we.[NonResAlienYN], e.[NonResAlienYN]),
		--			e.[OTOpt] =ISNULL(we.[OTOpt], e.[OTOpt]),
		--			e.[OTSched] =ISNULL(we.[OTSched], e.[OTSched]),
		--			e.[OccupCat] =ISNULL(we.[OccupCat], e.[OccupCat]),
		--			e.[PPIPExempt] =ISNULL(we.[PPIPExempt], e.[PPIPExempt]),
		--			--e.[PRCo] = e.[PRCo],
		--			e.[PRDept] = we.[PRDept],
		--			e.[PRGroup] = we.[PRGroup],
		--			e.[PayMethodDelivery] =ISNULL(we.[PayMethodDelivery], e.[PayMethodDelivery]),
		--			e.[PensionYN] =ISNULL(we.[PensionYN], e.[PensionYN]),
		--			e.[Phone] =ISNULL(we.[Phone], e.[Phone]),
		--			e.[PostToAll] =ISNULL(we.[PostToAll], e.[PostToAll]),
		--			e.[Race] =ISNULL(we.[Race], e.[Race]),
		--			e.[RecentRehireDate] =ISNULL(we.[RecentRehireDate], e.[RecentRehireDate]),
		--			e.[RecentSeparationDate] =ISNULL(we.[RecentSeparationDate], e.[RecentSeparationDate]),
		--			--e.[RejectReason] =ISNULL(we.[RejectReason], e.[RejectReason]),
		--			e.[RoutingId] =ISNULL(we.[RoutingId], e.[RoutingId]),
		--			e.[SSN] =ISNULL(we.[SSN], e.[SSN]),
		--			e.[SalaryAmt] =ISNULL(we.[SalaryAmt], e.[SalaryAmt]),
		--			e.[SeparationRedundancyRetirement] = ISNULL(we.[SeparationRedundancyRetirement], e.[SeparationRedundancyRetirement]),
		--			e.[Sex] =ISNULL(we.[Sex], e.[Sex]),
		--			e.[Shift] =ISNULL(we.[Shift], e.[Shift]),
		--			e.[SortName] =ISNULL(we.[SortName], e.[SortName]),
		--			e.[State] =ISNULL(we.[State], e.[State]),
		--			e.[Suffix] =ISNULL(we.[Suffix], e.[Suffix]),
		--			e.[TaxState] =ISNULL(we.[TaxState], e.[TaxState]),
		--			e.[TermDate] =ISNULL(we.[TermDate], e.[TermDate]),
		--			e.[TimesheetRevGroup] =ISNULL(we.[TimesheetRevGroup], e.[TimesheetRevGroup]),
		--			e.[TradeSeq] =ISNULL(we.[TradeSeq], e.[TradeSeq]),
		--			e.[UnempState] =ISNULL(we.[UnempState], e.[UnempState]),
		--			e.[UpdatePRAEYN] =ISNULL(we.[UpdatePRAEYN], e.[UpdatePRAEYN]),
		--			e.[UseIns] =ISNULL(we.[UseIns], e.[UseIns]),
		--			e.[UseInsState] =ISNULL(we.[UseInsState], e.[UseInsState]),
		--			e.[UseLocal] =ISNULL(we.[UseLocal], e.[UseLocal]),
		--			e.[UseState] =ISNULL(we.[UseState], e.[UseState]),
		--			e.[UseUnempState] =ISNULL(we.[UseUnempState], e.[UseUnempState]),
		--			e.[WOLocalCode] =ISNULL(we.[WOLocalCode], e.[WOLocalCode]),
		--			e.[WOTaxState] =ISNULL(we.[WOTaxState], e.[WOTaxState]),
		--			e.[YTDSUI] =ISNULL(we.[YTDSUI], e.[YTDSUI]),
		--			e.[Zip] =ISNULL(we.[Zip], e.[Zip]),
		--			e.[ud401kElgDate] =ISNULL(we.[ud401kElgDate], e.[ud401kElgDate]),
		--			e.[ud401kEligYN] =ISNULL(we.[ud401kEligYN], e.[ud401kEligYN]),
		--			e.[udCGCTable] =ISNULL(we.[udCGCTable], e.[udCGCTable]),
		--			e.[udCGCTableID] =ISNULL(we.[udCGCTableID], e.[udCGCTableID]),
		--			e.[udConv] =ISNULL(we.[udConv], e.[udConv]),
		--			e.[udEmpGroup] =ISNULL(we.[udEmpGroup], e.[udEmpGroup]),
		--			e.[udExempt] =ISNULL(we.[udExempt], e.[udExempt]),
		--			e.[udJobTitle] =ISNULL(we.[udJobTitle], e.[udJobTitle]),
		--			e.[udOrigHireDate] =ISNULL(we.[udOrigHireDate], e.[udOrigHireDate]),
		--			e.[udSource] =ISNULL(we.[udSource], e.[udSource]),
		--			e.[Notes] =ISNULL(e.Notes,'') + ISNULL(we.[Notes], ''),
		--			e.[udTermReason] =ISNULL(we.[udTermReason], e.[udTermReason])
		--		--WHEN MATCHED AND we.ImportID = @ImportID AND we.ApprovedYN = 'Y' 
		--		--	AND (we.PRDept IS NULL OR we.PRGroup IS NULL OR we.Craft IS NULL OR we.Class IS NULL OR we.InsCode IS NULL)
		--		--THEN 
		--		--	INSERT INTO @ValErrors (ImportID , PRCo , Employee , ErrorMessage )
					 
				
		--		--NO MATCHING EMPLOYEE RECORD.
		--		--WILL INSERT ANY EMPLOYEE - No invalid; Dept, PRGroup, Craft, Class, InsCode
		--		--No missing SSN, LastName, SortName, Race, Unemployement State, InsState, EarnCode, 
		--		WHEN NOT MATCHED --BY TARGET 
		--			--AND we.ImportID = @ImportID AND we.ApprovedYN = 'Y' 
		--			--AND we.PRDept IS NOT NULL AND we.PRGroup IS NOT NULL AND we.Craft IS NOT NULL AND we.Class IS NOT NULL AND we.InsCode IS NOT NULL
		--			AND we.SSN IS NOT NULL AND we.LastName IS NOT NULL AND we.SortName IS NOT NULL
		--			AND we.PRCo IN (SELECT PRCo FROM PRCO)
		--		THEN
		--			INSERT 
		--				([PRCo],[Employee],
		--				[AUAccountNumber],
		--				[AUBSB],
		--				[AUEFTYN],
		--				[AUReference],
		--				[AcctType],--5
		--				[ActiveYN],
		--				[Address],
		--				[Address2],
		--				[ArrearsActiveYN],
		--				[AuditYN],--10
		--				[BankAcct],
		--				[BirthDate],
		--				[CPPQPPExempt],
		--				[CSAllocMethod],
		--				[CSGarnGroup],--15
		--				[CSLimit],
		--				[CatStatus],
		--				[CellPhone],
		--				[CertYN],
		--				[ChkSort],--20
		--				[City],
		--				[Class],
		--				[Country],
		--				[Craft],
		--				[Crew],--25
		--				[DDPaySeq],
		--				[DefaultPaySeq],
		--				[DirDeposit],
		--				[EIExempt],
		--				[EMCo],--30
		--				[EMFixedRate],
		--				[EMGroup],
		--				[EarnCode],
		--				[Email],
						
		--				[Equipment],--35
		--				[F1Amt],
		--				[FirstName],
		--				[GLCo],
		--				[HDAmt],
		--				[HireDate],--40
		--				[HrlyRate],
		--				[InsCode],
		--				[InsState],
		--				[JCCo],
		--				[JCFixedRate],--45
		--				[Job],
		--				[LCFStock],
		--				[LCPStock],
		--				[LastName],
		--				[LastUpdated],--50
		--				[LocalCode],
		--				[MidName],
		--				[NAICS],
		--				[NewHireActEndDate],
		--				[NewHireActStartDate],--55
		--				[NonResAlienYN],
		--				[OTOpt],
		--				[OTSched],
		--				[OccupCat],
		--				[PPIPExempt],--60
						
		--				[PRDept],
		--				[PRGroup],
		--				[PayMethodDelivery],
		--				[PensionYN],
		--				[Phone],--65
		--				[PostToAll],
		--				[Race],
		--				[RecentRehireDate],
		--				[RecentSeparationDate],
		--				[RoutingId],--70
		--				[SSN],
		--				[SalaryAmt],
		--				[SeparationRedundancyRetirement],
		--				[Sex],
		--				[Shift],--75
		--				[SortName],
		--				[State],
		--				[Suffix],
		--				[TaxState],
		--				[TermDate],--80
		--				[TimesheetRevGroup],
		--				[TradeSeq],
		--				[UnempState],
		--				[UpdatePRAEYN],
		--				[UseIns],--85
		--				[UseInsState],
		--				[UseLocal],
		--				[UseState],
		--				[UseUnempState],
		--				[WOLocalCode],--90
		--				[WOTaxState],
		--				[YTDSUI],
		--				[Zip],
		--				[ud401kElgDate],
		--				[ud401kEligYN],--95
		--				[udCGCTable],
		--				[udCGCTableID],
		--				[udConv],
		--				[udEmpGroup],
		--				[udExempt],--100
		--				[udJobTitle],
		--				[udOrigHireDate],
		--				[udSource],
		--				[Notes],
		--				[udTermReason]--105
		--				)
		--			VALUES(ISNULL(we.[PRCo],1),we.ImportSequence,
		--				we.[AUAccountNumber],
		--				we.[AUBSB],
		--				we.[AUEFTYN],
		--				we.[AUReference],
		--				we.[AcctType],--5
		--				ISNULL(we.[ActiveYN],'N'),
		--				we.[Address],
		--				we.[Address2],
		--				we.[ArrearsActiveYN],
		--				we.[AuditYN],--10
		--				we.[BankAcct],
		--				we.[BirthDate],
		--				we.[CPPQPPExempt],
		--				we.[CSAllocMethod],
		--				we.[CSGarnGroup],--15
		--				we.[CSLimit],
		--				we.[CatStatus],
		--				we.[CellPhone],
		--				we.[CertYN],
		--				we.[ChkSort],--20
		--				we.[City],
		--				we.[Class],
		--				we.[Country],
		--				we.[Craft],
		--				we.[Crew],--25
		--				we.[DDPaySeq],
		--				we.[DefaultPaySeq],
		--				ISNULL(we.[DirDeposit],'N'),
		--				we.[EIExempt],
		--				we.[EMCo],--30
		--				ISNULL(we.[EMFixedRate],0),
		--				we.[EMGroup],
		--				we.[EarnCode],
		--				we.[Email],
		--				--we.[Employee],
						
		--				we.[Equipment], --35
		--				we.[F1Amt],
		--				we.[FirstName],
		--				we.[GLCo],
		--				we.[HDAmt],
		--				we.[HireDate],--40
		--				ISNULL(we.[HrlyRate],0),
		--				we.[InsCode],
		--				we.[InsState],
		--				we.[JCCo],
		--				ISNULL(we.[JCFixedRate], 0),--45
		--				we.[Job],
		--				we.[LCFStock],
		--				we.[LCPStock],
		--				we.[LastName], 
		--				we.[LastUpdated],--50
		--				we.[LocalCode],
		--				we.[MidName],
		--				we.[NAICS],
		--				we.[NewHireActEndDate],
		--				we.[NewHireActStartDate],--55
		--				we.[NonResAlienYN],
		--				we.[OTOpt],
		--				we.[OTSched], 
		--				we.[OccupCat], 
		--				we.[PPIPExempt],--60
						
		--				we.[PRDept],
		--				we.[PRGroup],
		--				we.[PayMethodDelivery],
		--				we.[PensionYN],
		--				we.[Phone],--65
		--				we.[PostToAll],
		--				we.[Race],
		--				we.[RecentRehireDate],
		--				we.[RecentSeparationDate],
		--				we.[RoutingId],--70
		--				we.[SSN],
		--				ISNULL(we.[SalaryAmt],0),
		--				we.[SeparationRedundancyRetirement],
		--				we.[Sex],
		--				we.[Shift],--75
		--				we.[SortName],
		--				we.[State],
		--				we.[Suffix],
		--				we.[TaxState],
		--				we.[TermDate], --80
		--				we.[TimesheetRevGroup],
		--				we.[TradeSeq],
		--				we.[UnempState],
		--				we.[UpdatePRAEYN],
		--				we.[UseIns], --85
		--				we.[UseInsState],
		--				we.[UseLocal],
		--				we.[UseState],
		--				we.[UseUnempState],
		--				we.[WOLocalCode],--90
		--				we.[WOTaxState],
		--				we.[YTDSUI],
		--				we.[Zip],
		--				we.[ud401kElgDate],
		--				we.[ud401kEligYN],--95
		--				we.[udCGCTable],
		--				we.[udCGCTableID],
		--				we.[udConv],
		--				we.[udEmpGroup],
		--				we.[udExempt],--100
		--				we.[udJobTitle],
		--				we.[udOrigHireDate],
		--				we.[udSource],
		--				we.[Notes],
		--				we.[udTermReason]--105
		--				)
		--	OUTPUT
		--		$action,
		--		INSERTED.PRCo,
		--		INSERTED.Employee
		--	INTO @MergeOutput;	
			
		--	SELECT @ReturnMessage = ISNULL(@ReturnMessage,'')+CHAR(13)+'Action: '+o.ActionType + ' was applied to Co: '+CONVERT(VARCHAR(3),o.PRCo) + ' Employee: '+CONVERT(VARCHAR(20),o.Employee) + ' - '+ e.FullName
		--	FROM @MergeOutput o
		--		LEFT JOIN dbo.PREHFullName e ON o.PRCo = e.PRCo AND o.Employee = e.Employee
		DECLARE @ImportType VARCHAR(30), @PRCo bCompany, @Employee bEmployee, @Status CHAR(1), @msg VARCHAR(255)


		DECLARE UploadPREH CURSOR FOR 
		SELECT ImportType, PRCo, Employee, ApprovedYN
		FROM dbo.mvwPREmpWorkEditValidation
		WHERE ImportID = @ImportID --AND ISNULL(ApprovedYN,'') <>''

		OPEN UploadPREH	
		FETCH NEXT FROM UploadPREH INTO @ImportType, @PRCo, @Employee, @Status
		
		WHILE @@FETCH_STATUS = 0 
		BEGIN
			IF EXISTS (SELECT TOP 1 1 FROM mvwPREmpWorkEditValidation we
				JOIN PREH e ON e.PRCo = we.PRCo AND e.Employee = we.Employee
				WHERE we.PRCo = @PRCo AND we.Employee = @Employee AND we.ApprovedYN = 'Y')
				BEGIN 
					BEGIN TRAN
					UPDATE e
					SET e.ActiveYN = ISNULL(we.ActiveYN,e.ActiveYN),
							--, e.[AUAccountNumber] =ISNULL(we.[AUAccountNumber], e.[AUAccountNumber]),
							--e.[AUBSB] =ISNULL(we.[AUBSB], e.[AUBSB]),
							--e.[AUEFTYN] =ISNULL(we.[AUEFTYN], e.[AUEFTYN]),
							--e.[AUReference] =ISNULL(we.[AUReference], e.[AUReference]),
							--e.[AcctType] =ISNULL(we.[AcctType], e.[AcctType]),
							e.[Address] =ISNULL(we.[Address], e.[Address]),
							e.[Address2] =ISNULL(we.[Address2], e.[Address2]),
							--e.[ArrearsActiveYN] =ISNULL(we.[ArrearsActiveYN], e.[ArrearsActiveYN]),
							--e.[AuditYN] =ISNULL(we.[AuditYN], e.[AuditYN]),
							--e.[BankAcct] =ISNULL(we.[BankAcct], e.[BankAcct]),
							e.[BirthDate] =ISNULL(we.[BirthDate], e.[BirthDate]),
							--e.[CPPQPPExempt] =ISNULL(we.[CPPQPPExempt], e.[CPPQPPExempt]),
							--e.[CSAllocMethod] =ISNULL(we.[CSAllocMethod], e.[CSAllocMethod]),
							--e.[CSGarnGroup] =ISNULL(we.[CSGarnGroup], e.[CSGarnGroup]),
							--e.[CSLimit] =ISNULL(we.[CSLimit], e.[CSLimit]),
							--e.[CatStatus] =ISNULL(we.[CatStatus], e.[CatStatus]),
							--e.[CellPhone] =ISNULL(we.[CellPhone], e.[CellPhone]),
							--e.[CertYN] =ISNULL(we.[CertYN], e.[CertYN]),
							--e.[ChkSort] =ISNULL(we.[ChkSort], e.[ChkSort]),
							e.[City] = ISNULL(we.[City], e.[City]),
							e.[Class] = we.[Class],
							--e.[Country] =ISNULL(we.[Country], e.[Country]),
							e.[Craft] = we.[Craft],
							--e.[Crew] =ISNULL(we.[Crew], e.[Crew]),
							--e.[DDPaySeq] =ISNULL(we.[DDPaySeq], e.[DDPaySeq]),
							--e.[DefaultPaySeq] =ISNULL(we.[DefaultPaySeq], e.[DefaultPaySeq]),
							--e.[DirDeposit] =ISNULL(we.[DirDeposit], e.[DirDeposit]),
							--e.[EIExempt] =ISNULL(we.[EIExempt], e.[EIExempt]),
							--e.[EMCo] =ISNULL(we.[EMCo], e.[EMCo]),
							--e.[EMFixedRate] =ISNULL(we.[EMFixedRate], e.[EMFixedRate]),
							--e.[EMGroup] =ISNULL(we.[EMGroup], e.[EMGroup]),
							--e.[EarnCode] =ISNULL(we.[EarnCode], e.[EarnCode]),
							e.[Email] =ISNULL(we.[Email], e.[Email]),
							--e.[Employee] = e.[Employee],
							--e.[Equipment] =ISNULL(we.[Equipment], e.[Equipment]),
							--e.[F1Amt] =ISNULL(we.[F1Amt], e.[F1Amt]),
							e.[FirstName] =ISNULL(we.[FirstName], e.[FirstName]),
							e.[GLCo] =ISNULL(we.[GLCo], e.[GLCo]),
							--e.[HDAmt] =ISNULL(we.[HDAmt], e.[HDAmt]),
							e.[HireDate] =ISNULL(we.[HireDate], e.[HireDate]),
							e.[HrlyRate] = CASE WHEN we.PRGroup = 1 THEN ISNULL(we.[HrlyRate], e.[HrlyRate]) ELSE ISNULL(e.[HrlyRate], 0) END,
							--e.[ImportID] =ISNULL(we.[ImportID], e.[ImportID]),
							--e.[ImportSequence] =ISNULL(we.[ImportSequence], e.[ImportSequence]),
							--e.[InsCode] = we.[InsCode],
							e.[InsState] =ISNULL(we.[InsState], e.[InsState]),
							--e.[JCCo] =ISNULL(we.[JCCo], e.[JCCo]),
							--e.[JCFixedRate] =ISNULL(we.[JCFixedRate], e.[JCFixedRate]),
							--e.[Job] =ISNULL(we.[Job], e.[Job]),
							--e.[LCFStock] =ISNULL(we.[LCFStock], e.[LCFStock]),
							--e.[LCPStock] =ISNULL(we.[LCPStock], e.[LCPStock]),
							e.[LastName] =ISNULL(we.[LastName], e.[LastName]),
							e.[LastUpdated] =ISNULL(we.[LastUpdated], GETDATE()),
							--e.[LocalCode] =ISNULL(we.[LocalCode], e.[LocalCode]),
							e.[MidName] =ISNULL(we.[MidName], e.[MidName]),
							--e.[NAICS] =ISNULL(we.[NAICS], e.[NAICS]),
							--e.[NewHireActEndDate] =ISNULL(we.[NewHireActEndDate], e.[NewHireActEndDate]),
							--e.[NewHireActStartDate] =ISNULL(we.[NewHireActStartDate], e.[NewHireActStartDate]),
							--e.[NonResAlienYN] =ISNULL(we.[NonResAlienYN], e.[NonResAlienYN]),
							--e.[OTOpt] =ISNULL(we.[OTOpt], e.[OTOpt]),
							--e.[OTSched] =ISNULL(we.[OTSched], e.[OTSched]),
							e.[OccupCat] =ISNULL(we.[OccupCat], e.[OccupCat]),
							--e.[PPIPExempt] =ISNULL(we.[PPIPExempt], e.[PPIPExempt]),
							--e.[PRCo] = e.[PRCo],
							e.[PRDept] = we.[PRDept],
							e.[PRGroup] = we.[PRGroup],
							--e.[PayMethodDelivery] =ISNULL(we.[PayMethodDelivery], e.[PayMethodDelivery]),
							e.[PensionYN] =ISNULL(we.[PensionYN], e.[PensionYN]),
							e.[Phone] =ISNULL(we.[Phone], e.[Phone]),
							--e.[PostToAll] =ISNULL(we.[PostToAll], e.[PostToAll]),
							e.[Race] =ISNULL(we.[Race], e.[Race]),
							e.[RecentRehireDate] =ISNULL(we.[RecentRehireDate], e.[RecentRehireDate]),
							--e.[RecentSeparationDate] =ISNULL(we.[RecentSeparationDate], e.[RecentSeparationDate]),
							--e.[RejectReason] =ISNULL(we.[RejectReason], e.[RejectReason]),
							--e.[RoutingId] =ISNULL(we.[RoutingId], e.[RoutingId]),
							e.[SSN] =ISNULL(we.[SSN], e.[SSN]),
							--e.[SalaryAmt] =ISNULL(we.[SalaryAmt], e.[SalaryAmt]),
							--e.[SeparationRedundancyRetirement] = ISNULL(we.[SeparationRedundancyRetirement], e.[SeparationRedundancyRetirement]),
							e.[Sex] =ISNULL(we.[Sex], e.[Sex]),
							--e.[Shift] =ISNULL(we.[Shift], e.[Shift]),
							--e.[SortName] =ISNULL(we.[SortName], e.[SortName]),
							e.[State] =ISNULL(we.[State], e.[State]),
							e.[Suffix] =ISNULL(we.[Suffix], e.[Suffix]),
							--e.[TaxState] =ISNULL(we.[TaxState], e.[TaxState]),
							e.[TermDate] =ISNULL(we.[TermDate], e.[TermDate]),
							--e.[TimesheetRevGroup] =ISNULL(we.[TimesheetRevGroup], e.[TimesheetRevGroup]),
							--e.[TradeSeq] =ISNULL(we.[TradeSeq], e.[TradeSeq]),
							e.[UnempState] =ISNULL(we.[UnempState], e.[UnempState]),
							--e.[UpdatePRAEYN] =ISNULL(we.[UpdatePRAEYN], e.[UpdatePRAEYN]),
							e.[UseIns] =ISNULL(we.[UseIns], e.[UseIns]),
							--e.[UseInsState] =ISNULL(we.[UseInsState], e.[UseInsState]),
							--e.[UseLocal] =ISNULL(we.[UseLocal], e.[UseLocal]),
							--e.[UseState] =ISNULL(we.[UseState], e.[UseState]),
							--e.[UseUnempState] =ISNULL(we.[UseUnempState], e.[UseUnempState]),
							--e.[WOLocalCode] =ISNULL(we.[WOLocalCode], e.[WOLocalCode]),
							--e.[WOTaxState] =ISNULL(we.[WOTaxState], e.[WOTaxState]),
							--e.[YTDSUI] =ISNULL(we.[YTDSUI], e.[YTDSUI]),
							e.[Zip] =ISNULL(we.[Zip], e.[Zip]),
							e.[ud401kElgDate] =ISNULL(we.[ud401kElgDate], e.[ud401kElgDate]),
							e.[ud401kEligYN] =ISNULL(we.[ud401kEligYN], e.[ud401kEligYN]),
							--e.[udCGCTable] =ISNULL(we.[udCGCTable], e.[udCGCTable]),
							--e.[udCGCTableID] =ISNULL(we.[udCGCTableID], e.[udCGCTableID]),
							--e.[udConv] =ISNULL(we.[udConv], e.[udConv]),
							e.[udEmpGroup] =ISNULL(we.[udEmpGroup], e.[udEmpGroup]),
							e.[udExempt] =ISNULL(we.[udExempt], e.[udExempt]),
							e.[udJobTitle] =ISNULL(we.[udJobTitle], e.[udJobTitle]),
							--e.[udOrigHireDate] =ISNULL(we.[udOrigHireDate], e.[udOrigHireDate]),
							--e.[udSource] =ISNULL(we.[udSource], e.[udSource]),
							e.[Notes] =ISNULL(e.Notes,'') + ISNULL(we.[Notes], ''),
							e.[udTermReason] =ISNULL(we.[udTermReason], e.[udTermReason])
					FROM dbo.PREH e
						JOIN mvwPREmpWorkEditValidation we ON e.PRCo = we.PRCo AND e.Employee = we.Employee
					WHERE we.ImportID = @ImportID AND @ImportType = 'UPDATE' AND e.PRCo = @PRCo AND e.Employee = @Employee
					
					

					INSERT INTO @MergeOutput (ActionType, PRCo, Employee)
					VALUES(@ImportType,@PRCo, @Employee) 
					
					DELETE dbo.udPREmpWorkEdit 
					WHERE ImportID = @ImportID AND PRCo = @PRCo AND Employee = @Employee

					COMMIT TRAN
				END

			IF EXISTS(
				SELECT TOP 1 1 FROM mvwPREmpWorkEditValidation we 
						LEFT JOIN PREH e ON we.PRCo = e.PRCo AND we.Employee = e.Employee
					WHERE e.Employee IS NULL AND we.PRCo = @PRCo AND we.Employee = @Employee AND we.ImportType LIKE 'NEW%' AND @Status = 'Y')
				BEGIN
					BEGIN TRAN
					INSERT INTO dbo.PREH
					(PRCo ,Employee ,
					    LastName ,
					    FirstName ,
					    MidName , --5
					    SortName ,
					    Address ,
					    City ,
					    State ,
					    Zip , --10
					    Address2 ,
					    Phone ,
					    SSN ,
					    Race ,
					    Sex , --15
					    BirthDate ,
					    HireDate ,
					    TermDate ,
					    PRGroup ,
					    PRDept , --20
					    Craft ,
					    Class ,
					    InsCode ,
					    TaxState ,
					    UnempState ,--25
					    InsState ,
					    LocalCode ,
					    GLCo ,
					    UseState ,
					    UseIns ,--30
					    JCCo ,
					    Job ,
					    Crew ,
					    LastUpdated ,
					    EarnCode ,--35
					    HrlyRate ,
					    SalaryAmt ,
					    OTOpt ,
					    OTSched ,
					    JCFixedRate ,--40
					    EMFixedRate ,
					    YTDSUI ,
					    OccupCat ,
					    CatStatus ,
					    DirDeposit ,--45
					    RoutingId ,
					    BankAcct ,
					    AcctType ,
					    ActiveYN ,
					    PensionYN ,--50
					    PostToAll ,
					    CertYN ,
					    ChkSort ,
					    AuditYN ,
					    Notes ,--55
					    --UniqueAttchID ,
					    Email ,
					    DefaultPaySeq ,
					    DDPaySeq ,
					    Suffix ,
					    TradeSeq ,--60
					    CSLimit ,
					    CSGarnGroup ,
					    CSAllocMethod ,
					    Shift ,
					    NonResAlienYN ,--65
					    --KeyID ,
					    Country ,
					    HDAmt ,
					    F1Amt ,
					    LCFStock ,
					    LCPStock ,
					    NAICS ,
					    AUEFTYN ,
					    AUAccountNumber ,
					    AUBSB ,
					    AUReference ,
					    EMCo ,
					    Equipment ,
					    EMGroup ,
					    PayMethodDelivery ,
					    CPPQPPExempt ,
					    EIExempt ,
					    PPIPExempt ,
					    TimesheetRevGroup ,
					    UpdatePRAEYN ,
					    WOTaxState ,
					    WOLocalCode ,
					    UseLocal ,
					    UseUnempState ,
					    UseInsState ,
					    NewHireActStartDate ,
					    NewHireActEndDate ,
					    CellPhone ,
					    ArrearsActiveYN ,
					    udOrigHireDate ,
					    udEmpGroup ,
					    udSource ,
					    udConv ,
					    udCGCTable ,
					    udCGCTableID ,
					    RecentRehireDate ,
					    RecentSeparationDate ,
					    SeparationRedundancyRetirement ,
					    udJobTitle ,
					    udExempt ,
					    ud401kEligYN ,
					    ud401kElgDate ,
					    udTermReason 
						--,ud401kElgEndDate
						)
					SELECT PRCo ,
					    Employee ,
					    LastName ,
					    FirstName ,
					    MidName ,
					    SortName ,
					    Address ,
					    City ,
					    State ,
					    Zip ,
					    Address2 ,
					    Phone ,
					    SSN ,
					    Race ,
					    Sex ,
					    BirthDate ,
					    HireDate ,
					    TermDate ,
					    PRGroup ,
					    PRDept ,
					    Craft ,
					    Class ,
					    InsCode ,
					    TaxState ,
					    UnempState ,
					    InsState ,
					    LocalCode ,
					    GLCo ,
					    UseState ,
					    UseIns ,
					    JCCo ,
					    Job ,
					    Crew ,
					    LastUpdated ,
					    EarnCode ,
					    HrlyRate ,
					    0,--SalaryAmt ,
					    OTOpt ,
					    OTSched ,
					    JCFixedRate ,
					    EMFixedRate ,
					    YTDSUI ,
					    OccupCat ,
					    CatStatus ,
					    DirDeposit ,
					    RoutingId ,
					    BankAcct ,
					    AcctType ,
					    ActiveYN ,
					    PensionYN ,
					    PostToAll ,
					    CertYN ,
					    ChkSort ,
					    AuditYN ,
					    Notes ,
					    --UniqueAttchID ,
					    Email ,
					    DefaultPaySeq ,
					    DDPaySeq ,
					    Suffix ,
					    TradeSeq ,
					    CSLimit ,
					    CSGarnGroup ,
					    CSAllocMethod ,
					    Shift ,
					    NonResAlienYN ,
					    --KeyID ,
					    Country ,
					    HDAmt ,
					    F1Amt ,
					    LCFStock ,
					    LCPStock ,
					    NAICS ,
					    AUEFTYN ,
					    AUAccountNumber ,
					    AUBSB ,
					    AUReference ,
					    EMCo ,
					    Equipment ,
					    EMGroup ,
					    PayMethodDelivery ,
					    CPPQPPExempt ,
					    EIExempt ,
					    PPIPExempt ,
					    TimesheetRevGroup ,
					    UpdatePRAEYN ,
					    WOTaxState ,
					    WOLocalCode ,
					    UseLocal ,
					    UseUnempState ,
					    UseInsState ,
					    NewHireActStartDate ,
					    NewHireActEndDate ,
					    CellPhone ,
					    ArrearsActiveYN ,
					    udOrigHireDate ,
					    udEmpGroup ,
					    udSource ,
					    udConv ,
					    udCGCTable ,
					    udCGCTableID ,
					    RecentRehireDate ,
					    RecentSeparationDate ,
					    SeparationRedundancyRetirement ,
					    udJobTitle ,
					    udExempt ,
					    ud401kEligYN ,
					    ud401kElgDate ,
					    udTermReason 
					FROM mvwPREmpWorkEditValidation we
					WHERE ImportID = @ImportID AND PRCo = @PRCo AND Employee = @Employee

					INSERT INTO @MergeOutput (ActionType, PRCo, Employee)
					VALUES('INSERT', @PRCo, @Employee)
					COMMIT TRAN
				END
			
			SELECT @Status = ISNULL(@Status, 'A')

			EXEC @rcode = [MCK_INTEGRATION].[dbo].[spHRNetStatusUpdate] @PRCo = @PRCo, @Employee = @Employee, @Status = @Status, @ReturnMessage = @msg OUT
			SELECT @ReturnMessage = ISNULL(@ReturnMessage,'') + @msg

			--INSERT INTO budPREmpImportErrors(ImportID, PRCo, Employee, ErrorSequence, Message)
			--SELECT @ImportID, PRCo, Employee, Sequence, ErrorMessage 
			--FROM [dbo].[mckfnPREmpWorkEditErrors](@ImportID)

			--SELECT * FROM mckfnPREmpWorkEditErrors ('TEST4')

			SELECT @ReturnMessage = ISNULL(@ReturnMessage,'') + ISNULL(@msg, '')
			
			FETCH NEXT FROM UploadPREH INTO @ImportType, @PRCo, @Employee, @Status
		END
		CLOSE UploadPREH
		DEALLOCATE UploadPREH

		
	END TRY
	BEGIN CATCH
		TranRollbk:
		ROLLBACK TRAN
		SELECT @ReturnMessage = ISNULL(@ReturnMessage, '')+' - '+ERROR_MESSAGE(), @rcode = 1
		
	END CATCH
	IF @rcode = 0
	BEGIN
		DELETE FROM dbo.budPREmpWorkEdit
		WHERE ImportID = @ImportID 
			--AND ApprovedYN = 'N' --AND ImportType = @ImportType
			--AND CONVERT(VARCHAR(3),PRCo) + CONVERT(VARCHAR(20),Employee) IN (SELECT CONVERT(VARCHAR(3),PRCo) + CONVERT(VARCHAR(20),Employee) FROM @MergeOutput)

		--DECLARE @ErrorCount BIGINT
		--SELECT @ErrorCount = COUNT(*)
		--FROM dbo.udPREmpWorkEdit
		--WHERE ImportID = @ImportID

		--SELECT @ReturnMessage = ISNULL(@ReturnMessage,'') + CASE WHEN @ReturnMessage IS NOT NULL THEN CHAR(13) END + CONVERT(VARCHAR(100),@ErrorCount) +' records were not processed because they have errors.'--, @rcode = 1
				
		SELECT @ReturnMessage = ISNULL(@ReturnMessage, '') +' '+ CONVERT(VARCHAR(255),COUNT(*)) + ' Records updated.'
		FROM @MergeOutput
		WHERE ActionType = 'UPDATE'
		
		SELECT @ReturnMessage = ISNULL(@ReturnMessage, '') +' '+ CONVERT(VARCHAR(255),COUNT(*)) + ' Records inserted.'
		FROM @MergeOutput
		WHERE ActionType = 'INSERT'

	END

	RETURN @rcode
END
