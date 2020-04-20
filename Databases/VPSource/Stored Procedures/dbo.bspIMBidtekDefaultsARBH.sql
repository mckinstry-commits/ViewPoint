SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspIMBidtekDefaultsARBH]
/***********************************************************
* CREATED BY: Danf
* MODIFIED BY: DANF 05/13/03 - 20997  Add Default for Job Cost Company and AR Invoice number.
*		RBT 09/09/03 - 20131 Allow rectypes <> tablenames.
*		RBT 07/01/04 - 25010, fix Auto Invoice number default.
*		RBT 03/08/05 - 27338, set JCCo to null if Contract is null.
*		RBT 08/29/05 - 29652, fix Company so it doesn't always default.
*		RBT 01/26/06 - 120057, fix Company query to only return the 1 correct row.
*		CC	02/18/09 - Issue #24531 - Use default only if set to overwrite or value is null
*		CC  05/29/09 - Issue #133516 - Correct defaulting of Company
*		TJL 06/03/09 - Issue #133818 - Cleaned up while working on this issue.
*		GF 09/12/2010 - issue #141031 changed to use function vfDateOnly
*		AMR 01/12/11 - #142350 - making case insensitive 
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

/**************************************************************************************************************
*																											  *
*                      Not Designed for  Adjustment, Credit or WriteOffs at this time						  *
*																											  *
**************************************************************************************************************/

/* General Declares */
declare @rcode int, @recode int, @desc varchar(120), @defaultvalue varchar(30), @currrecseq int,
	@complete int, @counter int, @oldrecseq int
	
/* Column ID variables when based upon a 'bidtek' default setting - 'Use Viewpoint Default set 'Y' on Template. */
declare @CompanyID int, @SourceID int, @TransTypeid int, @TransDateID int, @ARTransTypeID int,
@custgroupid int, @paytermsid int, @rectypeid int, @discdateid int, @duedateid int,
@invoiceid int, @jccoid int, @jccoid2 int
	
/* Column ID variables when setting required field to Zero */

/* Working variables */ 
 
declare  @Co bCompany, @CustGroup bGroup, @Customer bCustomer, @RType tinyint, @JCCo bCompany, @Contract bContract, 
	@Invoice varchar(10), @TransDate bDate, @PayTerms bPayTerms, @lastinvoice varchar(10),
	@custpayterms bPayTerms, @custrectype tinyint, @conpayterms bPayTerms, @corectype tinyint, @discdate bDate, @duedate bDate, 
	@discrate bUnitCost
   
/* Cursor variables */
declare @Recseq int, @Tablename varchar(20), @Column varchar(30), @Uploadval varchar(60), @Ident int
                     
select @rcode = 0

if @ImportId is null
	begin
	select @desc = 'Missing ImportId.', @rcode = 1
	goto bspexit
	end
if @ImportTemplate is null
	begin
	select @desc = 'Missing ImportTemplate.', @rcode = 1
	goto bspexit
	end
if @Form is null
	begin
	select @desc = 'Missing Form.', @rcode = 1
	goto bspexit
	end
       
/****************************************************************************************
*																						*
*			RECORDS ALREADY EXIST IN THE IMWE TABLE FROM THE IMPORTED TEXTFILE			*
*																						*
*			All records with the same RecordSeq represent a single import record		*
*																						*
****************************************************************************************/       
-- Check ImportTemplate detail for columns to set Bidtek Defaults
/* REM'D BECAUSE:  We cannot assume that user has imported every non-nullable value required by the table.
   If we exit this routine, then any non-nullable fields without an imported value will cause a
   table constraint error during the final upload process.  This procedure should provide enough
   defaults to SAVE the record, without error, if the import has not done so. */       
--if not exists(select IMTD.DefaultValue From IMTD
--             Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'
--              and IMTD.RecordType = @rectype)
--goto bspexit
 
/* Not all fields are overwritable even though the template would indicate they are (Due to the presence of a checkbox).
   Only those fields that can likely be imported and where we can provide a useable default value will get processed here 
   as overwritable. The following list does not contain all fields shown on the Template Detail.  This can be modified as the need arises.
   Example:  UISeq is very unlikely to be provided by the import text file.  Therefore there is nothing to overwrite. */       
DECLARE @OverwriteSource 	 	 bYN
	, @OverwriteTransType 	 	 bYN
	, @OverwriteARTransType 	 bYN
	, @OverwriteTransDate 	 	 bYN
	, @OverwriteCustGroup 	 	 bYN
	, @OverwritePayTerms 	 	 bYN
	, @OverwriteRecType 	 	 bYN
	, @OverwriteDiscDate 	 	 bYN
	, @OverwriteDueDate 	 	 bYN
	, @OverwriteJCCo 	 		 bYN
	, @OverwriteInvoice 	 	 bYN
	, @OverwriteCo				 bYN

/* This is pretty much a mirror of the list above EXCEPT it can exclude those columns that will be defaulted 
   as a record set and do not need to be defaulted per individual import record.  */	
DECLARE @IsCustGroupEmpty 		 bYN
	,	@IsPayTermsEmpty 		 bYN
	,	@IsInvoiceEmpty 		 bYN
	,	@IsRecTypeEmpty 		 bYN
	,	@IsJCCoEmpty 			 bYN
	,	@IsDueDateEmpty 		 bYN
	,	@IsDiscDateEmpty 		 bYN

/* Return Overwrite value from Template. */	
SELECT @OverwriteSource = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Source', @rectype);
SELECT @OverwriteTransType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TransType', @rectype);
SELECT @OverwriteARTransType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ARTransType', @rectype);
SELECT @OverwriteTransDate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TransDate', @rectype);
SELECT @OverwriteCustGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CustGroup', @rectype);
SELECT @OverwritePayTerms = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PayTerms', @rectype);
SELECT @OverwriteRecType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'RecType', @rectype);
SELECT @OverwriteDiscDate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'DiscDate', @rectype);
SELECT @OverwriteDueDate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'DueDate', @rectype);
SELECT @OverwriteJCCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'JCCo', @rectype);
SELECT @OverwriteInvoice = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Invoice', @rectype);   
SELECT @OverwriteCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Co', @rectype);   
       
/* There are some columns that can be updated to ALL imported records as a set.  The value is NOT
   unique to the individual imported record. */
select @CompanyID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Co', @rectype, 'N')				--Non-Nullable   
select @TransTypeid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'TransType', @rectype, 'N')	--Non-Nullable 
select @SourceID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Source', @rectype, 'N')			--Non-Nullable
select @ARTransTypeID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ARTransType', @rectype, 'N')--Non-Nullable
select @TransDateID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'TransDate', @rectype, 'N')	--Non-Nullable
                       
--Co:	ARTH Non-Nullable
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
 
--TransType:	ARBH Non-Nullable
if isnull(@TransTypeid,0) <> 0  AND (ISNULL(@OverwriteTransType, 'Y') = 'Y')
	begin
	UPDATE IMWE
	SET IMWE.UploadVal = 'A'
	where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @TransTypeid
		and IMWE.RecordType = @rectype
	end

if isnull(@TransTypeid,0) <> 0  AND (ISNULL(@OverwriteTransType, 'Y') = 'N')
	begin
	UPDATE IMWE
	SET IMWE.UploadVal = 'A'
	where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @TransTypeid
	and IMWE.RecordType = @rectype
	AND IMWE.UploadVal IS NULL
	end
        
--Source:  Non-Nullable, (Must always be 'AR Invoice')     
if isnull(@SourceID,0) <> 0
	begin
	UPDATE IMWE
	SET IMWE.UploadVal = 'AR Invoice'
	where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @SourceID
	and IMWE.RecordType = @rectype
	end

--ARTransType:	Non-Nullable, (Must always be 'I'.  This import is not prepared to handle Adjustments, Credits and Writeoffs)
if isnull(@ARTransTypeID,0) <> 0
	begin
	UPDATE IMWE
	SET IMWE.UploadVal = 'I'
	where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @ARTransTypeID
		and IMWE.RecordType = @rectype
	end
       
--TransDate:	Non-Nullable
if isnull(@TransDateID,0) <> 0 AND (ISNULL(@OverwriteTransDate, 'Y') = 'Y')
	begin
	UPDATE IMWE
	----#141031
	SET IMWE.UploadVal = convert(varchar(20), dbo.vfDateOnly(),101)
	where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @TransDateID
		and IMWE.RecordType = @rectype
	end
       
if isnull(@TransDateID,0) <> 0 AND (ISNULL(@OverwriteTransDate, 'Y') = 'N')
	begin
	UPDATE IMWE
	----#141031
	SET IMWE.UploadVal = convert(varchar(20), dbo.vfDateOnly(),101)
	where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @TransDateID
	and IMWE.RecordType = @rectype
	AND IMWE.UploadVal IS NULL
	end

/***** GET COLUMN IDENTIFIERS - Identifier will be returned ONLY when 'Use Viewpoint Default' is set. *******/         
select @paytermsid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PayTerms', @rectype, 'Y')
select @rectypeid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'RecType', @rectype, 'Y')
select @discdateid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'DiscDate', @rectype, 'Y')
select @duedateid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'DueDate', @rectype, 'Y')
select @jccoid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'JCCo', @rectype, 'Y')
select @jccoid2=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'JCCo', @rectype, 'N')
select @invoiceid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Invoice', @rectype, 'Y')

/***** GET COLUMN IDENTIFIERS - Identifier will be returned regardless of 'Use Viewpoint Default' setting. *******/
select @custgroupid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CustGroup', @rectype, 'N')	-- Non-Nullable
    
/* Begin default process.  Different concept here.  Multiple cursor records make up a single Import record
   determined by a change in the RecSeq value.  New RecSeq signals the beginning of the next Import record. */         
declare WorkEditCursor cursor local fast_forward for
select IMWE.RecordSeq, IMWE.Identifier, DDUD.TableName, DDUD.ColumnName, IMWE.UploadVal
from IMWE with (nolock)
inner join DDUD  with (nolock) on IMWE.Identifier = DDUD.Identifier and DDUD.Form = IMWE.Form
where IMWE.ImportId = @ImportId and IMWE.ImportTemplate = @ImportTemplate and IMWE.Form = @Form and
	IMWE.RecordType = @rectype
Order by IMWE.RecordSeq, IMWE.Identifier

open WorkEditCursor
-- set open cursor flag

fetch next from WorkEditCursor into @Recseq, @Ident, @Tablename, @Column, @Uploadval
       
select @currrecseq = @Recseq, @complete = 0, @counter = 1
     
-- while cursor is not empty
while @complete = 0
	begin
	if @@fetch_status <> 0 select @Recseq = -1
       
	--if rec sequence = current rec sequence flag
	if @Recseq = @currrecseq	--Moves on to defaulting process when the first record of a DIFFERENT import RecordSeq is detected
		begin
		/************************** GET UPLOADED VALUES FOR THIS IMPORT RECORD *****************************/
		/* For each imported record:  (Each imported record has multiple records in the IMWE table representing columns of the import record)
	       Cursor will cycle through each column of an imported record and set the imported value into a variable
		   that could be used during the defaulting process later if desired.  
		   
		   The imported value here is only needed if the value will be used to help determine another
		   default value in some way. */
		If @Column='Co' and isnumeric(@Uploadval) =1 select @Co = Convert( int, @Uploadval)
        If @Column='CustGroup' and isnumeric(@Uploadval) =1 select @CustGroup = Convert( int, @Uploadval)
       	If @Column='Customer' and isnumeric(@Uploadval) =1 select @Customer = Convert( int, @Uploadval)
       	If @Column='JCCo' and isnumeric(@Uploadval) =1 select @JCCo = Convert( int, @Uploadval)
       	If @Column='Contract' select @Contract = @Uploadval
		If @Column='TransDate' and isdate(@Uploadval) =1 select @TransDate =  Convert( smalldatetime, @Uploadval)
		If @Column='PayTerms' select @PayTerms = @Uploadval

		/* Set IsNull variable for later */
		IF @Column='CustGroup' 
			IF @Uploadval IS NULL
				SET @IsCustGroupEmpty = 'Y'
			ELSE
				SET @IsCustGroupEmpty = 'N'
		IF @Column='PayTerms' 
			IF @Uploadval IS NULL
				SET @IsPayTermsEmpty = 'Y'
			ELSE
				SET @IsPayTermsEmpty = 'N'
		IF @Column='Invoice' 
			IF @Uploadval IS NULL
				SET @IsInvoiceEmpty = 'Y'
			ELSE
				SET @IsInvoiceEmpty = 'N'
		IF @Column='RecType' 
			IF @Uploadval IS NULL
				SET @IsRecTypeEmpty = 'Y'
			ELSE
				SET @IsRecTypeEmpty = 'N'
		IF @Column='JCCo' 
			IF @Uploadval IS NULL
				SET @IsJCCoEmpty = 'Y'
			ELSE
				SET @IsJCCoEmpty = 'N'
		IF @Column='DueDate' 
			IF @Uploadval IS NULL
				SET @IsDueDateEmpty = 'Y'
			ELSE
				SET @IsDueDateEmpty = 'N'
		IF @Column='DiscDate' 
			IF @Uploadval IS NULL
				SET @IsDiscDateEmpty = 'Y'
			ELSE
				SET @IsDiscDateEmpty = 'N'
				
		--fetch next record
        if @@fetch_status <> 0 select @complete = 1
       
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
		   
		--CustGroup:	Non-Nullable
       	if @custgroupid <> 0 and isnull(@Co,'')<> '' AND (ISNULL(@OverwriteCustGroup, 'Y') = 'Y' OR ISNULL(@IsCustGroupEmpty, 'Y') = 'Y') 
			begin
			select @CustGroup = CustGroup
			from HQCO with (nolock) where HQCo = @Co
       
			UPDATE IMWE
			SET IMWE.UploadVal = @CustGroup
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @custgroupid and IMWE.RecordType = @rectype
			end
      
		--JCCo
       	if @jccoid <> 0 and isnull(@Co,'')<> '' AND (ISNULL(@OverwriteJCCo, 'Y') = 'Y' OR ISNULL(@IsJCCoEmpty, 'Y') = 'Y') 
			begin
			select @JCCo = JCCo
			from ARCO with (nolock) where ARCo = @Co
       
			UPDATE IMWE
			SET IMWE.UploadVal = @JCCo
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @jccoid and IMWE.RecordType = @rectype
			end

		--Invoice
		if @invoiceid <> 0 and isnull(@Co,'')<> ''  AND (ISNULL(@OverwriteInvoice, 'Y') = 'Y' OR ISNULL(@IsInvoiceEmpty, 'Y') = 'Y') 
			begin
      		if exists (select 1 from ARCO with (nolock) where ARCo = @Co and InvAutoNum = 'Y')
				begin
      			--fixed for #25010
      			exec @recode = bspARNextTrans @Co, @lastinvoice output, @msg output
      
      			if @recode = 0
      				begin
 					select @Invoice = @lastinvoice
            		select @Invoice = space(10 - datalength(@Invoice)) + @Invoice
      
           			UPDATE IMWE
          			SET IMWE.UploadVal = @Invoice
          			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
          			and IMWE.Identifier = @invoiceid and IMWE.RecordType = @rectype
  					end
      			end
             end
      
       	select @custpayterms = null, @custrectype = null, @conpayterms = null, @corectype = null
       
		-- select Company information
		select @corectype = RecType from ARCO with (nolock) where ARCo=@Co
       
		-- select Customer information
		select @custpayterms = PayTerms, @custrectype = RecType from ARCM with (nolock)
		where CustGroup=@CustGroup and Customer = @Customer
       
		-- select Contract information
		select @conpayterms = PayTerms from JCCM with (nolock)
		where JCCo=@JCCo and Contract = @Contract
       
		--PayTerms
       	if @paytermsid <> 0 and (isnull(@custpayterms,'')<> '' or isnull(@conpayterms,'')<> '') AND (ISNULL(@OverwritePayTerms, 'Y') = 'Y' OR ISNULL(@IsPayTermsEmpty, 'Y') = 'Y')
			begin
			select @PayTerms = @custpayterms
			if isnull(@conpayterms,'')<> ''select @PayTerms = @conpayterms
       
			UPDATE IMWE
			SET IMWE.UploadVal = @PayTerms
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @paytermsid and IMWE.RecordType = @rectype
			end

		--RecType
       	if @rectypeid <> 0 and (isnull(@corectype,'')<> '' or isnull(@custrectype,'')<> '') AND (ISNULL(@OverwriteRecType, 'Y') = 'Y' OR ISNULL(@IsRecTypeEmpty, 'Y') = 'Y') 
			begin
            select @RType = @corectype
			if isnull(@custrectype,'')<> ''select @RType = @custrectype
       
			UPDATE IMWE
			SET IMWE.UploadVal = @RType
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @rectypeid and IMWE.RecordType = @rectype
			end

		exec @recode = bspHQPayTermsDateCalc @PayTerms, @TransDate, @discdate output, @duedate output,
                                             @discrate output, @msg output
       
		--DiscDate
       	if @discdateid <> 0 AND (ISNULL(@OverwriteDiscDate, 'Y') = 'Y' OR ISNULL(@IsDiscDateEmpty, 'Y') = 'Y') 
			begin
			UPDATE IMWE
			SET IMWE.UploadVal = convert(varchar(20),@discdate,101)
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @discdateid and IMWE.RecordType = @rectype
			end
       
		--DueDate
       	if @duedateid <> 0 AND (ISNULL(@OverwriteDueDate, 'Y') = 'Y' OR ISNULL(@IsDueDateEmpty, 'Y') = 'Y') 
			begin
       		if isnull(@duedate,'')='' select @duedate = @TransDate
              
			UPDATE IMWE
			SET IMWE.UploadVal = convert(varchar(20),@duedate,101)
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @duedateid and IMWE.RecordType = @rectype
			end
       
   	 	--cleanup section
   	 
   	 	--issue #27338
   	 	if isnull(@Contract,'') = '' and @jccoid2 <> 0
   	 		begin
   	 		UPDATE IMWE
   			SET IMWE.UploadVal = null
   			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
   				and IMWE.Identifier = @jccoid2 and IMWE.RecordType = @rectype
   	 		end
    
   	 	--end cleanup
       
		select @currrecseq = @Recseq
		select @counter = @counter + 1
    	
		select @Co = null, @CustGroup = null, @Customer = null, @RType = null, @JCCo = null, @Contract = null, 
       		@Invoice = null, @TransDate = null, @PayTerms = null 

		select @custpayterms = null, @custrectype = null, @conpayterms = null, @corectype = null,
       		@discdate = null, @duedate = null, @discrate = null
       
		end
	end
       
--UPDATE IMWE
--SET IMWE.UploadVal = 0
--where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordType = @rectype and isnull(IMWE.UploadVal,'')='' and
--(IMWE.Identifier = @zcreditamtid)
       
close WorkEditCursor
deallocate WorkEditCursor

bspexit:
   select @msg = isnull(@desc,'Header') + char(13) + char(13) + '[bspIMBidtekDefaultsARBH]'

   return @rcode
   



GO
GRANT EXECUTE ON  [dbo].[bspIMBidtekDefaultsARBH] TO [public]
GO
