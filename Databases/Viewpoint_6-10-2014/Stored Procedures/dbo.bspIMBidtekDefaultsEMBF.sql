SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[bspIMBidtekDefaultsEMBF]
/***********************************************************
* CREATED BY: Danf
* MODIFIED BY: GG 11/27/00 - changed datatype from bAPRef to bAPReference
*            : DANF 08/22/01
*            : DANF 10/31/01 - Set GL transaction Account.
*            : DANF 03/06/02 - Correct removal of zero dollar amounts #16524
*            DANF 03/19/02 - Added Record Type
*			 CC	02/18/09 - Issue #24531 - Use default only if set to overwrite or value is null
*			 CC  05/29/09 - Issue #133516 - Correct defaulting of Company
*		 TRL 07/20/09 Issue 134231 
*			 GF 09/12/2010 - issue #141031 changed to use function vfDateOnly
*			AMR 01/12/11 - #142350 - making case sensitive by removing @inusemth that is not used 
*			GF 08/23/2012 TK-17347 calculate unit price if override flag = Y, not 'LS', and we have units and dollars
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

declare @rcode int, @recode int, @desc varchar(120),
		@ynactualdate bYN, @ynemgroup bYN, @yncostcode bYN, @yncosttype bYN, @ynmatlgroup bYN,
		@yninco bYN, @ynglco bYN, @yntaxgroup bYN, @yngltransacct bYN, @yngloffsetacct bYN,
		@ynfasbooknumberone bYN, @ynunitprice bYN, @fasbooknumberid int, @dollarid int,
		@equipid int, @CompanyID int, @defaultvalue varchar(30)
		
		
----TK-17347
DECLARE @ynoffsetglco bYN, @unitpriceid INT, @OffSetGLAcctId INT, @OffSetGLCoId INT,
		@GLTransAcctId INT


select @ynactualdate ='N', @ynemgroup ='N', @yncostcode ='N', @yncosttype ='N', @ynmatlgroup = 'N',
		@yninco ='N', @ynglco ='N', @yntaxgroup ='N', @yngltransacct ='N', @yngloffsetacct ='N',
		@ynfasbooknumberone = 'N', @ynunitprice ='N'
	
----TK-17347
SET @ynoffsetglco = 'N'

/* check required input params */
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
--
select @fasbooknumberid   = Identifier from IMTD
where IMTD.ImportTemplate = @ImportTemplate and IMTD.ColDesc = 'FasBookNumber'
if @@rowcount <> 0 and @fasbooknumberid is not null
begin
	declare  DeleteFasBooks cursor for
	select RecordSeq from IMWE
	where ImportId = @ImportId and ImportTemplate = @ImportTemplate and Form = @Form and Identifier = @fasbooknumberid and ImportedVal <> '1'
	Order by RecordSeq

	open DeleteFasBooks
	-- set open cursor flag
	declare @DelRecseq int

	nextRecord: fetch next from  DeleteFasBooks into @DelRecseq

	if @@fetch_status = 0
	begin
		delete IMWE
		where ImportId = @ImportId and ImportTemplate = @ImportTemplate and Form = @Form and  RecordSeq = @DelRecseq
	
		goto nextRecord
	end

	close DeleteFasBooks
	deallocate DeleteFasBooks
end

select @dollarid   = Identifier from IMTD
where IMTD.ImportTemplate = @ImportTemplate and IMTD.ColDesc = 'Dollars'
if @@rowcount <> 0 and @dollarid is not null
begin
	declare  DeleteZeroDollar cursor for
	select RecordSeq
	from IMWE
	where ImportId = @ImportId and ImportTemplate = @ImportTemplate and Form = @Form and Identifier = @dollarid and convert(float,UploadVal ) = 0
	Order by RecordSeq

	open DeleteZeroDollar
	-- set open cursor flag
	declare @DelZeroseq int

	nextZeroRecord: fetch next from  DeleteZeroDollar into @DelZeroseq

	if @@fetch_status = 0
	begin
		delete IMWE
		where ImportId = @ImportId and ImportTemplate = @ImportTemplate and Form = @Form and  RecordSeq = @DelZeroseq
		
		goto nextZeroRecord
	end
	
	close DeleteZeroDollar	
	deallocate DeleteZeroDollar
end

---- tk-17437 Check ImportTemplate detail for columns to set Bidtek Defaults
IF NOT EXISTS(select 1 FROM dbo.IMTD WHERE IMTD.ImportTemplate=@ImportTemplate
					AND IMTD.DefaultValue = '[Bidtek]')
	BEGIN
	select @desc='No Bidtek Defaults set up for ImportTemplate ' + @ImportTemplate +'.', @rcode=1
	goto bspexit
	END
			
--Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'
--if @@rowcount = 0
--begin
--	select @desc='No Bidtek Defaults set up for ImportTemplate ' + @ImportTemplate +'.', @rcode=1
--	goto bspexit
--end

DECLARE 
@OverwriteActualDate 	 				bYN,
@OverwriteEMGroup 	 					bYN,
@OverwriteCostCode 	 				bYN,
@OverwriteEMCostType 	 			bYN,
@OverwriteMatlGroup 	 				bYN,
@OverwriteINCo 	 						bYN,

@OverwriteUnitPrice 	 				bYN,

@OverwriteGLCo 	 						bYN,
@OverwriteTaxGroup 	 					bYN,
@OverwriteGLOffsetAcct  				bYN,
----TK-17347
@OverwriteOffsetGLCo 	 	 			bYN,
@OverwriteGLTransAcct  					bYN,
@OverwriteCo							bYN,

@IsCoEmpty 								bYN,
@IsMthEmpty 								bYN,
@IsBatchIdEmpty 							bYN,
@IsBatchSeqEmpty 						bYN,
@IsSourceEmpty 							bYN,
@IsBatchTransTypeEmpty 				bYN,
@IsEMTransEmpty 						bYN,
@IsActualDateEmpty 						bYN,
@IsEMTransTypeEmpty 					bYN,
@IsReversalStatusEmpty 				bYN,
@IsEMGroupEmpty 						bYN,
@IsWorkOrderEmpty 						bYN,
@IsWOItemEmpty 							bYN,
@IsEquipmentEmpty 						bYN,
@IsComponentTypeCodeEmpty		bYN,
@IsComponentEmpty 					bYN,
@IsCostCodeEmpty 						bYN,
@IsEMCostTypeEmpty 					bYN,
@IsMatlGroupEmpty 						bYN,
@IsINCoEmpty 								bYN,
@IsINLocationEmpty 						bYN,
@IsMaterialEmpty 							bYN,
@IsDescriptionEmpty 					bYN,
@IsGLCoEmpty 							bYN,
@IsGLTransAcctEmpty 					bYN,
@IsGLOffsetAcctEmpty 					bYN,
----TK-17347
@IsOffsetGLCoEmpty 						bYN,
@IsUnitsEmpty 							bYN,
@IsUMEmpty 								bYN,
@IsUnitPriceEmpty 						bYN,
@IsPerECMEmpty 							bYN,
@IsDollarsEmpty 							bYN,
@IsSerialNoEmpty 						bYN,
@IsMeterReadDateEmpty 				bYN,
@IsCurrentOdometerEmpty 			bYN,
@IsCurrentHourMeterEmpty 			bYN,
@IsCurrentTotalHourMeterEmpty 	bYN,
@IsCurrentTotalOdometerEmpty 	bYN,
@IsTaxGroupEmpty 						bYN,
@IsTaxTypeEmpty 							bYN,
@IsTaxCodeEmpty 						bYN,
@IsTaxBasisEmpty 						bYN,
@IsTaxRateEmpty 							bYN,
@IsTaxAmountEmpty 					bYN,
@IsPRCoEmpty 							bYN,
@IsPREmployeeEmpty 					bYN			

SELECT @OverwriteActualDate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ActualDate', @rectype);
SELECT @OverwriteEMGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'EMGroup', @rectype);
SELECT @OverwriteCostCode = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CostCode', @rectype);
SELECT @OverwriteEMCostType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'EMCostType', @rectype);
SELECT @OverwriteMatlGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'MatlGroup', @rectype);
SELECT @OverwriteINCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'INCo', @rectype);
SELECT @OverwriteUnitPrice = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'UnitPrice', @rectype);
SELECT @OverwriteGLCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'GLCo', @rectype);
SELECT @OverwriteTaxGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TaxGroup', @rectype);
SELECT @OverwriteGLOffsetAcct = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'GLOffsetAcct', @rectype);
SELECT @OverwriteGLTransAcct = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'GLTransAcct', @rectype);
SELECT @OverwriteCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Co', @rectype);
----TK-17437
SELECT @OverwriteOffsetGLCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'OffsetGLCo', @rectype);


select @CompanyID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Co'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCo, 'Y') = 'Y') 
begin
	UPDATE IMWE
	SET IMWE.UploadVal = @Company
	where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @CompanyID
end

select @CompanyID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Co'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCo, 'Y') = 'N') 
begin
	UPDATE IMWE
	SET IMWE.UploadVal = @Company
	where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @CompanyID
end

select IMTD.DefaultValue, DDUD.ColumnName, DDUD.Identifier From IMTD
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'ActualDate'
if @@rowcount <> 0 
BEGIN
	select @ynactualdate ='Y'	
END

select IMTD.DefaultValue, DDUD.ColumnName, DDUD.Identifier From IMTD
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'EMGroup'
if @@rowcount <> 0 
begin 
	select @ynemgroup ='Y'
end

select IMTD.DefaultValue, DDUD.ColumnName, DDUD.Identifier From IMTD
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'CostCode'
if @@rowcount <> 0 
begin
	select @yncostcode ='Y'
end

select IMTD.DefaultValue, DDUD.ColumnName, DDUD.Identifier From IMTD
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'EMCostType'
if @@rowcount <> 0 
begin
	select @yncosttype ='Y'
end

select IMTD.DefaultValue, DDUD.ColumnName, DDUD.Identifier From IMTD
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'MatlGroup'
if @@rowcount <> 0 
begin
	select @ynmatlgroup ='Y'
end

select IMTD.DefaultValue, DDUD.ColumnName, DDUD.Identifier From IMTD
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'INCo'
if @@rowcount <> 0 
begin
	select @yninco ='Y'
end

/*Issue 134321*/

/*Issue 134321*/

select IMTD.DefaultValue, DDUD.ColumnName, DDUD.Identifier From IMTD
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'GLCo'
if @@rowcount <> 0 
begin
	select @ynglco ='Y'
end

select IMTD.DefaultValue, DDUD.ColumnName, DDUD.Identifier From IMTD
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'TaxGroup'
if @@rowcount <> 0 
BEGIN
	select @yntaxgroup ='Y'
END

---- TK-17437 get offset gl account identifier
SET @OffSetGLAcctId = NULL
select @OffSetGLAcctId = DDUD.Identifier
From dbo.IMTD
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate
	AND IMTD.DefaultValue = '[Bidtek]'
	AND DDUD.ColumnName = 'GLOffsetAcct'
if @@rowcount <> 0 SET @yngloffsetacct  ='Y'

---- TK-17347 get offset gl co identifier
SET @OffSetGLCoId = NULL
select @OffSetGLCoId = DDUD.Identifier
From dbo.IMTD
inner join dbo.DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate = @ImportTemplate
	AND IMTD.DefaultValue = '[Bidtek]'
	AND DDUD.ColumnName = 'OffsetGLCo'
if @@rowcount <> 0 SET @ynoffsetglco  ='Y'

----TK-17347 get unitprice identifier
SET @unitpriceid = NULL
select @unitpriceid = DDUD.Identifier
From dbo.IMTD
inner join dbo.DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate = @ImportTemplate
	AND IMTD.DefaultValue = '[Bidtek]'
	AND DDUD.ColumnName = 'UnitPrice'
IF @@ROWCOUNT <> 0 SET @ynunitprice = 'Y'
	
----TK-17347 get GL transactino account identifier
SET @GLTransAcctId = NULL
select @GLTransAcctId = DDUD.Identifier
From dbo.IMTD
inner join dbo.DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate
	AND IMTD.DefaultValue = '[Bidtek]'
	AND DDUD.ColumnName = 'GLTransAcct'
if @@ROWCOUNT <> 0 SET @yngltransacct  ='Y'



declare  @Co bCompany, @Mth bMonth, @BatchId bBatchID, @BatchSeq int, @BatchTransType char, @Source bSource,
@Equipment bEquip, @RevCode bRevCode, @EMTrans bTrans, @EMTransType  varchar(10), @ComponentTypeCode varchar(10), @Component bEquip,
@Asset varchar(20), @EMGroup bGroup, @CostCode bCostCode, @EMCostType bEMCType, @ActualDate  bDate, @Description bDesc, @GLCo bCompany,
@EMGLTransAcct bGLAcct, @GLTransAcct bGLAcct, @GLOffsetAcct bGLAcct, @ReversalStatus tinyint, @OrigMth bMonth, @OrigEMTrans bTrans,
@PRCo bCompany, @PREmployee bEmployee, @APCo bCompany, @APTrans bTrans, @APLine bItem, @VendorGrp bGroup, @APVendor bVendor,
@APRef bAPReference, @WorkOrder bWO, @WOItem bItem, @MatlGroup bGroup, @INCo bCompany, @INLocation bLoc, @Material bMatl,
@SerialNo varchar(20), @UM bUM, @Units bUnits, @Dollars bDollar, @UnitPrice bUnitCost, @Hours bHrs, @PerECM bECM,
@JCCo bCompany, @Job bJob, @PhaseGrp bGroup, @JCPhase bPhase, @JCCostType bJCCType, @TaxGroup bGroup,
@Department bDept, @FasBookNumber varchar(10)
----TK-17347
,@Factor INT, @OffsetGLCo bCompany

declare WorkEditCursor cursor for
select IMWE.RecordSeq, IMWE.Identifier, DDUD.TableName, DDUD.ColumnName, IMWE.UploadVal from IMWE
inner join DDUD on IMWE.Identifier = DDUD.Identifier and DDUD.Form = IMWE.Form
where IMWE.ImportId = @ImportId and IMWE.ImportTemplate = @ImportTemplate and IMWE.Form = @Form
Order by IMWE.RecordSeq, IMWE.Identifier

open WorkEditCursor
-- set open cursor flag
-- #142350 - @importid not used removed it
declare @Recseq int, @Tablename varchar(20), @Column varchar(30), @Uploadval varchar(60), @Ident int,
 @seq int, @Identifier int

declare @currrecseq int, @allownull int, @error int, @tsql varchar(255), @valuelist varchar(255),
@columnlist varchar(255), @complete int, @counter int, @records int, @oldrecseq int

declare @costtypeout bEMCType

fetch next from WorkEditCursor into @Recseq, @Ident, @Tablename, @Column, @Uploadval

select @currrecseq = @Recseq, @complete = 0, @counter = 1

-- while cursor is not empty
while @complete = 0
begin

	if @@fetch_status <> 0
	select @Recseq = -1

	--if rec sequence = current rec sequence flag
	IF @Recseq = @currrecseq
		BEGIN
			If @Column='Co' and isnumeric(@Uploadval) =1 select @Co = Convert( int, @Uploadval)
			If @Column='Mth' and isdate(@Uploadval) =1 select @Mth = Convert( smalldatetime, @Uploadval)
			----If @Column='BatchSeq' and  isnumeric(@Uploadval) =1 select @BatchSeq = @Uploadval
			--If @Column='BatchTransType' select @BatchTransType = @Uploadval
			--If @Column='Source' select @Source = @Uploadval
			If @Column='Equipment' select @Equipment = @Uploadval
			/*	If @Column='RevCode' and isnumeric(@Uploadval) =1 select @RevCode = Convert( int, @Uploadval)
			If @Column='EMTrans' and isdate(@Uploadval) =1 select @EMTrans = Convert( smalldatetime, @Uploadval)
			If @Column='ComponentTypeCode' select @ComponentTypeCode = @Uploadval
			If @Column='Component' select @Component = @Uploadval
			If @Column='Asset' select @Type = @Asset */
			If @Column='EMTransType' select @EMTransType = @Uploadval
			If @Column='EMGroup' and isnumeric(@Uploadval) =1 select @EMGroup = Convert( int, @Uploadval)
			If @Column='CostCode' select @CostCode = @Uploadval
			If @Column='EMCostType' and  isnumeric(@Uploadval) =1 select @EMCostType = @Uploadval
			If @Column='ActualDate' and isdate(@Uploadval) =1 select @ActualDate = Convert( smalldatetime, @Uploadval)
			If @Column='Description' select @Description = @Uploadval
			If @Column='GLCo' and isnumeric(@Uploadval) =1 select @GLCo = Convert( int, @Uploadval)
			If @Column='GLTransAcct' select @GLTransAcct = @Uploadval
			If @Column='GLOffsetAcct' select @GLOffsetAcct = @Uploadval
			----TK-17347
			IF @Column = 'OffsetGLCo' AND ISNUMERIC(@Uploadval) = 1 SET @OffsetGLCo = CONVERT(INT, @Uploadval)
			/*	If @Column='ReversalStatus' select @ReversalStatus = @Uploadval
			If @Column='OrigMth' and  isnumeric(@Uploadval) =1 select @OrigMth = convert(numeric,@Uploadval)
			If @Column='OrigEMTrans' select @OrigEMTrans = @Uploadval
			If @Column='PRCo' and  isnumeric(@Uploadval) =1 select @PRCo = convert(numeric,@Uploadval)
			If @Column='PREmployee' select @PREmployee = @Uploadval
			If @Column='APCo' select @APCo = @Uploadval
			If @Column='APTrans' select @APTrans = @Uploadval
			If @Column='APLine' select @APLine = @Uploadval
			If @Column='VendorGrp' select @VendorGrp = @Uploadval
			If @Column='APVendor' and  isnumeric(@Uploadval) =1 select @APVendor = convert(decimal(10,3),@Uploadval)
			If @Column='APRef' select @APRef = @Uploadval
			If @Column='WorkOrder' select @WorkOrder = @Uploadval
			If @Column='WOItem' select @WOItem = @Uploadval */
			If @Column='MatlGroup' and isnumeric(@Uploadval) =1 select @MatlGroup = Convert( int, @Uploadval)
			If @Column='INCo' and isnumeric(@Uploadval) =1 select @INCo = Convert( int, @Uploadval)
			If @Column='INLocation' select @INLocation = @Uploadval
			If @Column='Material' select @Material = @Uploadval
			----If @Column='SerialNo' select @SerialNo = @Uploadval
			----TK-17347
			If @Column = 'UM' select @UM = @Uploadval
			If @Column = 'Units' AND ISNUMERIC(@Uploadval) = 1 SET @Units = CONVERT(DECIMAL(12,3), @Uploadval)
			If @Column = 'Dollars' AND ISNUMERIC(@Uploadval) = 1 SET @Dollars = CONVERT(DECIMAL(12,2), @Uploadval)
			If @Column = 'UnitPrice' AND ISNUMERIC(@Uploadval) = 1 SET @UnitPrice = CONVERT(DECIMAL(16,5), @Uploadval)
			----If @Column='Hours' and isnumeric(@Uploadval) =1 select @Hours = convert(decimal(10,3),@Uploadval)
			If @Column='PerECM' SELECT @PerECM = @Uploadval
			--If @Column='JCCo' and isnumeric(@Uploadval) =1 select @JCCo = convert(decimal(10,2),@Uploadval)
			--If @Column='Job' select @Job = @Uploadval
			--If @Column='PhaseGrp' select @PhaseGrp = @Uploadval
			--If @Column='JCPhase' select @JCPhase = @Uploadval
			--If @Column='JCCostType' select @JCCostType = @Uploadval
			--If @Column='TaxType' select @TaxType = @Uploadval */
			If @Column='TaxGroup' and isnumeric(@Uploadval) =1 select @TaxGroup = Convert( int, @Uploadval)
			/*	If @Column='TaxBasis' select @TaxBasis = @Uploadval
			If @Column='TaxRate' and isnumeric(@Uploadval) =1 select @TaxRate = convert(numeric,@Uploadval)
			If @Column='TaxAmount' and isnumeric(@Uploadval) =1 select @TaxAmount = convert(numeric,@Uploadval)*/

			IF @Column='Co' 
			IF @Uploadval IS NULL
					SET @IsCoEmpty = 'Y'
			ELSE
					SET @IsCoEmpty = 'N'
					
			IF @Column='Mth' 
			IF @Uploadval IS NULL
				SET @IsMthEmpty = 'Y'
			ELSE
				SET @IsMthEmpty = 'N'

			IF @Column='BatchId' 
			IF @Uploadval IS NULL
				SET @IsBatchIdEmpty = 'Y'
			ELSE
				SET @IsBatchIdEmpty = 'N'

			IF @Column='BatchSeq' 
			IF @Uploadval IS NULL
				SET @IsBatchSeqEmpty = 'Y'
			ELSE
				SET @IsBatchSeqEmpty = 'N'

			IF @Column='Source' 
			IF @Uploadval IS NULL
				SET @IsSourceEmpty = 'Y'
			ELSE
				SET @IsSourceEmpty = 'N'

			IF @Column='BatchTransType' 
			IF @Uploadval IS NULL
				SET @IsBatchTransTypeEmpty = 'Y'
			ELSE
				SET @IsBatchTransTypeEmpty = 'N'

			IF @Column='EMTrans' 
			IF @Uploadval IS NULL
				SET @IsEMTransEmpty = 'Y'
			ELSE
				SET @IsEMTransEmpty = 'N'

			IF @Column='ActualDate' 
			IF @Uploadval IS NULL
				SET @IsActualDateEmpty = 'Y'
			ELSE
				SET @IsActualDateEmpty = 'N'

			IF @Column='EMTransType' 
			IF @Uploadval IS NULL
				SET @IsEMTransTypeEmpty = 'Y'
			ELSE
				SET @IsEMTransTypeEmpty = 'N'

			IF @Column='ReversalStatus' 
			IF @Uploadval IS NULL
				SET @IsReversalStatusEmpty = 'Y'
			ELSE
				SET @IsReversalStatusEmpty = 'N'

			IF @Column='EMGroup' 
			IF @Uploadval IS NULL
				SET @IsEMGroupEmpty = 'Y'
			ELSE
				SET @IsEMGroupEmpty = 'N'

			IF @Column='WorkOrder' 
			IF @Uploadval IS NULL
				SET @IsWorkOrderEmpty = 'Y'
			ELSE
				SET @IsWorkOrderEmpty = 'N'

			IF @Column='WOItem' 
			IF @Uploadval IS NULL
				SET @IsWOItemEmpty = 'Y'
			ELSE
				SET @IsWOItemEmpty = 'N'

			IF @Column='Equipment' 
			IF @Uploadval IS NULL
				SET @IsEquipmentEmpty = 'Y'
			ELSE
				SET @IsEquipmentEmpty = 'N'

			IF @Column='ComponentTypeCode' 
			IF @Uploadval IS NULL
				SET @IsComponentTypeCodeEmpty = 'Y'
			ELSE
				SET @IsComponentTypeCodeEmpty = 'N'

			IF @Column='Component' 
			IF @Uploadval IS NULL
				SET @IsComponentEmpty = 'Y'
			ELSE
				SET @IsComponentEmpty = 'N'

			IF @Column='CostCode' 
			IF @Uploadval IS NULL
				SET @IsCostCodeEmpty = 'Y'
			ELSE
				SET @IsCostCodeEmpty = 'N'

			IF @Column='EMCostType' 
			IF @Uploadval IS NULL
				SET @IsEMCostTypeEmpty = 'Y'
			ELSE
				SET @IsEMCostTypeEmpty = 'N'

			IF @Column='MatlGroup' 
			IF @Uploadval IS NULL
				SET @IsMatlGroupEmpty = 'Y'
			ELSE
				SET @IsMatlGroupEmpty = 'N'

			IF @Column='INCo' 
			IF @Uploadval IS NULL
				SET @IsINCoEmpty = 'Y'
			ELSE
				SET @IsINCoEmpty = 'N'

			IF @Column='INLocation' 
			IF @Uploadval IS NULL
				SET @IsINLocationEmpty = 'Y'
			ELSE
				SET @IsINLocationEmpty = 'N'

			IF @Column='Material' 
			IF @Uploadval IS NULL
				SET @IsMaterialEmpty = 'Y'
			else	
				SET @IsMaterialEmpty = 'N'

			IF @Column='Description' 
			IF @Uploadval IS NULL
				SET @IsDescriptionEmpty = 'Y'
			ELSE
				SET @IsDescriptionEmpty = 'N'

			IF @Column='GLCo' 
			IF @Uploadval IS NULL
				SET @IsGLCoEmpty = 'Y'
			ELSE
				SET @IsGLCoEmpty = 'N'

			IF @Column='GLTransAcct' 
			IF @Uploadval IS NULL
				SET @IsGLTransAcctEmpty = 'Y'
			ELSE
				SET @IsGLTransAcctEmpty = 'N'

			IF @Column='OffsetGLCo' 
				IF @Uploadval IS NULL
					SET @IsOffsetGLCoEmpty = 'Y'
				ELSE
					SET @IsOffsetGLCoEmpty = 'N'

			IF @Column='GLOffsetAcct' 
			IF @Uploadval IS NULL
				SET @IsGLOffsetAcctEmpty = 'Y'
			ELSE
				SET @IsGLOffsetAcctEmpty = 'N'

			IF @Column='Units'
				IF @Uploadval IS NULL
					SET @IsUnitsEmpty = 'Y'
				ELSE
					SET @IsUnitsEmpty = 'N'
				
			IF @Column='UM' 
				IF @Uploadval IS NULL
					SET @IsUMEmpty = 'Y'
				ELSE
					SET @IsUMEmpty = 'N'
				
			IF @Column='UnitPrice' 
			IF @Uploadval IS NULL
				SET @IsUnitPriceEmpty = 'Y'
			ELSE
				SET @IsUnitPriceEmpty = 'N'

			IF @Column='PerECM' 
			IF @Uploadval IS NULL
				SET @IsPerECMEmpty = 'Y'
			ELSE
				SET @IsPerECMEmpty = 'N'

			IF @Column='Dollars' 
			IF @Uploadval IS NULL
				SET @IsDollarsEmpty = 'Y'
			ELSE
				SET @IsDollarsEmpty = 'N'

			IF @Column='SerialNo' 
			IF @Uploadval IS NULL
				SET @IsSerialNoEmpty = 'Y'
			ELSE
				SET @IsSerialNoEmpty = 'N'

			IF @Column='MeterReadDate' 
			IF @Uploadval IS NULL
				SET @IsMeterReadDateEmpty = 'Y'
			ELSE
				SET @IsMeterReadDateEmpty = 'N'

			IF @Column='CurrentOdometer' 
			IF @Uploadval IS NULL
				SET @IsCurrentOdometerEmpty = 'Y'
			ELSE
				SET @IsCurrentOdometerEmpty = 'N'

			IF @Column='CurrentHourMeter' 
			IF @Uploadval IS NULL
				SET @IsCurrentHourMeterEmpty = 'Y'
			ELSE
				SET @IsCurrentHourMeterEmpty = 'N'

			IF @Column='CurrentTotalHourMeter' 
			IF @Uploadval IS NULL
				SET @IsCurrentTotalHourMeterEmpty = 'Y'
			ELSE
				SET @IsCurrentTotalHourMeterEmpty = 'N'

			IF @Column='CurrentTotalOdometer' 
			IF @Uploadval IS NULL
				SET @IsCurrentTotalOdometerEmpty = 'Y'
			ELSE
				SET @IsCurrentTotalOdometerEmpty = 'N'

			IF @Column='TaxGroup' 
			IF @Uploadval IS NULL
				SET @IsTaxGroupEmpty = 'Y'
			ELSE
				SET @IsTaxGroupEmpty = 'N'

			IF @Column='TaxType' 
			IF @Uploadval IS NULL
				SET @IsTaxTypeEmpty = 'Y'
			ELSE
				SET @IsTaxTypeEmpty = 'N'

			IF @Column='TaxCode' 
			IF @Uploadval IS NULL
				SET @IsTaxCodeEmpty = 'Y'
			ELSE
			SET @IsTaxCodeEmpty = 'N'

			IF @Column='TaxBasis' 
			IF @Uploadval IS NULL
				SET @IsTaxBasisEmpty = 'Y'
			ELSE
				SET @IsTaxBasisEmpty = 'N'

			IF @Column='TaxRate' 
			IF @Uploadval IS NULL
				SET @IsTaxRateEmpty = 'Y'
			ELSE
				SET @IsTaxRateEmpty = 'N'

			IF @Column='TaxAmount' 
			IF @Uploadval IS NULL
				SET @IsTaxAmountEmpty = 'Y'
			ELSE
				SET @IsTaxAmountEmpty = 'N'

			IF @Column='PRCo' 
			IF @Uploadval IS NULL
				SET @IsPRCoEmpty = 'Y'
			ELSE
				SET @IsPRCoEmpty = 'N'

			IF @Column='PREmployee' 
			IF @Uploadval IS NULL
				SET @IsPREmployeeEmpty = 'Y'
			ELSE
				SET @IsPREmployeeEmpty = 'N'

		--fetch next record
		if @@fetch_status <> 0
		select @complete = 1

		select @oldrecseq = @Recseq

		fetch next from WorkEditCursor into @Recseq, @Ident, @Tablename, @Column, @Uploadval
		END
	ELSE
		BEGIN
			if @ynglco ='Y' and @Co is not null and @Co <> ''  AND (ISNULL(@OverwriteGLCo, 'Y') = 'Y' OR ISNULL(@IsGLCoEmpty, 'Y') = 'Y')
			begin
				select @GLCo = GLCo from bEMCO Where EMCo = @Co

				select @Identifier = DDUD.Identifier From DDUD
				inner join IMTD ON IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
				Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]' AND DDUD.ColumnName = 'GLCo'

				UPDATE IMWE
				SET IMWE.UploadVal = @GLCo
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @Identifier
			end


			if @ynactualdate ='Y' and @Co is not null and @Co <> '' AND (ISNULL(@OverwriteActualDate, 'Y') = 'Y' OR ISNULL(@IsActualDateEmpty, 'Y') = 'Y')
			begin
				select @Identifier = DDUD.Identifier From DDUD
				inner join IMTD ON IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
				Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'ActualDate'

				UPDATE IMWE
				----#141031
				SET IMWE.UploadVal = convert(varchar(20), dbo.vfDateOnly(),101)
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @Identifier
			end

			if @ynemgroup ='Y' and @Co is not null and @Co <> ''  AND (ISNULL(@OverwriteEMGroup, 'Y') = 'Y' OR ISNULL(@IsEMGroupEmpty, 'Y') = 'Y')
			begin
				exec @rcode = bspEMGroupGet @Co, @EMGroup output, @desc output

				select @Identifier = DDUD.Identifier from DDUD
				inner join IMTD ON IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
				Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'EMGroup'

				UPDATE IMWE
				SET IMWE.UploadVal = @EMGroup
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @Identifier
			end

			if @yncostcode ='Y' and @Co is not null and @Co <> '' AND (ISNULL(@OverwriteCostCode, 'Y') = 'Y' OR ISNULL(@IsCostCodeEmpty, 'Y') = 'Y')
			begin
				select @CostCode = DeprCostCode from bEMCO Where EMCo = @Co

				select @Identifier = DDUD.Identifier From DDUD
				inner join IMTD ON IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
				Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'CostCode'

				UPDATE IMWE
				SET IMWE.UploadVal = @CostCode
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @Identifier
			end

			if @yncosttype ='Y' and @Co is not null and @Co <> '' AND (ISNULL(@OverwriteEMCostType, 'Y') = 'Y' OR ISNULL(@IsEMCostTypeEmpty, 'Y') = 'Y')
			begin
				select @EMCostType = DeprCostType from bEMCO Where EMCo = @Co

				select @Identifier = DDUD.Identifier From DDUD
				inner join IMTD ON IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
				Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'EMCostType'

				UPDATE IMWE
				SET IMWE.UploadVal = @EMCostType
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @Identifier
			end
/*START Issue 134231*/
			if @ynmatlgroup ='Y' and @Co is not null and @Co <> ''  AND (ISNULL(@OverwriteMatlGroup, 'Y') = 'Y' OR ISNULL(@IsMatlGroupEmpty, 'Y') = 'Y')
			begin
				select @MatlGroup = MatlGroup from bHQCO Where HQCo = @Co
				select @Identifier = DDUD.Identifier  From DDUD
				inner join IMTD ON IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
				Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'MatlGroup'

				UPDATE IMWE
				SET IMWE.UploadVal = @MatlGroup
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @Identifier
			end

			if @yninco ='Y' and @Co is not null and @Co <> ''  AND (ISNULL(@OverwriteINCo, 'Y') = 'Y' OR ISNULL(@IsINCoEmpty, 'Y') = 'Y')
			begin
				select @INCo = INCo  from bEMCO Where EMCo = @Co

				select @Identifier = DDUD.Identifier From DDUD
				inner join IMTD ON IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
				Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'INCo'

				UPDATE IMWE
				SET IMWE.UploadVal = @INCo
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @Identifier
			end
---Add Unit Price update

/*END Issue 134231*/
			if @yntaxgroup ='Y' and @Co is not null and @Co <> ''  AND (ISNULL(@OverwriteTaxGroup, 'Y') = 'Y' OR ISNULL(@IsTaxGroupEmpty, 'Y') = 'Y')
			begin
				select @TaxGroup = TaxGroup from bHQCO Where HQCo = @Co

				select @Identifier = DDUD.Identifier  From DDUD
				inner join IMTD ON IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
				Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'TaxGroup'

				UPDATE IMWE
				SET IMWE.UploadVal = @TaxGroup
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @Identifier
			end

			if @yngltransacct ='Y' and @Co is not null and @Co <> '' AND (ISNULL(@OverwriteGLTransAcct, 'Y') = 'Y' OR ISNULL(@IsGLTransAcctEmpty, 'Y') = 'Y')
			begin
				select @EMGLTransAcct = null

				exec @recode = bspEMCostTypeValForCostCode @Co, @EMGroup, @EMCostType, @CostCode,
				@Equipment, 'N', @costtypeout, @EMGLTransAcct output, @msg output

				select @Identifier = DDUD.Identifier From DDUD
				inner join IMTD ON IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
				Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]' AND DDUD.ColumnName = 'GLTransAcct'

				UPDATE IMWE
				SET IMWE.UploadVal = @EMGLTransAcct
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @Identifier
			end

			---- depreciation offset account 'Depn'
			if @yngloffsetacct ='Y' and @Co is not null and @Co <> ''
					AND ISNULL(@EMTransType,'Depn') = 'Depn'
					AND (ISNULL(@OverwriteGLOffsetAcct, 'Y') = 'Y' OR ISNULL(@IsGLOffsetAcctEmpty, 'Y') = 'Y')
				BEGIN
				---- the deprectiation account only applies for type 'Depn'
				SELECT @GLOffsetAcct = DepreciationAcct
				FROM dbo.bEMDM
				where EMCo = @Co
					AND Department = (SELECT Department FROM dbo.bEMEM WHERE EMCo = @Co AND Equipment = @Equipment)
				
				---- update Offset GLCo
				IF ISNULL(@IsOffsetGLCoEmpty, 'Y') = 'Y'
					BEGIN
					----Default OffSet GL Co from EM Company Parameters
					SELECT @OffsetGLCo = GLCo
					FROM dbo.bEMCO 
					WHERE EMCo = @Co
					
					UPDATE dbo.IMWE
						SET IMWE.UploadVal = @OffsetGLCo
					WHERE IMWE.ImportTemplate=@ImportTemplate
						AND IMWE.ImportId=@ImportId
						AND IMWE.RecordSeq=@currrecseq
						AND IMWE.Identifier = @OffSetGLCoId
					END
				
				---- update Offset GL Account
				UPDATE IMWE
					SET IMWE.UploadVal = @GLOffsetAcct
				WHERE IMWE.ImportTemplate=@ImportTemplate
					AND IMWE.ImportId=@ImportId
					AND IMWE.RecordSeq=@currrecseq
					AND IMWE.Identifier = @OffSetGLAcctId
				END
			ELSE
				BEGIN
				--Get Offset GL Co
				if @ynoffsetglco ='Y' and isnull(@Co,'') <> ''
					AND (ISNULL(@OverwriteOffsetGLCo, 'Y') = 'Y' OR ISNULL(@IsOffsetGLCoEmpty, 'Y') = 'Y')
					BEGIN
					----Default OffSet GL Co from EM Company Parameters
					SELECT @OffsetGLCo = GLCo
					FROM dbo.bEMCO 
					WHERE EMCo = @Co
					
					----Override default Offset GLCo when INCo and IN Location both have values
					----Get Offset GL Co from EM Company Parameters
					IF @INCo IS NOT NULL AND isnull(@INLocation,'') <> '' 
						BEGIN 
						SELECT @OffsetGLCo = GLCo
						FROM dbo.bINCO
						WHERE INCo = @INCo 
						END
					 
					UPDATE IMWE
						SET IMWE.UploadVal = @OffsetGLCo
					WHERE IMWE.ImportTemplate=@ImportTemplate
						AND IMWE.ImportId=@ImportId
						AND IMWE.RecordSeq=@currrecseq
						AND IMWE.Identifier = @OffSetGLCoId
					END
					
				----Get Offset GLCo and GLAccount
				IF @yngloffsetacct ='Y' AND isnull(@Co,'') <> ''
						AND (ISNULL(@OverwriteGLOffsetAcct, 'Y') = 'Y' OR ISNULL(@IsGLOffsetAcctEmpty, 'Y') = 'Y')
					BEGIN
					
					SET @GLOffsetAcct = NULL
					if @INCo IS NOT NULL AND ISNULL(@INLocation,'') <> '' 
						BEGIN
						---- Get OffsetGLAcct = EquipSalesGLAcct from INLC or INLS or INLM or EMDM. */
						SELECT @GLOffsetAcct = EquipSalesGLAcct
						FROM dbo.bINLC 
						WHERE INCo = @INCo
							AND Loc = @INLocation
							AND Co = @OffsetGLCo
							AND MatlGroup = @MatlGroup 
							AND Category = (select Category from dbo.bHQMT WHERE MatlGroup = @MatlGroup
												AND Material = @Material)
					
						if isnull(@GLOffsetAcct,'')=''
							begin
							select @GLOffsetAcct = EquipSalesGLAcct from dbo.INLS with (nolock) where INCo = @INCo and Loc = @INLocation  and Co = @OffsetGLCo
							end 
						if @GLOffsetAcct is null
							begin
							select @GLOffsetAcct = EquipSalesGLAcct from dbo.INLM with (nolock) where INCo = @INCo and Loc = @INLocation 
							end
						END
					END

				----Set offset account to Misc from EM
				IF ISNULL(@GLOffsetAcct, '') = ''
					BEGIN
					SELECT @GLOffsetAcct = MatlMiscGLAcct
					from dbo.bEMCO 
					where EMCo = @Co
					END		

				---- update offset GL Account
				UPDATE IMWE
					SET IMWE.UploadVal = @GLOffsetAcct
				WHERE IMWE.ImportTemplate=@ImportTemplate
					AND IMWE.ImportId=@ImportId
					AND IMWE.RecordSeq=@currrecseq
					AND IMWE.Identifier = @OffSetGLAcctId

				END
					


			----TK-17347 if unit price is empty and dollars, um, unit are not calculate unit price
			IF ISNULL(@IsDollarsEmpty,'Y') = 'N' AND ISNULL(@IsUnitsEmpty, 'Y') = 'N'
				AND (ISNULL(@OverwriteUnitPrice,'Y') = 'Y' OR ISNULL(@IsUnitPriceEmpty, 'Y') = 'Y')
			----IF ISNULL(@OverwriteUnitPrice,'Y') = 'Y' AND ISNULL(@IsUnitPriceEmpty, 'Y') = 'Y' AND ISNULL(@IsDollarsEmpty,'Y') = 'N' AND ISNULL(@IsUnitsEmpty, 'Y') = 'N'
				BEGIN
				---- calculate unit price - EM Cost Adjustments always uses 'E' per each
				---- non lump sum only
				IF ISNULL(@UM,'') <> 'LS' AND ISNULL(@Units,0) <> 0 AND ISNULL(@Dollars,0) <> 0
					BEGIN
					SET @Factor = CASE @PerECM WHEN 'E' THEN 1
											   WHEN 'C' THEN 100
											   WHEN 'M' THEN 1000
											   ELSE 1 END
					----calculate unit price - for now do not use ecm			   
					SET @UnitPrice = ROUND((@Dollars / @Units), 5)
					
					---- update IMWE
					UPDATE dbo.IMWE
						SET IMWE.UploadVal = @UnitPrice
					WHERE IMWE.ImportTemplate = @ImportTemplate
						AND IMWE.ImportId=@ImportId
						AND IMWE.RecordSeq=@currrecseq
						AND IMWE.Identifier = @unitpriceid
					END
				END
				


			select @currrecseq = @Recseq
			select @counter = @counter + 1
		END

end
close WorkEditCursor
deallocate WorkEditCursor

bspexit:
select @msg = isnull(@desc,'Equipment') + char(13) + char(10) + '[bspBidtekDefaultEMBF]'

return @rcode



GO
GRANT EXECUTE ON  [dbo].[bspIMBidtekDefaultsEMBF] TO [public]
GO
