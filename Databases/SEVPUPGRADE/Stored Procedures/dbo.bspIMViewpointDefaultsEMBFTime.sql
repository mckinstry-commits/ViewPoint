SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspIMViewpointDefaultsEMBFTime]
/***********************************************************
* CREATED BY: Danf
* MODIFIED BY: TRL  12/17/08 - #131454 change format on Unit to 16,5...fixed PerECM upload value.
*								and decimal values for dollar and price
*								CC	 02/18/09 - Issue #24531 - Use default only if set to overwrite or value is null
*								TRL 05/11/09	- Issue 131362 - Added code for Batch trans Tyupe
*								CC  05/29/09 - Issue #133516 - Correct defaulting of Company
*					GF 09/14/2010 - issue #141031 change to use function vfDateOnly
*					AMR 01/12/11 - #142350, making case sensitive by removing unused vars and renaming same named variables
* 
* Usage:
* Used by Imports to create values for needed or missing
*      data based upon Bidtek default rules.
*
* Input params:
* @ImportId   Import Identifier
* @ImportTemplate   Import ImportTemplate
*
* Output params:
* @msg        error message
*
* Return code:
* 0 = success, 1 = failure
************************************************************/

(@Company bCompany, @ImportId varchar(20), @ImportTemplate varchar(20), @Form varchar(20), @rectype varchar(30), @msg varchar(120) output)

as

set nocount on

declare @rcode int, @recode int, @desc varchar(120),
@ynactualdate bYN, @ynemgroup bYN, @yncostcode bYN, @yncosttype bYN, @ynmatlgroup bYN, @yninco bYN,
@ynglco bYN, @yntaxgroup bYN, @yngltransacct bYN, @yngloffsetacct bYN, @ynfasbooknumberone bYN,
@ynemtranstype bYN,  /*Issue 131362*/@BatchTransTypeID int,
@fasbooknumberid int, @dollarid int, @equipid int, @CompanyID int, @defaultvalue varchar(30),
@UMID int, @SourceID int, @perecmID int, @ynequipment bYN, @ynwoitem bYN, @ynum bYN, @ynunitprice bYN, @yndollars bYN

select @ynactualdate ='N', @ynemgroup ='N', @yncostcode ='N', @yncosttype ='N', 
@ynglco ='N',  @yngltransacct ='N', @yngloffsetacct ='N', @ynmatlgroup = 'N',
@ynequipment = 'Y', @ynwoitem = 'Y', @ynum = 'Y', @ynunitprice = 'Y', @yndollars  = 'Y'

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

-- Check ImportTemplate detail for columns to set Bidtek Defaults
select IMTD.DefaultValue From IMTD
Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'
if @@rowcount = 0
begin
	select @desc='No Bidtek Defaults set up for ImportTemplate ' + @ImportTemplate +'.', @rcode=1
	goto bspexit
end

DECLARE 
@OverwriteSource 	 							bYN,
@OverwriteUM 	 								bYN,
@OverwritePerECM 							bYN,
@OverwriteEMTransType					bYN,
/*Issue 131362*/
@OverwriteBatchTransType 	 			bYN,
@OverwriteActualDate 						bYN,
@OverwriteEMGroup 							bYN,
@OverwriteMatlGroup 						bYN,
@OverwriteEquipment 						bYN,
@OverwriteCostCode 						bYN,
@OverwriteEMCostType 					bYN,
@OverwriteWOItem 	 						bYN,
@OverwriteUnitPrice 							bYN,
@OverwriteDollars 								bYN,
@OverwriteGLCo 	 							bYN,
@OverwriteGLOffsetAcct					bYN,
@OverwriteGLTransAcct					bYN,
@OverwriteCo							bYN,		
@IsCoEmpty 										bYN,
@IsMthEmpty 										bYN,
@IsBatchIdEmpty 								bYN,
@IsBatchSeqEmpty 							bYN,
@IsEMGroupEmpty 							bYN,
@IsBatchTransTypeEmpty 				bYN,
@IsSourceEmpty 								bYN,
@IsEMTransEmpty 							bYN,
@IsPRCoEmpty 									bYN,
@IsPREmployeeEmpty 						bYN,
@IsActualDateEmpty 							bYN,
@IsEMTransTypeEmpty 					bYN,
@IsWorkOrderEmpty 							bYN,
@IsWOItemEmpty 								bYN,
@IsEquipmentEmpty 							bYN,
@IsComponentTypeCodeEmpty 	bYN,
@IsComponentEmpty 						bYN,
@IsCostCodeEmpty 							bYN,
@IsHoursEmpty 									bYN,
@IsEMCostTypeEmpty 						bYN,
@IsGLCoEmpty 									bYN,
@IsOffsetGLCoEmpty 						bYN,
@IsUnitPriceEmpty 							bYN,
@IsUMEmpty 										bYN,
@IsPerECMEmpty 								bYN,
@IsDollarsEmpty 								bYN,
@IsGLTransAcctEmpty 						bYN,
@IsGLOffsetAcctEmpty 						bYN


SELECT @OverwriteSource = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Source', @rectype);
SELECT @OverwriteUM = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'UM', @rectype);
SELECT @OverwritePerECM = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PerECM', @rectype);
SELECT @OverwriteEMTransType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'EMTransType', @rectype);
/*Issue 131362*/
SELECT @OverwriteBatchTransType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'BatchTransType', @rectype);
SELECT @OverwriteActualDate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ActualDate', @rectype);
SELECT @OverwriteEMGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'EMGroup', @rectype);
SELECT @OverwriteMatlGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'MatlGroup', @rectype);
SELECT @OverwriteEquipment = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Equipment', @rectype);
SELECT @OverwriteCostCode = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CostCode', @rectype);
SELECT @OverwriteEMCostType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'EMCostType', @rectype);
SELECT @OverwriteWOItem = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'WOItem', @rectype);
SELECT @OverwriteUnitPrice = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'UnitPrice', @rectype);
SELECT @OverwriteDollars = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Dollars', @rectype);
SELECT @OverwriteGLCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'GLCo', @rectype);
SELECT @OverwriteGLOffsetAcct = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'GLOffsetAcct', @rectype);
SELECT @OverwriteGLTransAcct = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'GLTransAcct', @rectype);
SELECT @OverwriteCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Co', @rectype);

--------- Get Import Identifier and default value type "Y"  -------------------
/*Col:  Co*/
select @CompanyID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Co'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCo, 'Y') = 'Y') 
begin
	UPDATE IMWE
	SET IMWE.UploadVal = @Company
	where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @CompanyID
end
/*Col:  Source*/
select @SourceID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Source'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteSource, 'Y') = 'Y')
begin
	UPDATE IMWE
	SET IMWE.UploadVal = 'EMTime'
	where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @SourceID
end
/*Col:  UM*/
select @UMID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'UM'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteUM, 'Y') = 'Y')
begin
	UPDATE IMWE
	SET IMWE.UploadVal = 'HRS'
	where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @UMID
end
/*Col:  PerECM*/
select @perecmID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue from IMTD
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PerECM'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwritePerECM, 'Y') = 'Y')
begin
	UPDATE IMWE
	SET IMWE.UploadVal = 'E'
	where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @perecmID
end

--------- Get Import Identifier and default value type "N"  -------------------
/*Col:  Co*/
select @CompanyID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Co'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCo, 'Y') = 'N') 
begin
	UPDATE IMWE
	SET IMWE.UploadVal = @Company
	where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @CompanyID
end


/*Col:  Source*/
select @SourceID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Source'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteSource, 'Y') = 'N')
begin
UPDATE IMWE
	SET IMWE.UploadVal = 'EMTime'
	where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @SourceID
	AND IMWE.UploadVal IS NULL
end
/*Col:  UM*/
select @UMID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'UM'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteUM, 'Y') = 'N')
begin
	UPDATE IMWE
	SET IMWE.UploadVal = 'HRS'
	where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @UMID
	AND IMWE.UploadVal IS NULL
end
/*Col:  PerECM*/
select  @perecmID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue from IMTD
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PerECM'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwritePerECM, 'Y') = 'N')
begin
	UPDATE IMWE
	SET IMWE.UploadVal = 'E'
	where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @perecmID
	AND IsNull(IMWE.UploadVal,'')=''
end

--------- Check Default rec  -------------------
/*Col:  EMTransType*/
select IMTD.DefaultValue, DDUD.ColumnName, DDUD.Identifier From IMTD
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'EMTransType'
if @@rowcount <> 0 
begin
	select @ynemtranstype ='Y'
end
/*Col:  ActualDte*/
select IMTD.DefaultValue, DDUD.ColumnName, DDUD.Identifier From IMTD
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'ActualDate'
if @@rowcount <> 0 
begin
	select @ynactualdate ='Y'
end
/*Col:  EMGroup*/
select IMTD.DefaultValue, DDUD.ColumnName, DDUD.Identifier From IMTD
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'EMGroup'
if @@rowcount <> 0 
begin
	select @ynemgroup ='Y'
end
/*Col:  MatlGroup*/
select IMTD.DefaultValue, DDUD.ColumnName, DDUD.Identifier From IMTD
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'MatlGroup'
if @@rowcount <> 0 
begin
	select @ynmatlgroup ='Y'
end
/*Col:  Equipment*/
select IMTD.DefaultValue, DDUD.ColumnName, DDUD.Identifier From IMTD
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'Equipment'
if @@rowcount <> 0 
begin
	select @ynequipment ='Y'
end
/*Col:  CostCode*/
select IMTD.DefaultValue, DDUD.ColumnName, DDUD.Identifier From IMTD
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'CostCode'
if @@rowcount <> 0 
begin
	select @yncostcode ='Y'
end
/*Col:  EMCostType*/
select IMTD.DefaultValue, DDUD.ColumnName, DDUD.Identifier From IMTD
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'EMCostType'
if @@rowcount <> 0 
begin
	select @yncosttype ='Y'
end
/*Col:  EMWOItem*/
select IMTD.DefaultValue, DDUD.ColumnName, DDUD.Identifier From IMTD
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'WOItem'
if @@rowcount <> 0 
begin 
	select @ynwoitem ='Y'
end
/*Col:  UM*/
select IMTD.DefaultValue, DDUD.ColumnName, DDUD.Identifier From IMTD
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'UM'
if @@rowcount <> 0 
begin
	select @ynum ='Y'
end
/*Col:  UnitPrice*/
select IMTD.DefaultValue, DDUD.ColumnName, DDUD.Identifier From IMTD
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'UnitPrice'
if @@rowcount <> 0 
begin
	select @ynunitprice ='Y'
end
/*Col:  Dollars*/
select IMTD.DefaultValue, DDUD.ColumnName, DDUD.Identifier From IMTD
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'Dollars'
if @@rowcount <> 0 
begin
	select @yndollars ='Y'
end
/*Col:  GLCo*/
select IMTD.DefaultValue, DDUD.ColumnName, DDUD.Identifier From IMTD
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'GLCo'
if @@rowcount <> 0 
begin
	select @ynglco ='Y'
end
/*Col:  GLTransAcct */
select IMTD.DefaultValue, DDUD.ColumnName, DDUD.Identifier From IMTD
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'GLTransAcct'
if @@rowcount <> 0 
begin
	select @yngltransacct  ='Y'
end
/*Col:  GLOffset*/
select IMTD.DefaultValue, DDUD.ColumnName, DDUD.Identifier From IMTD
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'GLOffsetAcct'
if @@rowcount <> 0 
begin
	select @yngloffsetacct  ='Y'
end


declare  @Co bCompany, @Mth bMonth, @BatchId bBatchID, @BatchSeq int, @BatchTransType char, @Source bSource,
@Equipment bEquip, @RevCode bRevCode, @EMTrans bTrans, @EMTransType  varchar(10), @ComponentTypeCode varchar(10), @Component bEquip,
@Asset varchar(20), @EMGroup bGroup, @CostCode bCostCode, @EMCostType bEMCType, @ActualDate  bDate, @Description bDesc, @GLCo bCompany,
@EMGLTransAcct bGLAcct, @GLTransAcct bGLAcct, @GLOffsetAcct bGLAcct, @ReversalStatus tinyint, @OrigMth bMonth, @OrigEMTrans bTrans,
@PRCo bCompany, @PREmployee bEmployee, @APCo bCompany, @APTrans bTrans, @APLine bItem, @VendorGrp bGroup, @APVendor bVendor,
@APRef bAPReference, @WorkOrder bWO, @WOItem bItem, @MatlGroup bGroup, @INCo bCompany, @INLocation bLoc, @Material bMatl,
@SerialNo varchar(20), @UM bUM, @Units bUnits, @Dollars bDollar, @UnitPrice bUnitCost, @Hours bHrs, @PerECM bECM,
@JCCo bCompany, @Job bJob, @PhaseGrp bGroup, @JCPhase bPhase, @JCCostType bJCCType, @TaxGroup bGroup,
@Department bDept, @FasBookNumber varchar(10)

declare WorkEditCursor cursor for
select IMWE.RecordSeq, IMWE.Identifier, DDUD.TableName, DDUD.ColumnName, IMWE.UploadVal
from IMWE
inner join DDUD on IMWE.Identifier = DDUD.Identifier and DDUD.Form = IMWE.Form
where IMWE.ImportId = @ImportId and IMWE.ImportTemplate = @ImportTemplate and IMWE.Form = @Form
Order by IMWE.RecordSeq, IMWE.Identifier

open WorkEditCursor
-- set open cursor flag
--#142350 removing   @importid varchar(10), @seq int
DECLARE @Recseq int,
		@Tablename varchar(20),
		@Column varchar(30),
		@Uploadval varchar(60),
		@Ident int,
		@Identifier int

declare @currrecseq int, @allownull int, @error int, @tsql varchar(255), @valuelist varchar(255),
@columnlist varchar(255), @complete int, @counter int, @records int, @oldrecseq int

declare @costtypeout bEMCType

fetch next from WorkEditCursor into @Recseq, @Ident, @Tablename, @Column, @Uploadval

select @currrecseq = @Recseq, @complete = 0, @counter = 1

-- while cursor is not empty
WHILE @complete = 0
BEGIN

	if @@fetch_status <> 0
	begin
		select @Recseq = -1
	end

	--if rec sequence = current rec sequence flag
	IF @Recseq = @currrecseq
		BEGIN
			If @Column='Co' and isnumeric(@Uploadval) =1 select @Co = Convert( int, @Uploadval)
			If @Column='Mth' and isdate(@Uploadval) =1 select @Mth = Convert( smalldatetime, @Uploadval)
			--If @Column='BatchSeq' and  isnumeric(@Uploadval) =1 select @BatchSeq = @Uploadval
			--If @Column='BatchTransType' select @BatchTransType = @Uploadval
			If @Column='Source' select @Source = @Uploadval
			If @Column='Equipment' select @Equipment = @Uploadval
			--If @Column='RevCode' and isnumeric(@Uploadval) =1 select @RevCode = Convert( int, @Uploadval)
			--If @Column='EMTrans' and isdate(@Uploadval) =1 select @EMTrans = Convert( smalldatetime, @Uploadval)
			--If @Column='ComponentTypeCode' select @ComponentTypeCode = @Uploadval
			--If @Column='Component' select @Component = @Uploadval
			--If @Column='Asset' select @Type = @Asset 
			If @Column='EMTransType' select @EMTransType = @Uploadval
			If @Column='EMGroup' and isnumeric(@Uploadval) =1 select @EMGroup = Convert( int, @Uploadval)
			If @Column='CostCode' select @CostCode = @Uploadval
			If @Column='EMCostType' and  isnumeric(@Uploadval) =1 select @EMCostType = @Uploadval
			If @Column='ActualDate' and isdate(@Uploadval) =1 select @ActualDate = Convert( smalldatetime, @Uploadval)
			If @Column='Description' select @Description = @Uploadval
			If @Column='GLCo' and isnumeric(@Uploadval) =1 select @GLCo = Convert( int, @Uploadval)
			If @Column='GLTransAcct' select @GLTransAcct = @Uploadval
			If @Column='GLOffsetAcct' select @GLOffsetAcct = @Uploadval
			--If @Column='ReversalStatus' select @ReversalStatus = @Uploadval
			--If @Column='OrigMth' and  isnumeric(@Uploadval) =1 select @OrigMth = convert(numeric,@Uploadval)
			--If @Column='OrigEMTrans' select @OrigEMTrans = @Uploadval
			If @Column='PRCo' and  isnumeric(@Uploadval) =1 select @PRCo = convert(numeric,@Uploadval)
			If @Column='PREmployee' select @PREmployee = @Uploadval
			--If @Column='APCo' select @APCo = @Uploadval
			--If @Column='APTrans' select @APTrans = @Uploadval
			--If @Column='APLine' select @APLine = @Uploadval
			--If @Column='VendorGrp' select @VendorGrp = @Uploadval
			--If @Column='APVendor' and  isnumeric(@Uploadval) =1 select @APVendor = convert(decimal(10,3),@Uploadval)
			--If @Column='APRef' select @APRef = @Uploadval
			If @Column='WorkOrder' select @WorkOrder = @Uploadval
			If @Column='WOItem' select @WOItem = @Uploadval 
			--If @Column='MatlGroup' and isnumeric(@Uploadval) =1 select @MatlGroup = Convert( int, @Uploadval)
			--If @Column='INCo' and isnumeric(@Uploadval) =1 select @INCo = Convert( int, @Uploadval)
			--If @Column='INLocation' select @INLocation = @Uploadval
			--If @Column='Material' select @Material = @Uploadval
			--If @Column='SerialNo' select @SerialNo = @Uploadval
			If @Column='UM' select @UM = @Uploadval
			--Issue 131454
			If @Column='Units' and isnumeric(@Uploadval) =1 select @Units = convert(decimal(16,5),@Uploadval)
			If @Column='Dollars' and isnumeric(@Uploadval) =1 select @Dollars = convert(decimal(12,2),@Uploadval)
			If @Column='UnitPrice' and isnumeric(@Uploadval) =1 select @UnitPrice = convert(Decimal(12,2),@Uploadval)
			If @Column='Hours' and isnumeric(@Uploadval) =1 select @Hours = convert(decimal(10,3),@Uploadval)
			--Issue 131454
			--If @Column='PerECM' and isnumeric(@Uploadval) =1 select @PerECM = convert(decimal(10,5),@Uploadval)
			If @Column='PerECM' Select @PerECM = @Uploadval
			--/*If @Column='JCCo' and isnumeric(@Uploadval) =1 select @JCCo = convert(decimal(10,2),@Uploadval)
			--If @Column='Job' select @Job = @Uploadval
			--If @Column='PhaseGrp' select @PhaseGrp = @Uploadval
			--If @Column='JCPhase' select @JCPhase = @Uploadval
			--If @Column='JCCostType' select @JCCostType = @Uploadval
			--If @Column='TaxType' select @TaxType = @Uploadval 
			--If @Column='TaxGroup' and isnumeric(@Uploadval) =1 select @TaxGroup = Convert( int, @Uploadval)
			--If @Column='TaxBasis' select @TaxBasis = @Uploadval
			--If @Column='TaxRate' and isnumeric(@Uploadval) =1 select @TaxRate = convert(numeric,@Uploadval)
			--If @Column='TaxAmount' and isnumeric(@Uploadval) =1 select @TaxAmount = convert(numeric,@Uploadval)*/

			IF @Column='Co' 
			BEGIN
				If @Uploadval IS NULL
					Begin
						SET @IsCoEmpty = 'Y'
					End
				Else
					Begin
						SET @IsCoEmpty = 'N'
					End
			END
			IF @Column='Mth' 
			BEGIN
				If @Uploadval IS NULL
					Begin
						SET @IsMthEmpty = 'Y'
					End
				Else
					Begin
						SET @IsMthEmpty = 'N'
					End
			END
			IF @Column='BatchId' 
			BEGIN
				If @Uploadval IS NULL
					Begin
						SET @IsBatchIdEmpty = 'Y'
					End
				Else
					Begin
						SET @IsBatchIdEmpty = 'N'
					End
			END
			IF @Column='BatchSeq' 
			BEGIN
				If @Uploadval IS NULL
					Begin
						SET @IsBatchSeqEmpty = 'Y'
					End
				Else
					Begin
						SET @IsBatchSeqEmpty = 'N'
					End
			END
			IF @Column='EMGroup' 
			BEGIN
				If @Uploadval IS NULL
					Begin
						SET @IsEMGroupEmpty = 'Y'
					End
				Else
					Begin
						SET @IsEMGroupEmpty = 'N'
					End
			END
			IF @Column='BatchTransType' 
			BEGIN
				If @Uploadval IS NULL
					Begin
						SET @IsBatchTransTypeEmpty = 'Y'
					End
				Else
					Begin
						SET @IsBatchTransTypeEmpty = 'N'
					End
			END
			IF @Column='Source' 
			BEGIN
				If @Uploadval IS NULL
					Begin
						SET @IsSourceEmpty = 'Y'
					End
				Else
					Begin
						SET @IsSourceEmpty = 'N'
					End
			END
			IF @Column='EMTrans' 
			BEGIN
				If @Uploadval IS NULL
					Begin
						SET @IsEMTransEmpty = 'Y'
					End
				Else
					Begin
						SET @IsEMTransEmpty = 'N'
					End
			END
			IF @Column='PRCo' 
			BEGIN
				If @Uploadval IS NULL
					Begin
						SET @IsPRCoEmpty = 'Y'
					End
				Else
					Begin
						SET @IsPRCoEmpty = 'N'
					End
			END
			IF @Column='PREmployee' 
			BEGIN
				If @Uploadval IS NULL
					Begin
						SET @IsPREmployeeEmpty = 'Y'
					End
				Else
					Begin
						SET @IsPREmployeeEmpty = 'N'
					End
			END
			IF @Column='ActualDate' 
			BEGIN
				If @Uploadval IS NULL
					Begin
						SET @IsActualDateEmpty = 'Y'
					End
				Else
					Begin
						SET @IsActualDateEmpty = 'N'
					End
			END
			IF @Column='EMTransType' 
			BEGIN
				If @Uploadval IS NULL
					Begin
						SET @IsEMTransTypeEmpty = 'Y'
					End
				Else
					Begin
						SET @IsEMTransTypeEmpty = 'N'
					End
			END
			IF @Column='WorkOrder' 
			BEGIN
				If @Uploadval IS NULL
					Begin
						SET @IsWorkOrderEmpty = 'Y'
					End
				Else
					Begin
						SET @IsWorkOrderEmpty = 'N'
					End
			END
			IF @Column='WOItem' 
			BEGIN
				If @Uploadval IS NULL
					Begin
						SET @IsWOItemEmpty = 'Y'
					End
				Else
					Begin
						SET @IsWOItemEmpty = 'N'
					End
			END
			IF @Column='Equipment' 
			BEGIN
				If @Uploadval IS NULL
					Begin
						SET @IsEquipmentEmpty = 'Y'
					End
				Else
					Begin
						SET @IsEquipmentEmpty = 'N'
					End
			END
			IF @Column='ComponentTypeCode' 
			BEGIN
				If @Uploadval IS NULL
					Begin
						SET @IsComponentTypeCodeEmpty = 'Y'
					End
				Else
					Begin
						SET @IsComponentTypeCodeEmpty = 'N'
					End
			END
			IF @Column='Component' 
			BEGIN
				If @Uploadval IS NULL
					Begin
						SET @IsComponentEmpty = 'Y'
					End
				Else
					Begin
						SET @IsComponentEmpty = 'N'
					End
			END
			IF @Column='CostCode' 
			BEGIN
				If @Uploadval IS NULL
					Begin
						SET @IsCostCodeEmpty = 'Y'
					End
				Else
					Begin
						SET @IsCostCodeEmpty = 'N'
					End
			END
			IF @Column='EMCostType' 
			BEGIN
			If @Uploadval IS NULL
					Begin
						SET @IsEMCostTypeEmpty = 'Y'
					End
				Else
					Begin
						SET @IsEMCostTypeEmpty = 'N'
					End
			END
			IF @Column='UM' 
			BEGIN
				If @Uploadval IS NULL
					Begin
						SET @IsUMEmpty = 'Y'
					End
				Else
					Begin
						SET @IsUMEmpty = 'N'
					End
			END
			IF @Column='PerECM' 
			BEGIN
				If @Uploadval IS NULL
					Begin
						SET @IsPerECMEmpty = 'Y'
					End
				Else
					Begin
						SET @IsPerECMEmpty = 'N'
					End
			END
			IF @Column='UnitPrice' 
			BEGIN
				If @Uploadval IS NULL
					Begin
						SET @IsUnitPriceEmpty = 'Y'
					End
				Else
					Begin
						SET @IsUnitPriceEmpty = 'N'
					End
			END
			IF @Column='Hours' 
			BEGIN
				If @Uploadval IS NULL
					Begin
						SET @IsHoursEmpty = 'Y'
					End
				Else
					Begin
						SET @IsHoursEmpty = 'N'
					End
			END
			IF @Column='Dollars' 
			BEGIN
				If @Uploadval IS NULL
					Begin
						SET @IsDollarsEmpty = 'Y'
					End
				Else
					Begin
						SET @IsDollarsEmpty = 'N'
					End
			END
			IF @Column='OffsetGLCo' 
			BEGIN
				If @Uploadval IS NULL
					Begin
						SET @IsOffsetGLCoEmpty = 'Y'
					End
				Else
					Begin
						SET @IsOffsetGLCoEmpty = 'N'
					End
			END
			IF @Column='GLTransAcct' 
			BEGIN
				If @Uploadval IS NULL
					Begin
						SET @IsGLTransAcctEmpty = 'Y'
					End
				Else
					Begin
						SET @IsGLTransAcctEmpty = 'N'
					End
			END
			IF @Column='GLCo' 
			BEGIN
				If @Uploadval IS NULL
					Begin
						SET @IsGLCoEmpty = 'Y'
					End
				Else
					Begin
						SET @IsGLCoEmpty = 'N'
					End
			END
			IF @Column='GLOffsetAcct' 
			BEGIN
				If @Uploadval IS NULL
					Begin
						SET @IsGLOffsetAcctEmpty = 'Y'
					End
				Else
					Begin
						SET @IsGLOffsetAcctEmpty = 'N'
					End
			END
			--fetch next record

			if @@fetch_status <> 0
			begin
				select @complete = 1
			end

			select @oldrecseq = @Recseq

			fetch next from WorkEditCursor into @Recseq, @Ident, @Tablename, @Column, @Uploadval
		END
	ELSE
		BEGIN
			/* Col:  BatchTransType  */
			/*Issue 131362*/
			select @BatchTransTypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD  with (nolock)
			inner join DDUD  with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
			Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'BatchTransType'
			if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteBatchTransType, 'Y') = 'N')
			begin
				UPDATE IMWE
				SET IMWE.UploadVal = 'A'
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @BatchTransTypeID
				AND IMWE.UploadVal IS NULL
			end   
			/* Col:  MatlGroup  */
			if @ynmatlgroup ='Y' and (@Co is not null or IsNull(@Co,0) <> 0) AND (ISNULL(@OverwriteMatlGroup, 'Y') = 'Y' OR @MatlGroup IS NULL) 
			begin
				select @MatlGroup = MatlGroup	from bHQCO with (nolock) Where HQCo = @Co

				select @Identifier = DDUD.Identifier From DDUD
				inner join IMTD ON IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
				Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'MatlGroup'

				UPDATE IMWE
				SET IMWE.UploadVal = @MatlGroup
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @Identifier
			end
			/* Col:  EMGroup  */
			if @ynemgroup ='Y' and (@Co is not null or IsNull(@Co,0) <> 0) AND (ISNULL(@OverwriteEMGroup, 'Y') = 'Y' OR ISNULL(@IsEMGroupEmpty, 'Y') = 'Y')
			begin
				exec @rcode = bspEMGroupGet @Co, @EMGroup output, @desc output

				select @Identifier = DDUD.Identifier	From DDUD
				inner join IMTD ON IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
				Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'EMGroup'

				UPDATE IMWE
				SET IMWE.UploadVal = @EMGroup
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @Identifier
			end
			/* Col:  Equipment  */
		--	if @ynequipment ='Y' and (@Co is not null or IsNull(@Co,0) <> 0) and isnull(@WorkOrder ,'') <> ''   AND (ISNULL(@OverwriteEquipment, 'Y') = 'Y' OR ISNULL(@IsEquipmentEmpty, 'Y') = 'Y')
			begin
				select @Equipment = Equipment 	from EMWH 	where EMCo = @Co and WorkOrder = @WorkOrder 

				select @Identifier = DDUD.Identifier From DDUD
				inner join IMTD ON IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
				Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'Equipment'

				UPDATE IMWE
				SET IMWE.UploadVal = @Equipment
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @Identifier
			end   
			/* Col:  ActualDate  */
			if @ynactualdate ='Y' and (@Co is not null or IsNull(@Co,0) <> 0) AND (ISNULL(@OverwriteActualDate, 'Y') = 'Y' OR ISNULL(@IsActualDateEmpty, 'Y') = 'Y')
			begin
				select @Identifier = DDUD.Identifier 	From DDUD
				inner join IMTD ON IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
				Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'ActualDate'

				UPDATE IMWE
				----#141031
				SET IMWE.UploadVal = convert(varchar(20), dbo.vfDateOnly(),101)
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @Identifier
			end
			/* Col:  UnitPrice  */
			if @ynunitprice ='Y' and (@PRCo is not null or  IsNull(@PRCo,0) <> 0) and isnull(@PREmployee ,'') <> ''  AND (ISNULL(@OverwriteUnitPrice, 'Y') = 'Y' OR ISNULL(@IsUnitPriceEmpty, 'Y') = 'Y')
			begin
				select @UnitPrice = EMFixedRate from PREH 	where PRCo = @PRCo and Employee = @PREmployee

				select @Identifier = DDUD.Identifier	From DDUD
				inner join IMTD ON IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
				Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'UnitPrice'

				UPDATE IMWE
				SET IMWE.UploadVal = @UnitPrice
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @Identifier
			end
			/* Col:  Dollars  */
			if @yndollars ='Y' and (@Co is not null or IsNull(@Co,0) <> 0) AND (ISNULL(@OverwriteDollars, 'Y') = 'Y' OR ISNULL(@IsDollarsEmpty, 'Y') = 'Y')
			begin
					--if @UnitPrice is not null and @Units is not null 
					if IsNull(@UnitPrice,0)<>0 and IsNull(IsNull(@Units,@Hours),0)<>0
					begin
						select @Dollars = IsNull(IsNull(@Units,@Hours),0)* @UnitPrice
					end
				else
					begin
						select @Dollars = 0
					end
							select @Identifier = DDUD.Identifier	From DDUD
				inner join IMTD ON IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
				Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'Dollars'

				UPDATE IMWE
				SET IMWE.UploadVal = @Dollars
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @Identifier
			end
			
			/* Col:  CostCode  */
			if @yncostcode ='Y' and (@Co is not null or IsNull(@Co,0) <> 0) and isnull(@WorkOrder ,'') <> ''   AND (ISNULL(@OverwriteCostCode, 'Y') = 'Y' OR ISNULL(@IsCostCodeEmpty, 'Y') = 'Y')
			begin
				select @CostCode = CostCode 	from EMWI where EMCo = @Co and WorkOrder = @WorkOrder and WOItem = @WOItem

				select @Identifier = DDUD.Identifier From DDUD
				inner join IMTD ON IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
				Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'CostCode'

				UPDATE IMWE
				SET IMWE.UploadVal = @CostCode
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @Identifier
			end
			/* Col:  EMCostType  */
			if @yncosttype ='Y' and (@Co is not null or IsNull(@Co,0) <> 0)  AND (ISNULL(@OverwriteEMCostType, 'Y') = 'Y' OR ISNULL(@IsEMCostTypeEmpty, 'Y') = 'Y')
			begin
				select @EMCostType = LaborCT 	from bEMCO	Where EMCo = @Co

				select @Identifier = DDUD.Identifier 	From DDUD
				inner join IMTD ON IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
				Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'EMCostType'

				UPDATE IMWE
				SET IMWE.UploadVal = @EMCostType
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @Identifier
			end
			/* Col:  GLCo  */
			if @ynglco ='Y' and (@Co is not null or IsNull(@Co,0) <> 0)  AND (ISNULL(@OverwriteGLCo, 'Y') = 'Y' OR ISNULL(@IsGLCoEmpty, 'Y') = 'Y')
			begin
				select @GLCo = GLCo 	from bEMCO Where EMCo = @Co

				select @Identifier = DDUD.Identifier	From DDUD
				inner join IMTD ON IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
				Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]' AND DDUD.ColumnName = 'GLCo'

				UPDATE IMWE
				SET IMWE.UploadVal = @GLCo
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @Identifier
			end
			/* Col:  GLTransAcct  */
			if @yngltransacct ='Y' and (@Co is not null or IsNull(@Co,0) <> 0) AND (ISNULL(@OverwriteGLTransAcct, 'Y') = 'Y' OR ISNULL(@IsGLTransAcctEmpty, 'Y') = 'Y')
			begin
				select @EMGLTransAcct = null

				exec @recode = bspEMCostTypeValForCostCode @Co, @EMGroup, @EMCostType, @CostCode,
				@Equipment, 'N', @costtypeout, @EMGLTransAcct output,		@msg output

				select @Identifier = DDUD.Identifier 				From DDUD
				inner join IMTD ON IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
				Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]' AND DDUD.ColumnName = 'GLTransAcct'

				UPDATE IMWE
				SET IMWE.UploadVal = @EMGLTransAcct
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @Identifier
			end
			/* Col:  GLOffsetAcct  */
			if @yngloffsetacct ='Y' and (@Co is not null or IsNull(@Co,0) <> 0) AND (ISNULL(@OverwriteGLOffsetAcct, 'Y') = 'Y' OR ISNULL(@IsGLOffsetAcctEmpty, 'Y') = 'Y')
			begin
				select @Department = Department  from bEMEM Where EMCo = @Co and Equipment = @Equipment

				select @GLOffsetAcct = LaborFixedRateAcct from bEMDM where EMCo = @Co and Department = @Department

				select @Identifier = DDUD.Identifier 		From DDUD
				inner join IMTD ON IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
				Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'GLOffsetAcct'

				UPDATE IMWE
				SET IMWE.UploadVal = @GLOffsetAcct
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @Identifier
			end

			select @currrecseq = @Recseq
			select @counter = @counter + 1

		END
END


close WorkEditCursor
deallocate WorkEditCursor

bspexit:
select @msg = isnull(@desc,'Equipment') + char(13) + char(10) + '[bspViewpointDefaultEMBFTimecard]'
return @rcode




GO
GRANT EXECUTE ON  [dbo].[bspIMViewpointDefaultsEMBFTime] TO [public]
GO
