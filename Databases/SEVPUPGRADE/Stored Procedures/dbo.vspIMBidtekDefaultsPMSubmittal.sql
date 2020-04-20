SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[vspIMBidtekDefaultsPMSubmittal]
        /***********************************************************
         * CREATED BY:  AJW 
         * MODIFIED BY:	GP TK-19818 - Changed package to bDocument
		 *
         * Usage:
         *	Used by Imports to create values for needed or missing
         *      data based upon Bidtek default rules.
         *
         * Input params:
         *  @Company default company
         *	@ImportId	Import Identifier
         *	@ImportTemplate	Import ImportTemplate
         *  @Form import form
         *  @rectype 
         *
         * Output params:
         *	@msg		error message
         *
         * Return code:
         *	0 = success, 1 = failure
         ************************************************************/
        
 (@Company bCompany, @ImportId varchar(20), @ImportTemplate varchar(20), @Form varchar(30), @rectype varchar(30), @msg varchar(120) output)

as
BEGIN
        set nocount on
        
        declare @rcode int, @recode int, @desc varchar(120)
               
        SELECT @rcode = 0
        
        /* check required input params */
		-- hate gotos will knock these out later when I can see the bottom
        IF @ImportId IS NULL 
            BEGIN
                SELECT  @desc = 'Missing ImportId.',
                        @rcode = 1
                GOTO bspexit
            END
        IF @ImportTemplate IS NULL 
            BEGIN
                SELECT  @desc = 'Missing ImportTemplate.',
                        @rcode = 1
                GOTO bspexit
            END
        
        IF @Form IS NULL 
            BEGIN
                SELECT  @desc = 'Missing Form.',
                        @rcode = 1
                GOTO bspexit
            END
        
        -- Check ImportTemplate detail for columns to set Bidtek Defaults
        IF NOT EXISTS (SELECT 1
		FROM			IMTD WITH ( NOLOCK )
		WHERE			IMTD.ImportTemplate = @ImportTemplate
						AND IMTD.DefaultValue = '[Bidtek]'	)
        BEGIN 
			SELECT  @desc = 'No Bidtek Defaults set up for ImportTemplate '
                        + @ImportTemplate + '.',
                        @rcode = 1
                GOTO bspexit
        END
        
        -- keeping the vars so I don't have to dump them to a temp table and do queries again
        DECLARE 
				@OverwritePMCoYN bYN,
				@OverwriteProjectYN bYN,
				@OverwriteSeqYN bYN,
				@OverwriteSubmittalNumberYN bYN,
				@OverwriteSubmittalRevYN bYN,
				@OverwritePackageYN bYN,
				@OverwritePackageRevYN bYN,
				@OverwriteDescriptionYN bYN,
				@OverwriteDetailsYN bYN,
				@OverwriteDocumentTypeYN bYN,
				@OverwriteStatusYN bYN,
				@OverwriteSpecSectionYN bYN,
				@OverwriteCopiesYN bYN,
				@OverwriteApprovingFirmYN bYN,
				@OverwriteApprovingFirmContactYN bYN,
				@OverwriteOurFirmYN bYN,
				@OverwriteOurFirmContactYN bYN,
				@OverwriteResponsibleFirmYN bYN,
				@OverwriteResponsibleFirmContactYN bYN,
				@OverwriteAPCoYN bYN,
				@OverwriteSubcontractYN bYN,
				@OverwritePurchaseOrderYN bYN,
				@OverwriteActivityIDYN bYN,
				@OverwriteActivityDescriptionYN bYN,
				@OverwriteActivityDateYN bYN,
				@OverwriteVendorGroupYN bYN,
				@OverwriteDueToResponsibleFirmYN bYN,
				@OverwriteSentToResponsibleFirmYN bYN,
				@OverwriteDueFromResponsibleFirmYN bYN,
				@OverwriteReceivedFromResponsibleFirmYN bYN,
				@OverwriteReturnedToResponsibleFirmYN bYN,
				@OverwriteDueToApprovingFirmYN bYN,
				@OverwriteSentToApprovingFirmYN bYN,
				@OverwriteDueFromApprovingFirmYN bYN,
				@OverwriteReceivedFromApprovingFirmYN bYN,
				@OverwriteLeadDays1YN bYN,
				@OverwriteLeadDays2YN bYN,
				@OverwriteLeadDays3YN bYN,
				@OverwriteNotesYN bYN,
				@ynPMCo bYN,
				@ynProject bYN,
				@ynSeq bYN,
				@ynSubmittalNumber bYN,
				@ynSubmittalRev bYN,
				@ynPackage bYN,
				@ynPackageRev bYN,
				@ynDescription bYN,
				@ynDetails bYN,
				@ynDocumentType bYN,
				@ynStatus bYN,
				@ynSpecSection bYN,
				@ynCopies bYN,
				@ynApprovingFirm bYN,
				@ynApprovingFirmContact bYN,
				@ynOurFirm bYN,
				@ynOurFirmContact bYN,
				@ynResponsibleFirm bYN,
				@ynResponsibleFirmContact bYN,
				@ynAPCo bYN,
				@ynSubcontract bYN,
				@ynPurchaseOrder bYN,
				@ynActivityID bYN,
				@ynActivityDescription bYN,
				@ynActivityDate bYN,
				@ynVendorGroup bYN,
				@ynDueToResponsibleFirm bYN,
				@ynSentToResponsibleFirm bYN,
				@ynDueFromResponsibleFirm bYN,
				@ynReceivedFromResponsibleFirm bYN,
				@ynReturnedToResponsibleFirm bYN,
				@ynDueToApprovingFirm bYN,
				@ynSentToApprovingFirm bYN,
				@ynDueFromApprovingFirm bYN,
				@ynReceivedFromApprovingFirm bYN,
				@ynLeadDays1 bYN,
				@ynLeadDays2 bYN,
				@ynLeadDays3 bYN,
				@ynNotes bYN
			

		-- lets build a table of tables to update, someday ill improve the vfTableFromArray to run better
		CREATE TABLE #tblCols (ColumnName varchar(500))
		
		--populate @tblCols from colum list in IMTD
		INSERT INTO #tblCols ( ColumnName )
		select RTRIM(LTRIM([Names])) -- just in case someone puts white space into the list
		--KEEP IN MIND THIS COLUMN LIST IS REFERENCED THRU OUT THE PROC 
        from dbo.vfTableFromArray('PMCo,Project,Seq,SubmittalNumber,SubmittalRev,Package,PackageRev,'+
						'[Description],Details,DocumentType,[Status],SpecSection,Copies,ApprovingFirm,'+
						'ApprovingFirmContact,OurFirm,OurFirmContact,ResponsibleFirm,ResponsibleFirmContact,APCo,Subcontract,'+
						'PurchaseOrder,ActivityID,ActivityDescription,ActivityDate,VendorGroup,DueToResponsibleFirm,'+
						'SentToResponsibleFirm,DueFromResponsibleFirm,ReceivedFromResponsibleFirm,'+
						'ReturnedToResponsibleFirm,DueToApprovingFirm,SentToApprovingFirm,DueFromApprovingFirm,'+
						'ReceivedFromApprovingFirm,LeadDays1,LeadDays2,LeadDays3,Notes')
		
		-- replaces the	 vfIMTemplateOverwrite function, one shot all defaults
		SELECT @OverwritePMCoYN = piv.PMCo,
			@OverwriteProjectYN = piv.Project,
			@OverwriteSeqYN = piv.Seq,
			@OverwriteSubmittalNumberYN = piv.SubmittalNumber,
			@OverwriteSubmittalRevYN = piv.SubmittalRev,
			@OverwritePackageYN = piv.Package,
			@OverwritePackageRevYN = piv.PackageRev,
			@OverwriteDescriptionYN = piv.Description,
			@OverwriteDetailsYN = piv.Details,
			@OverwriteDocumentTypeYN = piv.DocumentType,
			@OverwriteStatusYN = piv.Status,
			@OverwriteSpecSectionYN = piv.SpecSection,
			@OverwriteCopiesYN = piv.Copies,
			@OverwriteApprovingFirmYN = piv.ApprovingFirm,
			@OverwriteApprovingFirmContactYN = piv.ApprovingFirmContact,
			@OverwriteOurFirmYN = piv.OurFirm,
			@OverwriteOurFirmContactYN = piv.OurFirmContact,
			@OverwriteResponsibleFirmYN = piv.ResponsibleFirm,
			@OverwriteResponsibleFirmContactYN = piv.ResponsibleFirmContact,
			@OverwriteAPCoYN = piv.APCo,
			@OverwriteSubcontractYN = piv.Subcontract,
			@OverwritePurchaseOrderYN = piv.PurchaseOrder,
			@OverwriteActivityIDYN = piv.ActivityID,
			@OverwriteActivityDescriptionYN = piv.ActivityDescription,
			@OverwriteActivityDateYN = piv.ActivityDate,
			@OverwriteVendorGroupYN = piv.VendorGroup,
			@OverwriteDueToResponsibleFirmYN = piv.DueToResponsibleFirm,
			@OverwriteSentToResponsibleFirmYN = piv.SentToResponsibleFirm,
			@OverwriteDueFromResponsibleFirmYN = piv.DueFromResponsibleFirm,
			@OverwriteReceivedFromResponsibleFirmYN = piv.ReceivedFromResponsibleFirm,
			@OverwriteReturnedToResponsibleFirmYN = piv.ReturnedToResponsibleFirm,
			@OverwriteDueToApprovingFirmYN = piv.DueToApprovingFirm,
			@OverwriteSentToApprovingFirmYN = piv.SentToApprovingFirm,
			@OverwriteDueFromApprovingFirmYN = piv.DueFromApprovingFirm,
			@OverwriteReceivedFromApprovingFirmYN = piv.ReceivedFromApprovingFirm,
			@OverwriteLeadDays1YN = piv.LeadDays1,
			@OverwriteLeadDays2YN = piv.LeadDays2,
			@OverwriteLeadDays3YN = piv.LeadDays3,
			@OverwriteNotesYN = piv.Notes
			
		FROM (
			   SELECT	d.ColumnName,
						CASE WHEN ISNULL(@rectype,'')='' THEN 'N' ELSE i.OverrideYN END AS OverwriteValue
			   FROM dbo.bDDUD d
					JOIN #tblCols c ON d.ColumnName = c.ColumnName
					LEFT JOIN 	dbo.IMTD i WITH (NOLOCK) ON i.Identifier = d.Identifier 
											AND i.ImportTemplate= @ImportTemplate
											AND i.DefaultValue = '[Bidtek]'
											AND i.RecordType = @rectype
											AND d.Form = @Form
			)   a
		PIVOT (MAX(a.OverwriteValue) 
		-- don't like this is hard coded but have to go with it for now
				FOR a.ColumnName IN (PMCo,Project,Seq,SubmittalNumber,SubmittalRev,Package,PackageRev,
						[Description],Details,DocumentType,[Status],SpecSection,Copies,ApprovingFirm,
						ApprovingFirmContact,OurFirm,OurFirmContact,ResponsibleFirm,ResponsibleFirmContact,APCo,Subcontract,
						PurchaseOrder,ActivityID,ActivityDescription,ActivityDate,VendorGroup,DueToResponsibleFirm,
						SentToResponsibleFirm,DueFromResponsibleFirm,ReceivedFromResponsibleFirm,
						ReturnedToResponsibleFirm,DueToApprovingFirm,SentToApprovingFirm,DueFromApprovingFirm,
						ReceivedFromApprovingFirm,LeadDays1,LeadDays2,LeadDays3,Notes)
									) piv
		-- in talking with DAN this might not be needed, we should always have a rectype, therefore
		-- we will alway have an overwrite or we won't, so instead of assigning N for nulls to the overwrite
		-- leave it null and that means N for the yn vars.
		SELECT 
			@ynPMCo = ISNULL(piv.PMCo,'N'),
			@ynProject = ISNULL(piv.Project,'N'),
			@ynSeq = ISNULL(piv.Seq,'N'),
			@ynSubmittalNumber = ISNULL(piv.SubmittalNumber,'N'),
			@ynSubmittalRev = ISNULL(piv.SubmittalRev,'N'),
			@ynPackage = ISNULL(piv.Package,'N'),
			@ynPackageRev = ISNULL(piv.PackageRev,'N'),
			@ynDescription = ISNULL(piv.Description,'N'),
			@ynDetails = ISNULL(piv.Details,'N'),
			@ynDocumentType = ISNULL(piv.DocumentType,'N'),
			@ynStatus = ISNULL(piv.Status,'N'),
			@ynSpecSection = ISNULL(piv.SpecSection,'N'),
			@ynCopies = ISNULL(piv.Copies,'N'),
			@ynApprovingFirm = ISNULL(piv.ApprovingFirm,'N'),
			@ynApprovingFirmContact = ISNULL(piv.ApprovingFirmContact,'N'),
			@ynOurFirm = ISNULL(piv.OurFirm,'N'),
			@ynOurFirmContact = ISNULL(piv.OurFirmContact,'N'),
			@ynResponsibleFirm = ISNULL(piv.ResponsibleFirm,'N'),
			@ynResponsibleFirmContact = ISNULL(piv.ResponsibleFirmContact,'N'),
			@ynAPCo = ISNULL(piv.APCo,'N'),
			@ynSubcontract = ISNULL(piv.Subcontract,'N'),
			@ynPurchaseOrder = ISNULL(piv.PurchaseOrder,'N'),
			@ynActivityID = ISNULL(piv.ActivityID,'N'),
			@ynActivityDescription = ISNULL(piv.ActivityDescription,'N'),
			@ynActivityDate = ISNULL(piv.ActivityDate,'N'),
			@ynVendorGroup = ISNULL(piv.VendorGroup,'N'),
			@ynDueToResponsibleFirm = ISNULL(piv.DueToResponsibleFirm,'N'),
			@ynSentToResponsibleFirm = ISNULL(piv.SentToResponsibleFirm,'N'),
			@ynDueFromResponsibleFirm = ISNULL(piv.DueFromResponsibleFirm,'N'),
			@ynReceivedFromResponsibleFirm = ISNULL(piv.ReceivedFromResponsibleFirm,'N'),
			@ynReturnedToResponsibleFirm = ISNULL(piv.ReturnedToResponsibleFirm,'N'),
			@ynDueToApprovingFirm = ISNULL(piv.DueToApprovingFirm,'N'),
			@ynSentToApprovingFirm = ISNULL(piv.SentToApprovingFirm,'N'),
			@ynDueFromApprovingFirm = ISNULL(piv.DueFromApprovingFirm,'N'),
			@ynReceivedFromApprovingFirm = ISNULL(piv.ReceivedFromApprovingFirm,'N'),
			@ynLeadDays1 = ISNULL(piv.LeadDays1,'N'),
			@ynLeadDays2 = ISNULL(piv.LeadDays2,'N'),
			@ynLeadDays3 = ISNULL(piv.LeadDays3,'N'),
			@ynNotes = ISNULL(piv.Notes,'N')
	   FROM (
			   SELECT	d.ColumnName,
						CASE WHEN i.Identifier IS NULL THEN 'N' ELSE 'Y' END AS OverrideValue
			   FROM dbo.bDDUD d
					JOIN #tblCols c ON d.ColumnName = c.ColumnName
					LEFT JOIN 	dbo.IMTD i WITH (NOLOCK) ON i.Identifier = d.Identifier 
											AND i.ImportTemplate= @ImportTemplate
											AND i.DefaultValue = '[Bidtek]'
			   WHERE d.Form = @Form
			)   a
		PIVOT (MAX(a.OverrideValue) 
				FOR a.ColumnName IN (PMCo,Project,Seq,SubmittalNumber,SubmittalRev,Package,PackageRev,
						[Description],Details,DocumentType,[Status],SpecSection,Copies,ApprovingFirm,
						ApprovingFirmContact,OurFirm,OurFirmContact,ResponsibleFirm,ResponsibleFirmContact,APCo,Subcontract,
						PurchaseOrder,ActivityID,ActivityDescription,ActivityDate,VendorGroup,DueToResponsibleFirm,
						SentToResponsibleFirm,DueFromResponsibleFirm,ReceivedFromResponsibleFirm,
						ReturnedToResponsibleFirm,DueToApprovingFirm,SentToApprovingFirm,DueFromApprovingFirm,
						ReceivedFromApprovingFirm,LeadDays1,LeadDays2,LeadDays3,Notes)
										) piv
	
		
	    -- let's see how to process the cursor
        -- here is the cursor set, pivoted out        
		SELECT
			ROW_NUMBER() OVER (ORDER BY RecordSeq) AS tmpID, -- I need a primary key, when I deal with joining
			piv.*
		INTO #tmpPivIMWE
		FROM (
			SELECT  IMWE.RecordSeq,
					DDUD.TableName,
					DDUD.ColumnName,
					IMWE.UploadVal
			FROM    dbo.IMWE
					INNER JOIN dbo.DDUD ON IMWE.Identifier = DDUD.Identifier
													   AND DDUD.Form = IMWE.Form
			WHERE   IMWE.ImportId = @ImportId
					AND IMWE.ImportTemplate = @ImportTemplate
					AND IMWE.Form LIKE @Form
		) AS a											 
		PIVOT  (
				-- use the upload value instead of the imported value
				-- this catches cross references and keyed in defaults
				-- I'm breaking this from the old version where we would intermix upload and imported
				-- I'm going to drive from the upload
					MAX(a.UploadVal)
					FOR a.ColumnName IN (PMCo,Project,Seq,SubmittalNumber,SubmittalRev,Package,PackageRev,
						[Description],Details,DocumentType,[Status],SpecSection,Copies,ApprovingFirm,
						ApprovingFirmContact,OurFirm,OurFirmContact,ResponsibleFirm,ResponsibleFirmContact,APCo,Subcontract,
						PurchaseOrder,ActivityID,ActivityDescription,ActivityDate,VendorGroup,DueToResponsibleFirm,
						SentToResponsibleFirm,DueFromResponsibleFirm,ReceivedFromResponsibleFirm,
						ReturnedToResponsibleFirm,DueToApprovingFirm,SentToApprovingFirm,DueFromApprovingFirm,
						ReceivedFromApprovingFirm,LeadDays1,LeadDays2,LeadDays3,Notes)
				)			
				   AS piv
	
		
        --let's add a cluster index on tmpID since we are going to use it everywhere
		CREATE UNIQUE CLUSTERED INDEX IX_tmpPivIMWE ON #tmpPivIMWE (tmpID)
		
		-- we are going to work off the temp table which for problem loads should provide performance
		-- this is because we have a smaller data set in the temp table than IMWE
		-- and we will hit all the rows at once per column
		-- for 100 imported rows in the past we loop 100 x 56 columns or 5600 times to update values and other selects
		-- now this should be just 56 times one for each column to a smaller 100 row temp table versus 
		-- a 1 million row IMWE table
		-- then the plan is to write back to IMWE in one shot 
	
		--check issues with data and then update to null if bad
		UPDATE #tmpPivIMWE
		SET PMCo = CASE WHEN ISNUMERIC(PMCo) = 1 THEN PMCo ELSE NULL END,
			Seq = CASE WHEN ISNUMERIC(Seq) = 1 THEN Seq ELSE NULL END,
			Copies = CASE WHEN ISNUMERIC(Copies) = 1 THEN Copies ELSE NULL END,
			ApprovingFirm = CASE WHEN ISNUMERIC(ApprovingFirm) = 1 THEN ApprovingFirm ELSE NULL END,
			ApprovingFirmContact = CASE WHEN ISNUMERIC(ApprovingFirmContact) = 1 THEN ApprovingFirmContact ELSE NULL END,
			OurFirm = CASE WHEN ISNUMERIC(OurFirm) = 1 THEN OurFirm ELSE NULL END,
			OurFirmContact = CASE WHEN ISNUMERIC(OurFirmContact) = 1 THEN OurFirmContact ELSE NULL END,
			ResponsibleFirm = CASE WHEN ISNUMERIC(ResponsibleFirm) = 1 THEN ResponsibleFirm ELSE NULL END,
			ResponsibleFirmContact = CASE WHEN ISNUMERIC(ResponsibleFirmContact) = 1 THEN ResponsibleFirmContact ELSE NULL END,
			ActivityID = CASE WHEN ISNUMERIC(ActivityID) = 1 THEN ActivityID ELSE NULL END,
			ActivityDate = CASE WHEN ISDATE(ActivityDate) = 1 THEN ActivityDate ELSE NULL END,
			VendorGroup = CASE WHEN ISNUMERIC(VendorGroup) = 1 THEN VendorGroup ELSE NULL END,
			APCo = CASE WHEN ISNUMERIC(APCo) = 1 THEN APCo ELSE NULL END,
			DueToResponsibleFirm = CASE WHEN ISDATE(DueToResponsibleFirm) = 1 THEN DueToResponsibleFirm ELSE NULL END,
			SentToResponsibleFirm = CASE WHEN ISDATE(SentToResponsibleFirm) = 1 THEN SentToResponsibleFirm ELSE NULL END,
			DueFromResponsibleFirm = CASE WHEN ISDATE(DueFromResponsibleFirm) = 1 THEN DueFromResponsibleFirm ELSE NULL END,
			ReceivedFromResponsibleFirm = CASE WHEN ISDATE(ReceivedFromResponsibleFirm) = 1 THEN ReceivedFromResponsibleFirm ELSE NULL END,
			ReturnedToResponsibleFirm = CASE WHEN ISDATE(ReturnedToResponsibleFirm) = 1 THEN ReturnedToResponsibleFirm ELSE NULL END,
			DueToApprovingFirm = CASE WHEN ISDATE(DueToApprovingFirm) = 1 THEN DueToApprovingFirm ELSE NULL END,
			SentToApprovingFirm = CASE WHEN ISDATE(SentToApprovingFirm) = 1 THEN SentToApprovingFirm ELSE NULL END,
			DueFromApprovingFirm = CASE WHEN ISDATE(DueFromApprovingFirm) = 1 THEN DueFromApprovingFirm ELSE NULL END,
			ReceivedFromApprovingFirm = CASE WHEN ISDATE(ReceivedFromApprovingFirm) = 1 THEN ReceivedFromApprovingFirm ELSE NULL END,
			LeadDays1 = CASE WHEN ISNUMERIC(LeadDays1) = 1 THEN LeadDays1 ELSE NULL END,
			LeadDays2 = CASE WHEN ISNUMERIC(LeadDays2) = 1 THEN LeadDays2 ELSE NULL END,
			LeadDays3 = CASE WHEN ISNUMERIC(LeadDays3) = 1 THEN LeadDays3 ELSE NULL END
			
		-- set default company
		IF @ynPMCo = 'Y' 
		BEGIN
		
			UPDATE piv
			SET PMCo = @Company
			FROM #tmpPivIMWE piv
			where piv.PMCo IS NULL
				OR ISNULL(@OverwritePMCoYN, 'Y') = 'Y'
		END
		
		-- set default vendor group
		IF @ynVendorGroup = 'Y' 
		BEGIN 
			UPDATE piv
			SET VendorGroup = h.VendorGroup
			FROM #tmpPivIMWE piv
				JOIN dbo.bPMCO m ON m.PMCo = piv.PMCo
				JOIN dbo.bHQCO h ON m.APCo = h.HQCo
			WHERE piv.VendorGroup IS NULL
				OR ISNULL(@OverwriteVendorGroupYN, 'Y') = 'Y'
		END
		
		--set default APCo
		IF @ynAPCo = 'Y' 
		BEGIN 
			UPDATE piv
			SET APCo = m.APCo
			FROM #tmpPivIMWE piv
				JOIN dbo.bPMCO m ON m.PMCo = piv.PMCo
			WHERE piv.APCo IS NULL
				OR ISNULL(@OverwriteAPCoYN, 'Y') = 'Y'
		END

		-- set default ApprovingFirm
		IF @ynApprovingFirm = 'Y' 
		BEGIN 
			UPDATE piv
			SET ApprovingFirm = p.SubmittalApprovingFirm
			FROM #tmpPivIMWE piv
				left join dbo.JCJMPM p on p.JCCo=piv.PMCo and p.Project=piv.Project
			WHERE piv.ApprovingFirm IS NULL
				OR ISNULL(@OverwriteApprovingFirmYN, 'Y') = 'Y'
		END

		-- set default ApprovingFirmContact
		IF @ynApprovingFirmContact = 'Y' 
		BEGIN 
			UPDATE piv
			SET ApprovingFirmContact = p.SubmittalApprovingFirmContact
			FROM #tmpPivIMWE piv
				left join dbo.JCJMPM p on p.JCCo=piv.PMCo and p.Project=piv.Project
			WHERE piv.ApprovingFirmContact IS NULL
				OR ISNULL(@OverwriteApprovingFirmContactYN, 'Y') = 'Y'
		END
		
		--set default OurFirm use project OurFirm first PMCo OurFirm second
		IF @ynOurFirm = 'Y' 
		BEGIN 
			UPDATE piv
			SET OurFirm = isnull(p.OurFirm,m.OurFirm)
			FROM #tmpPivIMWE piv
				JOIN dbo.PMCO m ON m.PMCo = piv.PMCo
				left join dbo.JCJMPM p on p.JCCo=piv.PMCo and p.Project=piv.Project
			WHERE piv.OurFirm IS NULL
				OR ISNULL(@OverwriteOurFirmYN, 'Y') = 'Y'
		END
		
		-- set seq
        IF (@ynSeq = 'Y')
	    BEGIN
		      UPDATE #tmpPivIMWE SET Seq=isnull(p.Seq,0)+RecordSeq
		      FROM #tmpPivIMWE t
		      LEFT JOIN (select PMCo,Project,max(Seq) as Seq
		      from PMSubmittal
		      group by PMCo,Project
		      )p on p.PMCo=t.PMCo and p.Project=t.Project
		      WHERE t.Seq is null OR ISNULL(@OverwriteSeqYN, 'Y') = 'Y'
		END
		
		--use cursor to validate the rest of our fields
		BEGIN -- block the cursor for rollups
			
				
			DECLARE curDefaultPMSubmittal CURSOR LOCAL FAST_FORWARD FOR
			SELECT tmpID, RecordSeq, PMCo,Project,Seq,Package,PackageRev,[Status],
			     VendorGroup,ApprovingFirm,ApprovingFirmContact,OurFirm,OurFirmContact,ResponsibleFirm,
			     ResponsibleFirmContact,APCo,Subcontract,PurchaseOrder,DocumentType
			FROM #tmpPivIMWE
			
			DECLARE @tmpID int,
					@currrecseq int,
					@pmco bCompany,
					@apco bCompany,
					@seq int,
					@project bProject,
					@package bDocument,
					@packagerev varchar(5),
					@status varchar(6),
					@vendorgroup bGroup,
					@approvingfirm bFirm,
					@approvingfirmcontact bEmployee,
					@ourfirm bFirm,
					@ourfirmcontact bEmployee,
					@responsiblefirm bFirm,
					@responsiblefirmcontact bEmployee,
					@sl VARCHAR(30),
					@po VARCHAR(30),
					@documenttype bDocType
					
			
			OPEN curDefaultPMSubmittal
			FETCH NEXT FROM curDefaultPMSubmittal INTO
			  @tmpID,@currrecseq,@pmco,@project,@seq,@package,@packagerev,@status,
			  @vendorgroup,@approvingfirm,@approvingfirmcontact,@ourfirm,@ourfirmcontact,@responsiblefirm,
			  @responsiblefirmcontact,@apco,@sl,@po,@documenttype
				WHILE @@FETCH_STATUS = 0
				BEGIN

				    -- valid project is required
				    exec @recode = vspPMProjectVal @pmco,@project,'0;1;2;3',null,null,null,
					null,null,null,null,null,null,null,null,null,
					null,null,null,null,null,null,null,null,@msg output
					IF @recode <> 0 
					BEGIN
						SELECT  @rcode = 1,@msg='Company'+convert(varchar(max),isnull(@pmco,''))+
						                   ',Project:'+isnull(@project,'')+','+
						                   isnull(@msg,'')

						INSERT  INTO dbo.IMWM
								( ImportId,
								  ImportTemplate,
								  Form,
								  RecordSeq,
								  Error,
								  [Message],
								  Identifier
								)
						VALUES  ( @ImportId,
								  @ImportTemplate,
								  @Form,
								  @currrecseq,
								  @recode,
								  @msg,
								  null
								)
					END
					--validate package/revision if either is present in the data
					IF ISNULL(@package,'')<>'' or ISNULL(@packagerev,'')<>'' 
					BEGIN
						EXEC @recode = vspPMSubmittalCreateRevisionPackageRevVal @pmco,@project,@package,@packagerev,@msg OUTPUT
						IF @recode <> 0 
						BEGIN
							SELECT  @rcode = 1,@msg='Company'+convert(varchar(max),isnull(@pmco,''))+
											   ',Project:'+isnull(@project,'')+
											   ',Package:'+isnull(@package,'')+
											   ',Revision:'+isnull(@packagerev,'')+','+
											   isnull(@msg,'')

							INSERT  INTO dbo.IMWM
									( ImportId,
									  ImportTemplate,
									  Form,
									  RecordSeq,
									  Error,
									  [Message],
									  Identifier
									)
							VALUES  ( @ImportId,
									  @ImportTemplate,
									  @Form,
									  @currrecseq,
									  @recode,
									  @msg,
									  null
									)
						END
					END
					
					--validate Status
					IF ISNULL(@status,'')<>'' 
					BEGIN
						EXEC @recode = bspPMStatusCodeVal @status,'SBMTL',null,@msg OUTPUT
						IF @recode <> 0 
						BEGIN
							SELECT  @rcode = 1,@msg='Company'+convert(varchar(max),isnull(@pmco,''))+
											   ',Project:'+isnull(@project,'')+
											   ',Status:'+isnull(@status,'')+','+
											   isnull(@msg,'')
							INSERT  INTO dbo.IMWM
									( ImportId,
									  ImportTemplate,
									  Form,
									  RecordSeq,
									  Error,
									  [Message],
									  Identifier
									)
							VALUES  ( @ImportId,
									  @ImportTemplate,
									  @Form,
									  @currrecseq,
									  @recode,
									  @msg,
									  null
									)
						END
					END
					
					--validate ApprovingFirm
					IF ISNULL(@approvingfirm,'')<>'' 
					BEGIN
						EXEC @recode = bspPMFirmVal @vendorgroup,@approvingfirm,null,null,@msg OUTPUT
						IF @recode <> 0 
						BEGIN
							SELECT  @rcode = 1,@msg='Company'+convert(varchar(max),isnull(@pmco,''))+
											   ',Project:'+isnull(@project,'')+
											   ',VendorGroup:'+convert(varchar(max),isnull(@vendorgroup,''))+
											   ',ApprovingFirm:'+convert(varchar(max),isnull(@approvingfirm,''))+','+
											  isnull(@msg,'')
							INSERT  INTO dbo.IMWM
									( ImportId,
									  ImportTemplate,
									  Form,
									  RecordSeq,
									  Error,
									  [Message],
									  Identifier
									)
							VALUES  ( @ImportId,
									  @ImportTemplate,
									  @Form,
									  @currrecseq,
									  @recode,
									  @msg,
									  null
									)
						END
					END
					
					--validate ApprovingFirmContact
					IF ISNULL(@approvingfirmcontact,'')<>'' 
					BEGIN
						EXEC @recode = vspPMFirmContactVal @vendorgroup,@approvingfirm,@approvingfirmcontact,null,@msg OUTPUT
						IF @recode <> 0 
						BEGIN
							SELECT  @rcode = 1,@msg='Company'+convert(varchar(max),isnull(@pmco,''))+
											   ',Project:'+isnull(@project,'')+
											   ',VendorGroup:'+convert(varchar(max),isnull(@vendorgroup,''))+
											   ',ApprovingFirm:'+convert(varchar(max),isnull(@approvingfirm,''))+
											   ',ApprovingFirmContact:'+convert(varchar(max),isnull(@approvingfirmcontact,''))+','+
											  isnull(@msg,'')
							INSERT  INTO dbo.IMWM
									( ImportId,
									  ImportTemplate,
									  Form,
									  RecordSeq,
									  Error,
									  [Message],
									  Identifier
									)
							VALUES  ( @ImportId,
									  @ImportTemplate,
									  @Form,
									  @currrecseq,
									  @recode,
									  @msg,
									  null
									)
						END
					END
					--validate OurFirm
					IF ISNULL(@ourfirm,'')<>'' 
					BEGIN
						EXEC @recode = bspPMFirmVal @vendorgroup,@ourfirm,null,null,@msg OUTPUT
						IF @recode <> 0 
						BEGIN
							SELECT  @rcode = 1,@msg='Company'+convert(varchar(max),isnull(@pmco,''))+
											   ',Project:'+isnull(@project,'')+
											   ',VendorGroup:'+convert(varchar(max),isnull(@vendorgroup,''))+
											   ',OurFirm:'+convert(varchar(max),isnull(@ourfirm,''))+','+
											  isnull(@msg,'')
							INSERT  INTO dbo.IMWM
									( ImportId,
									  ImportTemplate,
									  Form,
									  RecordSeq,
									  Error,
									  [Message],
									  Identifier
									)
							VALUES  ( @ImportId,
									  @ImportTemplate,
									  @Form,
									  @currrecseq,
									  @recode,
									  @msg,
									  null
									)
						END
					END
					--validate OurFirmContact
					IF ISNULL(@ourfirmcontact,'')<>'' 
					BEGIN
						EXEC @recode = vspPMFirmContactVal @vendorgroup,@ourfirm,@ourfirmcontact,null,@msg OUTPUT
						IF @recode <> 0 
						BEGIN
							SELECT  @rcode = 1,@msg='Company'+convert(varchar(max),isnull(@pmco,''))+
											   ',Project:'+isnull(@project,'')+
											   ',VendorGroup:'+convert(varchar(max),isnull(@vendorgroup,''))+
											   ',OurFirm:'+convert(varchar(max),isnull(@ourfirm,''))+
											   ',OurFirmContact:'+convert(varchar(max),isnull(@ourfirmcontact,''))+','+
											   isnull(@msg,'')
							INSERT  INTO dbo.IMWM
									( ImportId,
									  ImportTemplate,
									  Form,
									  RecordSeq,
									  Error,
									  [Message],
									  Identifier
									)
							VALUES  ( @ImportId,
									  @ImportTemplate,
									  @Form,
									  @currrecseq,
									  @recode,
									  @msg,
									  null
									)
						END
					END
					--validate ResponsibleFirm
					IF ISNULL(@responsiblefirm,'')<>'' 
					BEGIN
						EXEC @recode = bspPMFirmVal @vendorgroup,@responsiblefirm,null,null,@msg OUTPUT
						IF @recode <> 0 
						BEGIN
							SELECT  @rcode = 1,@msg='Company'+convert(varchar(max),isnull(@pmco,''))+
											   ',Project:'+isnull(@project,'')+
											   ',VendorGroup:'+convert(varchar(max),isnull(@vendorgroup,''))+
											   ',ResponsibleFirm:'+convert(varchar(max),isnull(@responsiblefirm,''))+','+
											   isnull(@msg,'')
							INSERT  INTO dbo.IMWM
									( ImportId,
									  ImportTemplate,
									  Form,
									  RecordSeq,
									  Error,
									  [Message],
									  Identifier
									)
							VALUES  ( @ImportId,
									  @ImportTemplate,
									  @Form,
									  @currrecseq,
									  @recode,
									  @msg,
									  null
									)
						END
					END					
					--validate ResponsibleFirmContact
					IF ISNULL(@responsiblefirmcontact,'')<>'' 
					BEGIN
						EXEC @recode = vspPMFirmContactVal @vendorgroup,@responsiblefirm,@responsiblefirmcontact,null,@msg OUTPUT
						IF @recode <> 0 
						BEGIN
							SELECT  @rcode = 1,@msg='Company'+convert(varchar(max),isnull(@pmco,''))+
											   ',Project:'+isnull(@project,'')+
											   ',VendorGroup:'+convert(varchar(max),isnull(@vendorgroup,''))+
											   ',ResponsibleFirm:'+convert(varchar(max),isnull(@responsiblefirm,''))+
											   ',ResponsibleFirmContact:'+convert(varchar(max),isnull(@responsiblefirmcontact,''))+','+
											   isnull(@msg,'')
							INSERT  INTO dbo.IMWM
									( ImportId,
									  ImportTemplate,
									  Form,
									  RecordSeq,
									  Error,
									  [Message],
									  Identifier
									)
							VALUES  ( @ImportId,
									  @ImportTemplate,
									  @Form,
									  @currrecseq,
									  @recode,
									  @msg,
									  null
									)
						END
					END					
					--validate Subcontract
					IF ISNULL(@sl,'')<>'' 
					BEGIN
						EXEC @recode = vspSLValForPMOL @pmco,@apco,@sl,@project,null,null,null,@vendorgroup,
						'Y',null,null,null,null,null,null,null,null,null,null,null,@msg output
 						IF @recode <> 0 
						BEGIN
							SELECT  @rcode = 1,@msg='Company'+convert(varchar(max),isnull(@pmco,''))+
											   ',Project:'+isnull(@project,'')+
											   ',VendorGroup:'+convert(varchar(max),isnull(@vendorgroup,''))+
											   ',SubContract:'+convert(varchar(max),isnull(@sl,''))+
											   isnull(@msg,'')
							INSERT  INTO dbo.IMWM
									( ImportId,
									  ImportTemplate,
									  Form,
									  RecordSeq,
									  Error,
									  [Message],
									  Identifier
									)
							VALUES  ( @ImportId,
									  @ImportTemplate,
									  @Form,
									  @currrecseq,
									  @recode,
									  @msg,
									  null
									)
						END
					END	
					
					--validate PurchaseOrder
					IF ISNULL(@po,'')<>'' 
					BEGIN
						EXEC @recode = vspPMPCOValForPO @pmco,@apco,@po,@project,null,null,null,@vendorgroup,
						null,null,null,null,null,null,null,null,null,null,null,null,@msg output
	
 						IF @recode <> 0 
						BEGIN
							SELECT  @rcode = 1,@msg='Company'+convert(varchar(max),isnull(@pmco,''))+
											   ',Project:'+isnull(@project,'')+
											   ',VendorGroup:'+convert(varchar(max),isnull(@vendorgroup,''))+
											   ',PurchaseOrder:'+convert(varchar(max),isnull(@po,''))+
											   isnull(@msg,'')
							INSERT  INTO dbo.IMWM
									( ImportId,
									  ImportTemplate,
									  Form,
									  RecordSeq,
									  Error,
									  [Message],
									  Identifier
									)
							VALUES  ( @ImportId,
									  @ImportTemplate,
									  @Form,
									  @currrecseq,
									  @recode,
									  @msg,
									  null
									)
						END
					END	
					
					--validate DocumentType
					IF ISNULL(@documenttype,'')<>'' 
					BEGIN
						EXEC @recode = bspPMDocTypeVal @documenttype,'SBMTL',null,null,@msg output
	
 						IF @recode <> 0 
						BEGIN
							SELECT  @rcode = 1,@msg='Company'+convert(varchar(max),isnull(@pmco,''))+
											   ',Project:'+isnull(@project,'')+
											   ',DocumentType:'+isnull(@documenttype,'')+','+
											   isnull(@msg,'')
							INSERT  INTO dbo.IMWM
									( ImportId,
									  ImportTemplate,
									  Form,
									  RecordSeq,
									  Error,
									  [Message],
									  Identifier
									)
							VALUES  ( @ImportId,
									  @ImportTemplate,
									  @Form,
									  @currrecseq,
									  @recode,
									  @msg,
									  null
									)
						END
					END	
					
				FETCH NEXT FROM curDefaultPMSubmittal INTO
				  @tmpID,@currrecseq,@pmco,@project,@seq,@package,@packagerev,@status,
				  @vendorgroup,@approvingfirm,@approvingfirmcontact,@ourfirm,@ourfirmcontact,@responsiblefirm,
				  @responsiblefirmcontact,@apco,@sl,@po,@documenttype
				END -- While
			CLOSE curDefaultPMSubmittal
			DEALLOCATE curDefaultPMSubmittal
		END -- end the cursor
  
	-- write the temp table back to IMWE
	-- we need to depivot the temp table here to get it in the right format to write it back
	-- because unpivot removes null rows, I'm going to update IMWE to null first
	UPDATE i
	SET UploadVal = NULL
	FROM  dbo.bIMWE i
		JOIN dbo.bDDUD b ON b.Identifier = i.Identifier
							AND b.Form = i.Form
		JOIN #tblCols c ON c.ColumnName = b.ColumnName 
	WHERE i.ImportId = @ImportId
					AND i.ImportTemplate = @ImportTemplate
					AND i.Form = @Form
					
	UPDATE dbo.bIMWE
	SET UploadVal = unpiv.UploadVal
	FROM 
	(SELECT 
			RecordSeq,
			TableName,
			PMCo,Project,Seq,SubmittalNumber,SubmittalRev,Package,PackageRev,
						[Description],Details,DocumentType,[Status],SpecSection,Copies,ApprovingFirm,
						ApprovingFirmContact,OurFirm,OurFirmContact,ResponsibleFirm,ResponsibleFirmContact,APCo,Subcontract,
						PurchaseOrder,ActivityID,ActivityDescription,ActivityDate,VendorGroup,DueToResponsibleFirm,
						SentToResponsibleFirm,DueFromResponsibleFirm,ReceivedFromResponsibleFirm,
						ReturnedToResponsibleFirm,DueToApprovingFirm,SentToApprovingFirm,DueFromApprovingFirm,
						ReceivedFromApprovingFirm,LeadDays1,LeadDays2,LeadDays3,Notes
		FROM #tmpPivIMWE ) piv
		UNPIVOT 
			(UploadVal FOR ColumnName IN (
						PMCo,Project,Seq,SubmittalNumber,SubmittalRev,Package,PackageRev,
						[Description],Details,DocumentType,[Status],SpecSection,Copies,ApprovingFirm,
						ApprovingFirmContact,OurFirm,OurFirmContact,ResponsibleFirm,ResponsibleFirmContact,APCo,Subcontract,
						PurchaseOrder,ActivityID,ActivityDescription,ActivityDate,VendorGroup,DueToResponsibleFirm,
						SentToResponsibleFirm,DueFromResponsibleFirm,ReceivedFromResponsibleFirm,
						ReturnedToResponsibleFirm,DueToApprovingFirm,SentToApprovingFirm,DueFromApprovingFirm,
						ReceivedFromApprovingFirm,LeadDays1,LeadDays2,LeadDays3,Notes
											)
	) unpiv
	JOIN dbo.bDDUD b ON b.TableName = unpiv.TableName
						AND b.ColumnName = unpiv.ColumnName
						AND b.Form = @Form
	JOIN dbo.bIMWE i ON b.Form = i.Form
						AND b.Identifier = i.Identifier
						AND i.ImportTemplate = @ImportTemplate
						AND i.RecordSeq = unpiv.RecordSeq
						AND i.ImportId = @ImportId
						
											
    --clean up our temp table      			
	DROP TABLE #tmpPivIMWE
	DROP TABLE #tblCols

	bspexit:

	SELECT  @msg = ISNULL(@desc, 'PM Submittal Register') + CHAR(13) + CHAR(10)
			+ '[vspIMBidtekDefaultsPMSubmittal]'

	RETURN @rcode

END


GO
GRANT EXECUTE ON  [dbo].[vspIMBidtekDefaultsPMSubmittal] TO [public]
GO
