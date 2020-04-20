SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[bspIMBidtekDefaultsEMBFFuel]
/***********************************************************
* CREATED BY: Danf
* MODIFIED BY: danf 03/14/02 Added @inco to bspEMEquipPartVal
*            	DANF 03/19/02 - Added Record Type
*			 	DANF 09/08/2003 - 22380 Correct Unit Price Default and add speed up.
*				DANF 09/08/2003 - 22381 Corrected Gl offset account when material is from inventory.
*				DANF 06/12/2006 - 121360 Corrected Default for Tax Code
*				TRL  10/27/2008	- 130765 format numeric imports according viewpoint datatypes
*				TRL  12/17/2008 - #131454 change format on Unit to 16,5
*				CC	02/18/2009	- Issue #24531 - Use default only if set to overwrite or value is null
*				CC  05/29/2009	- Issue #133516 - Correct defaulting of Company
*				CHS	10/13/2009	- Issue #29996 - default material description.
*				TRL 12/23/2009 -Issue 1363450 - Set correct Matl Group and Offset GLCo
*				GF 09/12/2010 - issue #141031 changed to use vfDateOnly
*				AMR 01/12/11 - #142350 - making case sensitive by removing @inusemth that is not used 
*				GF 08/25/2012 TK-17367 update import record with correct Offset GLCo
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
   
declare @rcode int, @recode int, @desc varchar(120), @defaultvalue varchar(30),
@ynactualdate bYN, @ynemgroup bYN, @yncostcode bYN, @yncosttype bYN, @ynmatlgroup bYN, @yninco bYN,
@ynglco bYN,@ynoffsetglco bYN/*136350*/, @yntaxgroup bYN, @yngltransacct bYN, @yngloffsetacct bYN, @ynmaterial bYN,
@ynum bYN, @ynunitprice bYN, @yndollars bYN, @yntaxtype bYN, @ynperecm bYN, @yntaxcode bYN

declare @dollarid int, @equipid int, @actualdateid int, @emgroupid int, @costcodeid int, @emcosttypeid int, @matlgroupid int,
@incoid int, @glcoid int, @offsetglcoid int /*136350*/, @taxgroupid int, @gltransacctid int, @gloffsetacctid int, @materialid int,
@umid int, @unitpriceid int, @dollarsid int, @taxtypeid int, @perecmid int, @taxcodeid int, @CompanyID int,
@DescID bItemDesc   -- Issue #29996     

select @ynactualdate ='N', @ynemgroup ='N', @yncostcode ='N', @yncosttype ='N', @ynmatlgroup ='N', @yninco ='N',
@ynglco ='N',@ynoffsetglco ='N' /*136350*/, @yntaxgroup ='N', @yngltransacct ='N', @yngloffsetacct ='N', @ynmaterial = 'N',
@ynum ='N', @ynunitprice ='N', @yndollars ='N', @yntaxtype ='N', @ynperecm = 'N', @yntaxcode = 'N'

/* check required input params */
if isnull(@ImportId,'')=''
begin
	select @desc = 'Missing ImportId.', @rcode = 1
	goto bspexit
end

if isnull(@ImportTemplate,'')=''
begin
	select @desc = 'Missing ImportTemplate.', @rcode = 1
	goto bspexit
end

if isnull(@Form,'')=''
begin
	select @desc = 'Missing Form.', @rcode = 1
	goto bspexit
end

-- Check ImportTemplate detail for columns to set Bidtek Defaults

if not exists(select IMTD.DefaultValue From IMTD with (nolock)
       Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'
       and IMTD.RecordType = @rectype)
begin 
	 select @desc='No Bidtek Defaults set up for ImportTemplate ' + @ImportTemplate +'.', @rcode=1
	goto bspexit
end

DECLARE 
@OverwriteActualDate 	 	 bYN,
@OverwriteEMGroup 	 	 bYN,
@OverwriteCostCode 	 	 bYN,
@OverwriteEMCostType 	 	 bYN,
@OverwriteMatlGroup 	 	 bYN,
@OverwriteMaterial 	 	 bYN,
@OverwriteINCo 	 		 bYN,
@OverwriteGLCo 	 	 	 bYN,
@OverwriteOffsetGLCo 	 	 	 bYN,--/*136350*/
@OverwriteTaxGroup 	 	 bYN,
@OverwriteGLTransAcct 	 bYN,
@OverwriteGLOffsetAcct 	 bYN,
@OverwriteUM 	 	 	 	 bYN,
@OverwriteUnitPrice 	 	 bYN,
@OverwriteDollars 	 	 bYN,
@OverwriteTaxType 	 	 bYN,
@OverwritePerECM 	 	 	 bYN,
@OverwriteTaxCode 	 	 bYN,
@OverwriteCo				 bYN,
@OverwriteDesc			 bYN,-- Issue #29996
@IsCoEmpty 					 bYN,
@IsMthEmpty 				 bYN,
@IsBatchIdEmpty 			 bYN,
@IsBatchSeqEmpty 			 bYN,
@IsSourceEmpty 				 bYN,
@IsBatchTransTypeEmpty 		 bYN,
@IsEMTransEmpty 			 bYN,
@IsActualDateEmpty 			 bYN,
@IsEMTransTypeEmpty 		 bYN,
@IsReversalStatusEmpty 		 bYN,
@IsEMGroupEmpty 			 bYN,
@IsWorkOrderEmpty 			 bYN,
@IsWOItemEmpty 				 bYN,
@IsEquipmentEmpty 			 bYN,
@IsComponentTypeCodeEmpty 	 bYN,
@IsComponentEmpty 			 bYN,
@IsCostCodeEmpty 			 bYN,
@IsEMCostTypeEmpty 			 bYN,
@IsMatlGroupEmpty 			 bYN,
@IsINCoEmpty 				 bYN,
@IsINLocationEmpty 			 bYN,
@IsMaterialEmpty 			 bYN,
@IsDescriptionEmpty 		 bYN,
@IsGLCoEmpty 				 bYN,
@IsGLTransAcctEmpty 		 bYN,
@IsOffsetGLCoEmpty 				 bYN,/*136350*/
@IsGLOffsetAcctEmpty 		 bYN,
@IsUnitsEmpty 				 bYN,
@IsUMEmpty 					 bYN,
@IsUnitPriceEmpty 			 bYN,
@IsPerECMEmpty 				 bYN,
@IsDollarsEmpty 			 bYN,
@IsSerialNoEmpty 			 bYN,
@IsMeterReadDateEmpty 		 bYN,
@IsCurrentOdometerEmpty 	 bYN,
@IsCurrentHourMeterEmpty 	 bYN,
@IsCurrentTotalHourMeterEmpty 	 bYN,
@IsCurrentTotalOdometerEmpty 	 bYN,
@IsTaxGroupEmpty 				 bYN,
@IsTaxTypeEmpty 				 bYN,
@IsTaxCodeEmpty 				 bYN,
@IsTaxBasisEmpty 				 bYN,
@IsTaxRateEmpty 				 bYN,
@IsTaxAmountEmpty 				 bYN,
@IsPRCoEmpty 					 bYN,
@IsPREmployeeEmpty 				 bYN

SELECT @OverwriteActualDate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ActualDate', @rectype);
SELECT @OverwriteEMGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'EMGroup', @rectype);
SELECT @OverwriteCostCode = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CostCode', @rectype);
SELECT @OverwriteEMCostType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'EMCostType', @rectype);
SELECT @OverwriteMatlGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'MatlGroup', @rectype);
SELECT @OverwriteMaterial = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Material', @rectype);
SELECT @OverwriteINCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'INCo', @rectype);
SELECT @OverwriteGLCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'GLCo', @rectype);
SELECT @OverwriteTaxGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TaxGroup', @rectype);
SELECT @OverwriteGLTransAcct = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'GLTransAcct', @rectype);
SELECT @OverwriteGLOffsetAcct = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'GLOffsetAcct', @rectype);
----TK-17367
SELECT @OverwriteOffsetGLCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'GLOffsetGLCo', @rectype);
SELECT @OverwriteUM = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'UM', @rectype);
SELECT @OverwriteUnitPrice = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'UnitPrice', @rectype);
SELECT @OverwriteDollars = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Dollars', @rectype);
SELECT @OverwriteTaxType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TaxType', @rectype);
SELECT @OverwritePerECM = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PerECM', @rectype);
SELECT @OverwriteTaxCode = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TaxCode', @rectype);
SELECT @OverwriteCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Co', @rectype);
SELECT @OverwriteDesc = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Description', @rectype)-- Issue #29996    
SELECT @DescID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Description', @rectype, 'Y');-- Issue #29996    
   
select @CompanyID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Co'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCo, 'Y') = 'Y') 
begin
      UPDATE IMWE
      SET IMWE.UploadVal = @Company
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @CompanyID
end

select @CompanyID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Co'
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCo, 'Y') = 'N') 
begin
      UPDATE IMWE
      SET IMWE.UploadVal = @Company
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @CompanyID
end
   
select @defaultvalue = IMTD.DefaultValue, @actualdateid = DDUD.Identifier
From IMTD with (nolock)
inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'ActualDate'
if @defaultvalue = '[Bidtek]' 
begin 
	select @ynactualdate ='Y' 
end
   
select @defaultvalue = IMTD.DefaultValue, @emgroupid = DDUD.Identifier
From IMTD with (nolock)
inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'EMGroup'
if @defaultvalue = '[Bidtek]'  
begin 
	select @ynemgroup ='Y' 
end
   
select @defaultvalue = IMTD.DefaultValue, @costcodeid = DDUD.Identifier
From IMTD with (nolock)
inner join DDUD  with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'CostCode'
if @defaultvalue = '[Bidtek]'  
begin
	select @yncostcode ='Y'
end

select @defaultvalue = IMTD.DefaultValue, @emcosttypeid = DDUD.Identifier
From IMTD with (nolock)
inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'EMCostType'
if @defaultvalue = '[Bidtek]'  
begin 
	select @yncosttype ='Y'
end

select @defaultvalue = IMTD.DefaultValue, @matlgroupid = DDUD.Identifier
From IMTD with (nolock)
inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'MatlGroup'
if @defaultvalue = '[Bidtek]'  
begin
	select @ynmatlgroup ='Y'
end

select @defaultvalue = IMTD.DefaultValue, @incoid = DDUD.Identifier
From IMTD with (nolock)
inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'INCo'
if @defaultvalue = '[Bidtek]'  
begin 
	select @yninco ='Y'
end

select @defaultvalue = IMTD.DefaultValue, @materialid = DDUD.Identifier
From IMTD with (nolock)
inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Material'
if @defaultvalue = '[Bidtek]'  
begin
	select @ynmaterial ='Y'
end

select @defaultvalue = IMTD.DefaultValue, @umid = DDUD.Identifier From IMTD with (nolock)
inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'UM'
if @defaultvalue = '[Bidtek]' 
begin
	select @ynum ='Y'
end

select @defaultvalue = IMTD.DefaultValue, @unitpriceid = DDUD.Identifier From IMTD with (nolock)
inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'UnitPrice'
if @defaultvalue = '[Bidtek]'  
begin
	select @ynunitprice ='Y' 
end

select @defaultvalue = IMTD.DefaultValue, @dollarsid = DDUD.Identifier From IMTD with (nolock)
inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Dollars'
if @defaultvalue = '[Bidtek]'  
begin
	select @yndollars  ='Y'
end

select @defaultvalue = IMTD.DefaultValue, @perecmid = DDUD.Identifier From IMTD with (nolock)
inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PerECM'
if @defaultvalue = '[Bidtek]'  
begin
	select @ynperecm  ='Y'
end

select @defaultvalue = IMTD.DefaultValue, @taxcodeid = DDUD.Identifier From IMTD with (nolock)
inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'TaxCode'
if @defaultvalue = '[Bidtek]'  
begin
	select @yntaxcode  ='Y'
end

select @defaultvalue = IMTD.DefaultValue, @taxtypeid = DDUD.Identifier From IMTD with (nolock)
inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'TaxType'
if @defaultvalue = '[Bidtek]'
begin 
	select @yntaxtype  ='Y'
end

select @defaultvalue = IMTD.DefaultValue, @glcoid = DDUD.Identifier From IMTD with (nolock)
inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'GLCo'
if @defaultvalue = '[Bidtek]'  
begin
	select @ynglco ='Y'
end 

----TK-17367
select @defaultvalue = IMTD.DefaultValue, @offsetglcoid = DDUD.Identifier From IMTD with (nolock)
inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'OffsetGLCo'
if @defaultvalue = '[Bidtek]'  
begin
	select @ynoffsetglco ='Y'
end 


select @defaultvalue = IMTD.DefaultValue, @taxgroupid = DDUD.Identifier From IMTD with (nolock)
inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'TaxGroup'
if @defaultvalue = '[Bidtek]'  
begin
	select @yntaxgroup ='Y'
end

select @defaultvalue = IMTD.DefaultValue, @gltransacctid = DDUD.Identifier From IMTD with (nolock)
inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'GLTransAcct'
if @defaultvalue = '[Bidtek]'  
begin
	select @yngltransacct  ='Y'
end

select @defaultvalue = IMTD.DefaultValue, @gloffsetacctid = DDUD.Identifier From IMTD with (nolock)
inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'GLOffsetAcct'
if @defaultvalue = '[Bidtek]'  
begin
	select @yngloffsetacct  ='Y'
end

declare  @Co bCompany, @Mth bMonth, @BatchId bBatchID, @BatchSeq int, @BatchTransType char, @Source bSource,
@Equipment bEquip, @RevCode bRevCode, @EMTrans bTrans, @EMTransType  varchar(10), @ComponentTypeCode varchar(10), @Component bEquip,
@Asset varchar(20), @EMGroup bGroup, @CostCode bCostCode, @EMCostType bEMCType, @ActualDate  bDate, @Description bDesc, @GLCo bCompany,@OffsetGLCo bCompany,/*136350*/
@GLTransAcct bGLAcct, @GLOffsetAcct bGLAcct, @ReversalStatus tinyint, @OrigMth bMonth, @OrigEMTrans bTrans,
@PRCo bCompany, @PREmployee bEmployee, @APCo bCompany, @APTrans bTrans, @APLine bItem, @VendorGrp bGroup, @APVendor bVendor,
@APRef bAPReference, @WorkOrder bWO, @WOItem bItem, @MatlGroup bGroup, @INCo bCompany, @INLocation bLoc, @Material bMatl,
@SerialNo varchar(20), @UM bUM, @Units bUnits, @Dollars bDollar, @UnitPrice bUnitCost, @Hours bHrs, @PerECM bECM,
@JCCo bCompany, @Job bJob, @PhaseGrp bGroup, @JCPhase bPhase, @JCCostType bJCCType, @TaxGroup bGroup,
@Department bDept, @FuelCostCode bCostCode, @FuelMaterial bMatl, @FuelEMCostType bEMCType,
@CurrentHourMeter bHrs, @CurrentOdoMeter bHrs, @FuelUM bUM, @ECMFact int, @EMEP_HQMatl bMatl, @stdum bUM,
@price bUnitCost, @stocked bYN, @category varchar(10), @taxcodein bTaxCode, @taxcodeout bTaxCode

declare WorkEditCursor cursor local fast_forward for
select IMWE.RecordSeq, IMWE.Identifier, DDUD.TableName, DDUD.ColumnName, IMWE.UploadVal
from IMWE
inner join DDUD on IMWE.Identifier = DDUD.Identifier and DDUD.Form = IMWE.Form
where IMWE.ImportId = @ImportId and IMWE.ImportTemplate = @ImportTemplate and IMWE.Form = @Form
Order by IMWE.RecordSeq, IMWE.Identifier
   
open WorkEditCursor
-- set open cursor flag
-- #142350 - @importid not used removed it
declare @Recseq int, @Tablename varchar(20), @Column varchar(30), @Uploadval varchar(60), @Ident int,
	 @seq int, @Identifier int
   
declare @crcsq int, @allownull int, @error int, @tsql varchar(255), @valuelist varchar(255),
@columnlist varchar(255), @complete int, @counter int, @records int, @oldrecseq int
   
declare @costtypeout bEMCType

fetch next from WorkEditCursor into @Recseq, @Ident, @Tablename, @Column, @Uploadval

select @crcsq = @Recseq, @complete = 0, @counter = 1

-- while cursor is not empty
while @complete = 0
begin
	if @@fetch_status <> 0
	select @Recseq = -1

	--if rec sequence = current rec sequence flag
	if @Recseq = @crcsq
		begin
			If @Column='Co' and isnumeric(@Uploadval) =1 select @Co = Convert( int, @Uploadval)
			If @Column='Mth' and isdate(@Uploadval) =1 select @Mth = Convert( smalldatetime, @Uploadval)
			/*	If @Column='BatchSeq' and  isnumeric(@Uploadval) =1 select @BatchSeq = @Uploadval
			If @Column='BatchTransType' select @BatchTransType = @Uploadval*/
			If @Column='Source' select @Source = @Uploadval
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
			If @Column='OffsetGLCo' and isnumeric(@Uploadval) =1 select @OffsetGLCo = Convert( int, @Uploadval)/*136350*/
			If @Column='GLTransAcct' select @GLTransAcct = @Uploadval
			If @Column='GLOffsetAcct' select @GLOffsetAcct = @Uploadval
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
			/*	If @Column='SerialNo' select @SerialNo = @Uploadval*/
			If @Column='UM' select @UM = @Uploadval
			--Issue 130765
			--Issue #131454
			If @Column='Units' and isnumeric (@Uploadval) = 1 select @Units = convert(decimal(16,5),@Uploadval)

			If @Column='Dollars' and isnumeric(@Uploadval) =1 select @Dollars = convert(numeric(12,2),@Uploadval)
			If @Column='UnitPrice' and isnumeric(@Uploadval) =1 select @UnitPrice = convert(numeric(12,2),@Uploadval)
			/*	If @Column='Hours' and isnumeric(@Uploadval) =1 select @Hours = convert(decimal(10,3),@Uploadval)*/
			If @Column='PerECM' select @PerECM = @Uploadval
			If @Column='CurrentHourMeter' and isnumeric(@Uploadval) =1 select @CurrentHourMeter = convert(numeric(10,2),@Uploadval)
			If @Column='CurrentOdoMeter' and isnumeric(@Uploadval) =1 select @CurrentOdoMeter = convert(numeric(10,2),@Uploadval)
			/*	If @Column='JCCo' and isnumeric(@Uploadval) =1 select @JCCo = convert(decimal(10,2),@Uploadval)
			If @Column='Job' select @Job = @Uploadval
			If @Column='PhaseGrp' select @PhaseGrp = @Uploadval
			If @Column='JCPhase' select @JCPhase = @Uploadval
			If @Column='JCCostType' select @JCCostType = @Uploadval
			If @Column='TaxType' select @TaxType = @Uploadval */
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
				ELSE
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
			/*136350*/		
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
					
			IF @Column='Description' -- Issue #29996    
				IF @Uploadval IS NULL
					SET @IsDescriptionEmpty = 'Y'
				ELSE
					SET @IsDescriptionEmpty = 'N'
			
			--fetch next record
			if @@fetch_status <> 0
			select @complete = 1
	   
			 select @oldrecseq = @Recseq
	   
			 fetch next from WorkEditCursor into @Recseq, @Ident, @Tablename, @Column, @Uploadval
		end 
	else
		begin
			--Get Transaction GL Co
			if @ynglco ='Y' and isnull(@Co,'') <> '' AND (ISNULL(@OverwriteGLCo, 'Y') = 'Y' OR ISNULL(@IsGLCoEmpty, 'Y') = 'Y')
			begin
				select @GLCo = GLCo	from dbo.EMCO with (nolock) 	Where EMCo = @Co

				UPDATE IMWE
				SET IMWE.UploadVal = @GLCo
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@crcsq and IMWE.Identifier = @glcoid
			end
			--Get Actual Date
			if @ynactualdate ='Y' and isnull(@Co,'') <> '' AND (ISNULL(@OverwriteActualDate, 'Y') = 'Y' OR ISNULL(@IsActualDateEmpty, 'Y') = 'Y')
			begin
				/*136350*/
				select @Identifier = DDUD.Identifier From DDUD
				inner join IMTD ON IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
				Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'ActualDate'

				UPDATE IMWE
				----#141031
				SET IMWE.UploadVal = convert(varchar(20), dbo.vfDateOnly())
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@crcsq and IMWE.Identifier = @Identifier
			end
			--Get EM Group
			if @ynemgroup ='Y' and isnull(@Co,'') <> '' AND (ISNULL(@OverwriteEMGroup, 'Y') = 'Y' OR ISNULL(@IsEMGroupEmpty, 'Y') = 'Y')
			begin
				exec @rcode = bspEMGroupGet @Co, @EMGroup output, @desc output

				select @Identifier = DDUD.Identifier from DDUD
				inner join IMTD ON IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
				Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'EMGroup'

				UPDATE IMWE
				SET IMWE.UploadVal = @EMGroup
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@crcsq and IMWE.Identifier = @Identifier
			end
			--Get Equipment Fuel Cost Code and Cost Type overrides and Dept info
			if isnull(@Co,'') <> ''
			begin
				select @FuelCostCode = FuelCostCode, @Department = Department, @FuelEMCostType = FuelCostType,@FuelMaterial = FuelMatlCode, @FuelUM = FuelCapUM
				from dbo.EMEM with (nolock) 
				Where EMCo = @Co and Equipment = @Equipment
			end
			--EM Cost Code
			if @yncostcode ='Y' and isnull(@Co,'') <> '' AND (ISNULL(@OverwriteCostCode, 'Y') = 'Y' OR ISNULL(@IsCostCodeEmpty, 'Y') = 'Y')
			begin
				select @CostCode = @FuelCostCode
				--Default EM Fuel Cost Code
				if isnull(@CostCode,'') = ''
				begin
					select @CostCode = FuelCostCode from dbo.EMCO with (nolock) Where EMCo = @Co
				end

				UPDATE IMWE
				SET IMWE.UploadVal = @CostCode
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@crcsq and IMWE.Identifier = @costcodeid
			end
			--EM Cost Type			 
			if @yncosttype ='Y' and isnull(@Co,'') <> '' AND (ISNULL(@OverwriteEMCostType, 'Y') = 'Y' OR ISNULL(@IsEMCostTypeEmpty, 'Y') = 'Y')
			begin
				select @EMCostType = @FuelEMCostType
				--Default EM Fuel Cost Type
				If isnull(@EMCostType,'') = ''
				begin
					select @EMCostType = FuelCostType 	from dbo.EMCO with (nolock)  Where EMCo = @Co
				end

				UPDATE IMWE
				SET IMWE.UploadVal = @EMCostType
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@crcsq and IMWE.Identifier = @emcosttypeid
			end
			--Get the GL Transaction Account
			if @yngltransacct ='Y' and isnull(@Co,'') <> '' AND (ISNULL(@OverwriteGLTransAcct, 'Y') = 'Y' OR ISNULL(@IsGLTransAcctEmpty, 'Y') = 'Y')
			begin
				exec @recode = bspEMCostTypeValForCostCode @Co, @EMGroup, @EMCostType, @CostCode,@Equipment, 'N', @costtypeout, 
				@GLTransAcct output,@msg output

				UPDATE IMWE
				SET IMWE.UploadVal = @GLTransAcct
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@crcsq and IMWE.Identifier = @gltransacctid
			end
			--Material Group
  			if @ynmatlgroup ='Y' and isnull(@Co,'') <> '' AND (ISNULL(@OverwriteMatlGroup, 'Y') = 'Y' OR ISNULL(@IsMatlGroupEmpty, 'Y') = 'Y') 
  			begin
  				--Default Matl Group comes from EM Company
				select @MatlGroup = MatlGroup from dbo.HQCO with (nolock) Where HQCo = @Co

				
				
				UPDATE IMWE
				SET IMWE.UploadVal = @MatlGroup
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@crcsq and IMWE.Identifier = @matlgroupid
			end
			--INCo
			if @yninco ='Y' and isnull(@Co,'') <> '' AND (ISNULL(@OverwriteINCo, 'Y') = 'Y' OR ISNULL(@IsINCoEmpty, 'Y') = 'Y')
			begin
				select @INCo = INCo from dbo.EMCO with (nolock) Where EMCo = @Co
				/*136350*/
				if @INCo is not null and isnull(@INLocation,'') <>''
				begin
					--Change Matl Group to IN Co's Material Group when IN Location has a value'
					select @MatlGroup = MatlGroup from dbo.HQCO with (nolock) Where HQCo = @INCo

					UPDATE IMWE
					SET IMWE.UploadVal = @MatlGroup
					where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@crcsq and IMWE.Identifier = @matlgroupid
				end
				UPDATE IMWE
				SET IMWE.UploadVal = @INCo
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@crcsq and IMWE.Identifier = @incoid
			end
			--Set Material to EM assigned Equipment Fule Matl
			if @ynmaterial ='Y' and isnull(@Co,'') <> '' AND (ISNULL(@OverwriteMaterial, 'Y') = 'Y' OR ISNULL(@IsMaterialEmpty, 'Y') = 'Y')
			begin
				select @Material = @FuelMaterial

				UPDATE IMWE
				SET IMWE.UploadVal = @FuelMaterial
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@crcsq and IMWE.Identifier = @materialid
			end
   			--TaxGroup
			if @yntaxgroup ='Y' and isnull(@Co,'') <> '' AND (ISNULL(@OverwriteTaxGroup, 'Y') = 'Y' OR ISNULL(@IsTaxGroupEmpty, 'Y') = 'Y')
			begin
				select @TaxGroup = TaxGroup from dbo.HQCO with (nolock) Where HQCo = @Co 

				UPDATE IMWE
				SET IMWE.UploadVal = @TaxGroup
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@crcsq and IMWE.Identifier = @taxgroupid
			end
			
			/*136360 Start*/
			--Get Offset GL Co
			if @ynoffsetglco ='Y' and isnull(@Co,'') <> '' AND (ISNULL(@OverwriteOffsetGLCo, 'Y') = 'Y' OR ISNULL(@IsOffsetGLCoEmpty, 'Y') = 'Y')
			BEGIN
			
				--Default OffSet GL Co from EM Company Parameters
				select @OffsetGLCo = GLCo	from dbo.bEMCO with (nolock) 	Where EMCo = @Co
				--Override default Offset GLCo when INCo and IN Location both have values
				--Get Offset GL Co from EM Company Parameters
				if @INCo is not null and isnull(@INLocation,'') <> '' 
				begin 
					select @OffsetGLCo = GLCo	from dbo.bINCO with (nolock) 	Where INCo = @INCo 
				end
				
				----TK-17367
				UPDATE IMWE
				SET IMWE.UploadVal = @OffsetGLCo
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@crcsq and IMWE.Identifier = @offsetglcoid
			end
			--Get Offset GLCo and GLAccount
   			if @yngloffsetacct ='Y' and isnull(@Co,'') <> '' AND (ISNULL(@OverwriteGLOffsetAcct, 'Y') = 'Y' OR ISNULL(@IsGLOffsetAcctEmpty, 'Y') = 'Y')
			begin
				SET @GLOffsetAcct = NULL
				if @INCo is not null and isnull(@INLocation,'') <> '' 
					begin
					/* Get OffsetGLAcct = EquipSalesGLAcct from INLC or INLS or INLM or EMDM. */
					select @GLOffsetAcct = EquipSalesGLAcct from dbo.INLC with (nolock)  
					where 	INCo = @INCo and Loc = @INLocation and Co = @OffsetGLCo and MatlGroup = @MatlGroup 
					and Category = (select Category from dbo.HQMT with (nolock) where MatlGroup = @MatlGroup and Material = @Material)
				
					if isnull(@GLOffsetAcct,'')=''
						begin
						select @GLOffsetAcct = EquipSalesGLAcct from dbo.INLS with (nolock) where INCo = @INCo and Loc = @INLocation  and Co = @OffsetGLCo
						end 
					if @GLOffsetAcct is null
						begin
						select @GLOffsetAcct = EquipSalesGLAcct from dbo.INLM with (nolock) where INCo = @INCo and Loc = @INLocation 
						end
					end 
				
				/* Get GLOffsetAcct from bHQMC by Category */
				If isnull(@GLOffsetAcct,'')=''
					begin					
					select @GLOffsetAcct = GLAcct
					from dbo.HQMC with (nolock)
					where MatlGroup = @MatlGroup 
						AND Category = (select Category from bHQMT where MatlGroup=@MatlGroup and Material=@Material)
					end 
				
				/* If not returned, get bEMCO.MatlMiscGLAcct. Note that Fuel Posting form will not allow bEMCO.MatlMiscGLAcct to be null. */	
				If isnull(@GLOffsetAcct,'')=''
					begin 
					select @GLOffsetAcct = MatlMiscGLAcct from dbo.EMCO with (nolock) where EMCo = @OffsetGLCo
					end

				UPDATE IMWE
				SET IMWE.UploadVal = @GLOffsetAcct
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@crcsq and IMWE.Identifier = @gloffsetacctid
			end
			/*136350 End*/
			
			if @ynum ='Y' and isnull(@Co,'') <> ''  AND (ISNULL(@OverwriteUM, 'Y') = 'Y' OR ISNULL(@IsUMEmpty, 'Y') = 'Y')
			begin
				UPDATE IMWE
				SET IMWE.UploadVal = @FuelUM
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@crcsq and IMWE.Identifier = @umid
			end

			if @ynperecm ='Y' and isnull(@Co,'') <> '' AND (ISNULL(@OverwritePerECM, 'Y') = 'Y' OR ISNULL(@IsPerECMEmpty, 'Y') = 'Y')
			begin
				select @PerECM = 'E'
				UPDATE IMWE
				SET IMWE.UploadVal = @PerECM
				where IMWE.ImportTemplate=@ImportTemplate  and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@crcsq 
				and IMWE.Identifier = @perecmid
			end
	   
			if @ynunitprice='Y' or @yntaxcode='Y' 
			begin
				exec @recode = bspEMEquipPartVal @Co, @Equipment, @MatlGroup, @INCo, @INLocation, @Material, @taxcodein, @EMEP_HQMatl output, @stdum output,
				@price output, @stocked output, @category output, @taxcodeout output, @msg output
			end 
   
			if @ynunitprice ='Y' and isnull(@Co,'') <> '' AND (ISNULL(@OverwriteUnitPrice, 'Y') = 'Y' OR ISNULL(@IsUnitPriceEmpty, 'Y') = 'Y')
			begin
				select @UnitPrice = isnull(@price,0)

				UPDATE IMWE
				SET IMWE.UploadVal = @UnitPrice
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@crcsq 
				and IMWE.Identifier = @unitpriceid
			end
	
			if @yndollars ='Y' and isnull(@Co,'') <> '' AND (ISNULL(@OverwriteDollars, 'Y') = 'Y' OR ISNULL(@IsDollarsEmpty, 'Y') = 'Y')
			begin
				select @ECMFact = 1
				if @PerECM = 'M' 
					select @ECMFact = 1000
				if @PerECM = 'C'  
					select @ECMFact = 100
					
				select @Dollars = isnull(@UnitPrice, 0) * (isnull(@Units, 0)/ @ECMFact)

				UPDATE IMWE
				SET IMWE.UploadVal = @Dollars
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@crcsq 
				and IMWE.Identifier = @dollarsid
			end
   
			if @yntaxcode ='Y' and isnull(@Co,'') <> ''  AND (ISNULL(@OverwriteTaxCode, 'Y') = 'Y' OR ISNULL(@IsTaxCodeEmpty, 'Y') = 'Y')
			begin
				UPDATE IMWE
				SET IMWE.UploadVal = @taxcodeout
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@crcsq and IMWE.Identifier = @taxcodeid
			end

			if @yntaxtype ='Y' and isnull(@Co,'') <> '' AND (ISNULL(@OverwriteTaxType, 'Y') = 'Y' OR ISNULL(@IsTaxTypeEmpty, 'Y') = 'Y')
			begin
				UPDATE IMWE
				SET IMWE.UploadVal = '1'
				where IMWE.ImportTemplate=@ImportTemplate 	and IMWE.ImportId=@ImportId  and IMWE.RecordSeq=@crcsq  and IMWE.Identifier = @taxtypeid
			end

			-- Description -- Issue #29996    
			if @DescID <> 0 AND (@OverwriteDesc = 'Y' OR @IsDescriptionEmpty = 'Y')
			begin
				set @desc = ''
				Select @desc = Description from dbo.HQMT with(nolock)	where MatlGroup = @MatlGroup and Material = @Material

				update IMWE
				set IMWE.UploadVal = @desc 
				where IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordSeq = @oldrecseq AND IMWE.Identifier = @DescID
				AND IMWE.RecordType = @rectype
		end
  
   		-- set Current Req Seq to next @Recseq   
		select @crcsq = @Recseq, @taxcodeout = null, @counter = @counter + 1
	end
end

close WorkEditCursor
deallocate WorkEditCursor
   
bspexit:
	select @msg = isnull(@desc,'Equipment Fuel') + char(13) + char(10) + '[bspBidtekDefaultEMBFFuel]'
   	return @rcode



GO
GRANT EXECUTE ON  [dbo].[bspIMBidtekDefaultsEMBFFuel] TO [public]
GO
