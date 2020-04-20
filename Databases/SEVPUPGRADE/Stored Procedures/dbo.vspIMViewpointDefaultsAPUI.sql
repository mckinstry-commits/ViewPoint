SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspIMViewpointDefaultsAPUI]
/***********************************************************
* CREATED BY: TJL 05/15/09 - Issue #25567, Create new Import for AP Unapproved
* MODIFIED BY: 
*				CC  05/29/09 - Issue #133516 - Correct defaulting of Company
*				MV	10/19/09 - #131826 - default vendor PayControl
*				GF  09/15/2010 - issue #141031 changed to use vfDateOnly and vfDateOnlyMonth
*				AMR 01/17/11 - #142350, making case insensitive by removing unused vars and renaming same named variables-  
*	
*
*
* Usage:
*	Used by Imports to create values for needed or missing
*      data based upon Bidtek default rules.
*
* Input params:
*	@ImportId	Import Identifier
*	@ImportTemplate	Import ImportTemplate
*
* Output params:
*	@msg		error message
*
* Return code:
*	0 = success, 1 = failure
************************************************************/
    
(@Company bCompany, @ImportId varchar(20), @ImportTemplate varchar(20), @Form varchar(20), @rectype varchar(30), @msg varchar(120) output)

as

set nocount on

/* Column ID's */
declare @rcode int, @recode int, @desc varchar(120), @CompanyID int, @vendorgroupid int, @discdateid int, @invdateID int,
	@duedateid int, @paymethodid int, @cmcoid int, @cmacctid int, @v1099ynid int, @v1099typeid int, @v1099boxid int, 
	@payoverrideynid int, @separatepayynid int, @uimthid int, @reviewergroupid int, @zinvtotalid int,
	@nv1099ynid int, @npayoverrideynid int, @nseparatepayynid int, @paycontrolid int
	
/* Working variables */   
-- renaming @v1099yn,@v1099type,@v1099box
DECLARE @Co bCompany,
		@UIMth varchar(20),
		@UISeq smallint,
		@VendorGroup bGroup,
		@Vendor bVendor,
		@InvDate bDate,
		@PayMethod char,
		@CMCo bCompany,
		@CMAcct bCMAcct,
		@V1099YN bYN,
		@V1099Type varchar(10),
		@V1099Box tinyint,
		@PayOverrideYN bYN,
		@PayName varchar(60),
		@PayAddress varchar(60),
		@PayCity varchar(30),
		@PayState bState,
		@PayZip bZip,
		@PayAddInfo varchar(60),
		@payterms bPayTerms,
		@V1099YNWV bYN,
		@V1099TYPEWV varchar(10),
		@V1099BOXWV tinyint,
		@apvmcmacct bCMAcct,
		@discdate bDate,
		@duedate bDate,
		@discrate bUnitCost,
		@separatepayyn bYN,
		@APVMEFT char(1),
		@dmth bDate,
		@ReviewerGroup bGroup,
		@apvmpaycontrol varchar(10)

/* Cursor variables */
declare @Recseq int, @Tablename varchar(20), @Column varchar(30), @Uploadval varchar(60), @Ident int,
	@valuelist varchar(255), @complete int, @counter int, @oldrecseq int, @currrecseq int
           
if @ImportId is null
	begin
	select @desc = 'Missing ImportId.', @rcode = 1
	goto vspexit
	end
if @ImportTemplate is null
	begin
	select @desc = 'Missing ImportTemplate.', @rcode = 1
	goto vspexit
	end
if @Form is null
	begin
	select @desc = 'Missing Form.', @rcode = 1
	goto vspexit
	end

/****************************************************************************************
*																						*
*			RECORDS ALREADY EXIST IN THE IMWE TABLE FROM THE IMPORTED TEXTFILE			*
*																						*
*			All records with the same RecordSeq represent a single import record		*
*																						*
****************************************************************************************/

/* Check ImportTemplate detail for existence of columns to be defaulted Defaults */
/* REM'D BECAUSE:  We cannot assume that user has imported every non-nullable value required by the table.
   If we exit this routine, then any non-nullable fields without an imported value will cause a
   table constraint error during the final upload process.  This procedure should provide enough
   defaults to SAVE the record, without error, if the import has not done so. */ 
--select IMTD.DefaultValue
--from IMTD with (nolock)
--Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'
--	and IMTD.RecordType = @rectype
--if @@rowcount = 0
--	begin
--	select @desc='No Bidtek Defaults set up for ImportTemplate ' + @ImportTemplate +'.'
--	goto vspexit
--	end

/* Not all fields are overwritable even though the template would indicate they are (Due to the presence of a checkbox).
   Only those fields that can likely be imported and where we can provide a useable default value will get processed here 
   as overwritable. The following list does not contain all fields shown on the Template Detail.  This can be modified as the need arises.
   Example:  UISeq is very unlikely to be provided by the import text file.  Therefore there is nothing to overwrite. */
DECLARE	@OverwriteCo 	 				bYN
		,@OverwriteUIMth				bYN
		,@OverwriteVendorGroup 	 		bYN
		,@OverwriteInvDate 	 			bYN
		,@OverwriteDiscDate 			bYN
		,@OverwriteDueDate 	 			bYN
		,@OverwritePayMethod 			bYN
		,@OverwriteCMCo 	 			bYN
		,@OverwriteCMAcct 	 			bYN
		,@OverwriteSeparatePayYN 		bYN
		,@OverwriteV1099YN 	 	 		bYN
		,@OverwriteV1099Type 	 		bYN
		,@OverwriteV1099Box 	 		bYN
		,@OverwritePayOverrideYN 		bYN
		,@OverwritePayControl			bYN

/* This is pretty much a mirror of the list above EXCEPT it excludes those columns that will be defaulted 
   as a record set and do not need to be defaulted per individual import record.  */	
DECLARE @IsVendorGroupEmpty 	 		bYN
		,@IsDiscDateEmpty 		 		bYN
		,@IsDueDateEmpty 		 		bYN
		,@IsPayMethodEmpty 		 		bYN
		,@IsCMCoEmpty 			 		bYN
		,@IsCMAcctEmpty 			 	bYN
		,@IsSeparatePayYNEmpty 	 		bYN
		,@IsV1099YNEmpty 		 		bYN
		,@IsV1099TypeEmpty 		 		bYN
		,@IsV1099BoxEmpty 		 		bYN
		,@IsPayOverrideYNEmpty 	 		bYN
		,@IsPayControlEmpty 	 		bYN

/* Return Overwrite value from Template. */	
SELECT @OverwriteCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'APCo', @rectype);
SELECT @OverwriteUIMth = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'UIMth', @rectype);
SELECT @OverwriteVendorGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'VendorGroup', @rectype);
SELECT @OverwriteInvDate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'InvDate', @rectype);
SELECT @OverwriteDiscDate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'DiscDate', @rectype);
SELECT @OverwriteDueDate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'DueDate', @rectype);
SELECT @OverwritePayMethod = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PayMethod', @rectype);
SELECT @OverwriteCMCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CMCo', @rectype);
SELECT @OverwriteCMAcct = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CMAcct', @rectype);
SELECT @OverwriteSeparatePayYN = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'SeparatePayYN', @rectype);
SELECT @OverwriteV1099YN = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'V1099YN', @rectype);
SELECT @OverwriteV1099Type = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'V1099Type', @rectype);
SELECT @OverwriteV1099Box = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'V1099Box', @rectype);
SELECT @OverwritePayOverrideYN = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PayOverrideYN', @rectype);
SELECT @OverwritePayControl = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PayControl', @rectype);

/* There are some columns that can be updated to ALL imported records as a set.  The value is NOT
   unique to the individual imported record. */
select @CompanyID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'APCo', @rectype, 'N')		--Non-Nullable
select @uimthid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'UIMth', @rectype, 'N')		--Non-Nullable
select @invdateID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'InvDate', @rectype, 'Y')

--APCo
if @CompanyID IS NOT NULL AND (ISNULL(@OverwriteCo, 'Y') = 'Y')
	begin
	--'Use Viewpoint Default' = Y and 'Overwrite Import Value' = Y  (Set ALL import records to this Company)
	Update IMWE
	SET IMWE.UploadVal = @Company
	where IMWE.ImportTemplate=@ImportTemplate and
		IMWE.ImportId=@ImportId and IMWE.Identifier = @CompanyID and IMWE.RecordType = @rectype
  	end

if @CompanyID IS NOT NULL AND (ISNULL(@OverwriteCo, 'Y') = 'N')
	begin
	--'Use Viewpoint Default' = Y and 'Overwrite Import Value' = N  (Set to this Company only if no import value exists)
	Update IMWE
	SET IMWE.UploadVal = @Company
	where IMWE.ImportTemplate=@ImportTemplate and
		IMWE.ImportId=@ImportId and IMWE.Identifier = @CompanyID and IMWE.RecordType = @rectype
		AND IMWE.UploadVal IS NULL
  	end

--UIMth
----#141031
SET @UIMth = CONVERT(VARCHAR(20), dbo.vfDateOnlyMonth(),101)
--select @dmth = convert(varchar(2), month(getxdate())) + '/1/' + convert(varchar(4),year(getxdate()))
--select @UIMth = convert(varchar(20),@dmth,101)
if ISNULL(@uimthid, 0)<> 0 AND (ISNULL(@OverwriteUIMth, 'Y') = 'Y')
	begin
	Update IMWE
	SET IMWE.UploadVal = @UIMth
	where IMWE.ImportTemplate=@ImportTemplate and
		IMWE.ImportId=@ImportId and IMWE.Identifier = @uimthid and IMWE.RecordType = @rectype
  	end

if ISNULL(@uimthid, 0)<> 0 AND (ISNULL(@OverwriteUIMth, 'Y') = 'N')
	begin
	Update IMWE
	SET IMWE.UploadVal = @UIMth
	where IMWE.ImportTemplate=@ImportTemplate and
		IMWE.ImportId=@ImportId and IMWE.Identifier = @uimthid and IMWE.RecordType = @rectype
		AND IMWE.UploadVal IS NULL
  	end
  	
--Invoice Date
if isnull(@invdateID,0) <> 0 AND (ISNULL(@OverwriteInvDate , 'Y') = 'Y')
	begin
	UPDATE IMWE
	----#141031
	SET IMWE.UploadVal = convert(varchar(20), dbo.vfDateOnly(),101)		--Invoice Date = Todays Date
	where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @invdateID
		and IMWE.RecordType = @rectype
	end
	
if isnull(@invdateID,0) <> 0 AND (ISNULL(@OverwriteInvDate , 'Y') = 'N')
	begin
	UPDATE IMWE
	----#141031
	SET IMWE.UploadVal = convert(varchar(20), dbo.vfDateOnly(),101)		--Invoice Date = Todays Date
	where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @invdateID
		and IMWE.RecordType = @rectype
		AND IMWE.UploadVal IS NULL
	end

/***** GET COLUMN IDENTIFIERS - Identifier will be returned ONLY when 'Use Viewpoint Default' is set. *******/ 
select @discdateid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'DiscDate', @rectype, 'Y')
select @duedateid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'DueDate', @rectype, 'Y')
select @cmacctid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CMAcct', @rectype, 'Y')
select @separatepayynid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'SeparatePayYN', @rectype, 'Y')
select @v1099ynid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'V1099YN', @rectype, 'Y')
select @v1099typeid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'V1099Type', @rectype, 'Y')
select @v1099boxid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'V1099Box', @rectype, 'Y')
select @payoverrideynid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PayOverrideYN', @rectype, 'Y')
select @paycontrolid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PayControl', @rectype, 'Y')


/***** GET COLUMN IDENTIFIERS - Identifier will be returned regardless of 'Use Viewpoint Default' setting. *******/ 
select @vendorgroupid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'VendorGroup', @rectype, 'N')	--Non-Nullable
select @paymethodid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PayMethod', @rectype, 'N')		--Non-Nullable
select @cmcoid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CMCo', @rectype, 'N')					--Non-Nullable

--Used to set required columns to ZERO when not otherwise set by a default. (Cleanup: See end of procedure) 
select @zinvtotalid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'InvTotal', @rectype, 'N')

--Used to set required columns to 'N' when not otherwise set by a default. (Cleanup: See end of procedure)        
select @nv1099ynid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'V1099YN', @rectype, 'N')
select @nseparatepayynid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'SeparatePayYN', @rectype, 'N')
select @npayoverrideynid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PayOverrideYN', @rectype, 'N')

/* Begin default process.  Different concept here.  Multiple cursor records make up a single Import record
   determined by a change in the RecSeq value.  New RecSeq signals the beginning of the next Import record. */
declare WorkEditCursor cursor local fast_forward for
select IMWE.RecordSeq, IMWE.Identifier, DDUD.TableName, DDUD.ColumnName, IMWE.UploadVal
from IMWE with (nolock)
inner join DDUD with (nolock) on IMWE.Identifier = DDUD.Identifier and DDUD.Form = IMWE.Form
where IMWE.ImportId = @ImportId and IMWE.ImportTemplate = @ImportTemplate and IMWE.Form = @Form and
	IMWE.RecordType = @rectype
Order by IMWE.RecordSeq, IMWE.Identifier
    
open WorkEditCursor

fetch next from WorkEditCursor into @Recseq, @Ident, @Tablename, @Column, @Uploadval
    
select @currrecseq = @Recseq, @complete = 0, @counter = 1

-- while cursor is not empty
while @complete = 0
    begin
    
	if @@fetch_status <> 0 select @Recseq = -1

	if @Recseq = @currrecseq	--Moves on to defaulting process when the first record of a DIFFERENT import RecordSeq is detected
		begin
		/************************** GET UPLOADED VALUES FOR THIS IMPORT RECORD *****************************/
		/* For each imported record:  (Each imported record has multiple records in the IMWE table representing columns of the import record)
	       Cursor will cycle through each column of an imported record and set the imported value into a variable
		   that could be used during the defaulting process later if desired.  
		   
		   The imported value here is only needed if the value will be used to help determine another
		   default value in some way. */
		If @Column='APCo' and isnumeric(@Uploadval) =1 select @Co = Convert(int, @Uploadval)
		If @Column='UIMth' and isdate(@Uploadval) =1 select @UIMth = Convert(smalldatetime, @Uploadval)
		If @Column='VendorGroup' and isnumeric(@Uploadval) =1 select @VendorGroup = Convert(int, @Uploadval)
		If @Column='Vendor' and isnumeric(@Uploadval) =1 select @Vendor = Convert(int, @Uploadval)
		If @Column='InvDate' and isdate(@Uploadval) =1 select @InvDate = Convert(smalldatetime, @Uploadval)
		If @Column='PayMethod' select @PayMethod = @Uploadval
		If @Column='PayName' select @PayName = @Uploadval
		If @Column='PayAddress' select @PayAddress = @Uploadval
		If @Column='PayCity' select @PayCity = @Uploadval
		If @Column='PayState' select @PayState = @Uploadval
 		If @Column='PayZip' select @PayZip = @Uploadval
		
		/* Set IsNull variable for later */
		IF @Column='VendorGroup' 
			IF @Uploadval IS NULL
				SET @IsVendorGroupEmpty = 'Y'
			ELSE
				SET @IsVendorGroupEmpty = 'N'
		IF @Column='DiscDate' 
			IF @Uploadval IS NULL
				SET @IsDiscDateEmpty = 'Y'
			ELSE
				SET @IsDiscDateEmpty = 'N'
		IF @Column='DueDate' 
			IF @Uploadval IS NULL
				SET @IsDueDateEmpty = 'Y'
			ELSE
				SET @IsDueDateEmpty = 'N'
		IF @Column='PayMethod' 
			IF @Uploadval IS NULL
				SET @IsPayMethodEmpty = 'Y'
			ELSE
				SET @IsPayMethodEmpty = 'N'
		IF @Column='CMCo' 
			IF @Uploadval IS NULL
				SET @IsCMCoEmpty = 'Y'
			ELSE
				SET @IsCMCoEmpty = 'N'
		IF @Column='CMAcct' 
			IF @Uploadval IS NULL
				SET @IsCMAcctEmpty = 'Y'
			ELSE
				SET @IsCMAcctEmpty = 'N'
		IF @Column='SeparatePayYN' 
			IF @Uploadval IS NULL
				SET @IsSeparatePayYNEmpty = 'Y'
			ELSE
				SET @IsSeparatePayYNEmpty = 'N'
		IF @Column='V1099YN' 
			IF @Uploadval IS NULL
				SET @IsV1099YNEmpty = 'Y'
			ELSE
				SET @IsV1099YNEmpty = 'N'
		IF @Column='V1099Type' 
			IF @Uploadval IS NULL
				SET @IsV1099TypeEmpty = 'Y'
			ELSE
				SET @IsV1099TypeEmpty = 'N'
		IF @Column='V1099Box' 
			IF @Uploadval IS NULL
				SET @IsV1099BoxEmpty = 'Y'
			ELSE
				SET @IsV1099BoxEmpty = 'N'
		IF @Column='PayOverrideYN' 
			IF @Uploadval IS NULL
				SET @IsPayOverrideYNEmpty = 'Y'
			ELSE
				SET @IsPayOverrideYNEmpty = 'N'
		IF @Column='PayControl' 
			IF @Uploadval IS NULL
				SET @IsPayControlEmpty = 'Y'
			ELSE
				SET @IsPayControlEmpty = 'N'
		
		if @@fetch_status <> 0 select @complete = 1		--This will be set only after ALL records in IMWE have been processed

		select @oldrecseq = @Recseq

		fetch next from WorkEditCursor into @Recseq, @Ident, @Tablename, @Column, @Uploadval
		end
	else
		begin
		/* A DIFFERENT import RecordSeq has been detected.  Before moving on, set the default values for our previous Import Record. */
		
		/*************************************** SET DEFAULT VALUES ****************************************/
		/* At this moment, all columns of a single imported record have been processed above.  The defaults for 
		   this single imported record will be set below before the cursor moves on to the columns of the next
		   imported record.  
		   
		   For the most part (There are some exceptions), if a column identifier is present ('Use Viewpoint Default = Y)
		   and the 'Overwrite Import Value' = Y OR if the actual imported value is empty, we will then set a bidtek 
		   default. */

  		--UISeq:  Non-Nullable (Must get generated as part of the upload process)
  		--						exec @recode = vspAPUIGetNextSeq @Co, @UIMth, @UISeq output, @msg output
  			
		--VendorGroup:  Non-Nullable
		if @vendorgroupid <> 0 AND (ISNULL(@OverwriteVendorGroup, 'Y') = 'Y' OR ISNULL(@IsVendorGroupEmpty, 'Y') = 'Y')
			begin
			select @VendorGroup = VendorGroup
			from HQCO with (nolock) 
			where HQCo = @Co

			UPDATE IMWE
			SET IMWE.UploadVal = @VendorGroup
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @vendorgroupid and IMWE.RecordType = @rectype
			end
  
		--Disc Date & Due Date based upon PayTerms
		select @payterms = PayTerms, @V1099YNWV = V1099YN, @V1099TYPEWV = V1099Type, @V1099BOXWV = V1099Box,
			@separatepayyn = SeparatePayInvYN, @apvmcmacct = CMAcct, @apvmpaycontrol = PayControl		
		from APVM with (nolock)
		where VendorGroup=@VendorGroup and Vendor = @Vendor

		select @discdate ='', @duedate ='', @discrate =0
    
		if isnull(@payterms,'') <> ''
			begin
			exec @recode = bspHQPayTermsDateCalc @payterms, @InvDate, @discdate output, @duedate output, @discrate output, @msg output
			end

		if @discdateid <> 0 and isnull(@discdate,'') <> '' AND (ISNULL(@OverwriteDiscDate, 'Y') = 'Y' OR ISNULL(@IsDiscDateEmpty, 'Y') = 'Y')
			begin
			UPDATE IMWE
			SET IMWE.UploadVal = convert(varchar(20),@discdate,101)
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @discdateid and IMWE.RecordType = @rectype
			end
    
    	if @duedateid <> 0 and isnull(@duedate,'') <> '' AND (ISNULL(@OverwriteDueDate, 'Y') = 'Y' OR ISNULL(@IsDueDateEmpty, 'Y') = 'Y')
			begin
			UPDATE IMWE
			SET IMWE.UploadVal = convert(varchar(20),@duedate,101)
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @duedateid and IMWE.RecordType = @rectype
			end
    
		--129286, If Due Date is set to default, but is blank, and pay terms are not set, 
		--then default the Due Date to the Invoice Date or current date if Invoice is blank
		IF @duedateid <> 0 AND ISNULL(@duedate,'') = '' AND ISNULL(@payterms,'') = ''
			BEGIN
			UPDATE IMWE
			----#141031
			SET IMWE.UploadVal = isnull(convert(varchar(20),@InvDate,101), convert(varchar(20), dbo.vfDateOnly(),101))
			WHERE IMWE.ImportTemplate=@ImportTemplate AND IMWE.ImportId=@ImportId AND IMWE.RecordSeq=@currrecseq
			AND IMWE.Identifier = @duedateid AND IMWE.RecordType = @rectype
			END
    
		--Pay Method:  Non-Nullable
    	if @paymethodid <> 0 AND (ISNULL(@OverwritePayMethod, 'Y') = 'Y' OR ISNULL(@IsPayMethodEmpty, 'Y') = 'Y' OR
    		@PayMethod = '') 
			begin
			select @PayMethod = 'C'
			--#25361, check EFT option in APVM.  According to MaryAnn, only type 'A' is EFT, otherwise check.
			select @APVMEFT = EFT 
			from APVM with (nolock) 
			where VendorGroup = @VendorGroup and Vendor = @Vendor
   
   			if isnull(@APVMEFT,'') = 'A' select @PayMethod = 'E'
    
			UPDATE IMWE
			SET IMWE.UploadVal = @PayMethod
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @paymethodid and IMWE.RecordType = @rectype
			end

		--CM Co:  Non-Nullable
    	if @cmcoid <> 0 AND (ISNULL(@OverwriteCMCo, 'Y') = 'Y' OR ISNULL(@IsCMCoEmpty, 'Y') = 'Y')
     		begin
			select @CMCo = CMCo
			from APCO with (nolock) where APCo = @Co
    
			UPDATE IMWE
			SET IMWE.UploadVal = @CMCo
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @cmcoid and IMWE.RecordType = @rectype
			end
    
		--CM Account
    	if @cmacctid <> 0 AND (ISNULL(@OverwriteCMAcct, 'Y') = 'Y' OR ISNULL(@IsCMAcctEmpty, 'Y') = 'Y')
			begin
			select @CMAcct = CMAcct
			from APCO with (nolock) where APCo = @Co
    
			UPDATE IMWE
			SET IMWE.UploadVal = isnull(@apvmcmacct, @CMAcct)
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @cmacctid and IMWE.RecordType = @rectype
			end

		--Pay Control
    	if @paycontrolid <> 0 AND (ISNULL(@OverwritePayControl, 'Y') = 'Y' OR ISNULL(@IsPayControlEmpty, 'Y') = 'Y')
			begin
			select @apvmpaycontrol = PayControl
			from APVM with (nolock) 
			where VendorGroup = @VendorGroup and Vendor = @Vendor
    
			UPDATE IMWE
			SET IMWE.UploadVal = @apvmpaycontrol
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @paycontrolid and IMWE.RecordType = @rectype
			end
    
		--Separate Pay
    	if @separatepayynid <> 0 AND (ISNULL(@OverwriteSeparatePayYN, 'Y') = 'Y' OR ISNULL(@IsSeparatePayYNEmpty, 'Y') = 'Y')
			begin
			UPDATE IMWE
			SET IMWE.UploadVal = isnull(@separatepayyn, 'N')
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @separatepayynid and IMWE.RecordType = @rectype
			end

		--V1099YN
    	if @v1099ynid <> 0 AND (ISNULL(@OverwriteV1099YN, 'Y') = 'Y' OR ISNULL(@IsV1099YNEmpty, 'Y') = 'Y') 
     		begin
			select @V1099YN = @V1099YNWV
    
			UPDATE IMWE
			SET IMWE.UploadVal = @V1099YN
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @v1099ynid and IMWE.RecordType = @rectype
			end
    
		--V1099Type
    	if @v1099typeid <> 0 AND (ISNULL(@OverwriteV1099Type, 'Y') = 'Y' OR ISNULL(@IsV1099TypeEmpty, 'Y') = 'Y') 
     		begin
			select @V1099Type = @V1099TYPEWV
    
			UPDATE IMWE
			SET IMWE.UploadVal = @V1099Type
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @v1099typeid and IMWE.RecordType = @rectype
			end
    
		--V1099Box
    	if @v1099boxid <> 0 AND (ISNULL(@OverwriteV1099Box, 'Y') = 'Y' OR ISNULL(@IsV1099BoxEmpty, 'Y') = 'Y')
     		begin
			select @V1099Box = @V1099BOXWV
    
			UPDATE IMWE
			SET IMWE.UploadVal = @V1099Box
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @v1099boxid and IMWE.RecordType = @rectype
			end
    
		--Pay Override
    	if @payoverrideynid <> 0 AND (ISNULL(@OverwritePayOverrideYN, 'Y') = 'Y' OR ISNULL(@IsPayOverrideYNEmpty, 'Y') = 'Y') 
     		begin
			select @PayOverrideYN = 'N'
			if isnull(@PayName,'')<> '' and isnull(@PayAddress,'')<>'' and isnull(@PayCity,'')<>'' and
				isnull(@PayState,'')<>'' and isnull(@PayZip,'')<>'' select @PayOverrideYN = 'Y'
    
			UPDATE IMWE
			SET IMWE.UploadVal = @PayOverrideYN
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @payoverrideynid and IMWE.RecordType = @rectype
			end
    
		select @currrecseq = @Recseq
		select @counter = @counter + 1
    
		end		--End SET DEFAULT VALUE process
    end		-- End @complete Loop, Last IMWE record has been processed

close WorkEditCursor
deallocate WorkEditCursor

/* Set required (dollar) inputs to 0 where not already set with some other value */          
UPDATE IMWE
SET IMWE.UploadVal = 0
where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId 
	and IMWE.RecordType = @rectype and isnull(IMWE.UploadVal,'')='' and
	(IMWE.Identifier = @zinvtotalid)

/* Set required (Y/N) inputs to 'N' where not already set with some other value */       
UPDATE IMWE
SET IMWE.UploadVal = 'N'
where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId 
	and IMWE.RecordType = @rectype and isnull(IMWE.UploadVal,'') not in ('N','Y') and
	(IMWE.Identifier = @nv1099ynid or IMWE.Identifier = @npayoverrideynid or IMWE.Identifier = @nseparatepayynid)
	
vspexit:
select @msg = isnull(@desc,'Header ') + char(13) + char(13) + '[vspIMViewpointDefaultsAPUI]'

return @rcode



GO
GRANT EXECUTE ON  [dbo].[vspIMViewpointDefaultsAPUI] TO [public]
GO
