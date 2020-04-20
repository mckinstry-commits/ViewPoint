SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE        proc [dbo].[bspIMViewpointDefaultsEMBFTimecard]
   /***********************************************************
    * CREATED BY: Danf
    * MODIFIED BY: GF 09/11/2010 - issue #141031 change to use function vfDateOnly
    *				AMR 01/12/11 - #142350, making case sensitive by removing unused vars and renaming same named variables
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
           @ynactualdate bYN, @ynemgroup bYN, @yncostcode bYN, @yncosttype bYN, @ynmatlgroup bYN, @yninco bYN,
           @ynglco bYN, @yntaxgroup bYN, @yngltransacct bYN, @yngloffsetacct bYN, @ynfasbooknumberone bYN,
           @fasbooknumberid int, @dollarid int, @equipid int, @CompanyID int, @defaultvalue varchar(30),
		   @UMID int, @SourceID int, @perecmID bYN, @ynequipment bYN, @ynwoitem bYN, @ynum bYN, @ynunitprice bYN, @yndollars bYN
   
   select @ynactualdate ='N', @ynemgroup ='N', @yncostcode ='N', @yncosttype ='N', 
          @ynglco ='N',  @yngltransacct ='N', @yngloffsetacct ='N', 
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
   select IMTD.DefaultValue
   From IMTD
   Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'
   if @@rowcount = 0
     begin
     select @desc='No Bidtek Defaults set up for ImportTemplate ' + @ImportTemplate +'.', @rcode=1
     goto bspexit
     end
   
   select @CompanyID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Co'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'
    begin
      UPDATE IMWE
      SET IMWE.UploadVal = @Company
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @CompanyID
    end

   select @SourceID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Source'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'
    begin
      UPDATE IMWE
      SET IMWE.UploadVal = 'EMTime'
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @SourceID
    end
   
   select @UMID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'UM'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'
    begin
      UPDATE IMWE
      SET IMWE.UploadVal = 'LS'
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @UMID
    end

    select @perecmID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PerECM'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'
    begin
      UPDATE IMWE
      SET IMWE.UploadVal = 'E'
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @perecmID
    end

    select @perecmID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'EMTransType'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'
    begin
      UPDATE IMWE
      SET IMWE.UploadVal = 'E'
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @perecmID
    end

   select IMTD.DefaultValue, DDUD.ColumnName, DDUD.Identifier
   From IMTD
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'EMTransType'
   if @@rowcount <> 0 select @ynactualdate ='Y'

   select IMTD.DefaultValue, DDUD.ColumnName, DDUD.Identifier
   From IMTD
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'ActualDate'
   if @@rowcount <> 0 select @ynactualdate ='Y'
   
   select IMTD.DefaultValue, DDUD.ColumnName, DDUD.Identifier
   From IMTD
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'EMGroup'
   if @@rowcount <> 0 select @ynemgroup ='Y'
   
   select IMTD.DefaultValue, DDUD.ColumnName, DDUD.Identifier
   From IMTD
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'Equipment'
   if @@rowcount <> 0 select @ynequipment ='Y'

   select IMTD.DefaultValue, DDUD.ColumnName, DDUD.Identifier
   From IMTD
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'CostCode'
   if @@rowcount <> 0 select @yncostcode ='Y'

   select IMTD.DefaultValue, DDUD.ColumnName, DDUD.Identifier
   From IMTD
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'EMCostType'
   if @@rowcount <> 0 select @yncosttype ='Y'
   
   select IMTD.DefaultValue, DDUD.ColumnName, DDUD.Identifier
   From IMTD
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'WOItem'
   if @@rowcount <> 0 select @ynwoitem ='Y'

   select IMTD.DefaultValue, DDUD.ColumnName, DDUD.Identifier
   From IMTD
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'UM'
   if @@rowcount <> 0 select @ynum ='Y'
      
   select IMTD.DefaultValue, DDUD.ColumnName, DDUD.Identifier
   From IMTD
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'UnitPrice'
   if @@rowcount <> 0 select @ynunitprice ='Y'

   select IMTD.DefaultValue, DDUD.ColumnName, DDUD.Identifier
   From IMTD
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'Dollars'
   if @@rowcount <> 0 select @yndollars ='Y'

   select IMTD.DefaultValue, DDUD.ColumnName, DDUD.Identifier
   From IMTD
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'GLCo'
   if @@rowcount <> 0 select @ynglco ='Y'
   
    select IMTD.DefaultValue, DDUD.ColumnName, DDUD.Identifier
   From IMTD
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'GLOffsetAcct'
   if @@rowcount <> 0 select @yngloffsetacct  ='Y'
   
   select IMTD.DefaultValue, DDUD.ColumnName, DDUD.Identifier
   From IMTD
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'GLTransAcct'
   if @@rowcount <> 0 select @yngltransacct  ='Y'
   
   
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
  --#142350 removing  @importid varchar(10), @seq int
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
   while @complete = 0
   
   begin
   
     if @@fetch_status <> 0
       select @Recseq = -1
   
       --if rec sequence = current rec sequence flag
     if @Recseq = @currrecseq
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
   	If @Column='APRef' select @APRef = @Uploadval*/
   	If @Column='WorkOrder' select @WorkOrder = @Uploadval
   	If @Column='WOItem' select @WOItem = @Uploadval 
    /*If @Column='MatlGroup' and isnumeric(@Uploadval) =1 select @MatlGroup = Convert( int, @Uploadval)
   	If @Column='INCo' and isnumeric(@Uploadval) =1 select @INCo = Convert( int, @Uploadval)
   	If @Column='INLocation' select @INLocation = @Uploadval
   	If @Column='Material' select @Material = @Uploadval
    If @Column='SerialNo' select @SerialNo = @Uploadval*/ 
   	If @Column='UM' select @UM = @Uploadval
   	If @Column='Units' select @Units = @Uploadval
   	If @Column='Dollars' and isnumeric(@Uploadval) =1 select @Dollars = convert(numeric,@Uploadval)
   	If @Column='UnitPrice' and isnumeric(@Uploadval) =1 select @UnitPrice = convert(numeric,@Uploadval)
   	If @Column='Hours' and isnumeric(@Uploadval) =1 select @Hours = convert(decimal(10,3),@Uploadval)
   	If @Column='PerECM' and isnumeric(@Uploadval) =1 select @PerECM = convert(decimal(10,5),@Uploadval)
   	/*If @Column='JCCo' and isnumeric(@Uploadval) =1 select @JCCo = convert(decimal(10,2),@Uploadval)
    If @Column='Job' select @Job = @Uploadval
   	If @Column='PhaseGrp' select @PhaseGrp = @Uploadval
   	If @Column='JCPhase' select @JCPhase = @Uploadval
   	If @Column='JCCostType' select @JCCostType = @Uploadval
   	If @Column='TaxType' select @TaxType = @Uploadval 
   	If @Column='TaxGroup' and isnumeric(@Uploadval) =1 select @TaxGroup = Convert( int, @Uploadval)
   	If @Column='TaxBasis' select @TaxBasis = @Uploadval
   	If @Column='TaxRate' and isnumeric(@Uploadval) =1 select @TaxRate = convert(numeric,@Uploadval)
   	If @Column='TaxAmount' and isnumeric(@Uploadval) =1 select @TaxAmount = convert(numeric,@Uploadval)*/
   
   
              --fetch next record
   
           if @@fetch_status <> 0
             select @complete = 1
   
           select @oldrecseq = @Recseq
   
           fetch next from WorkEditCursor into @Recseq, @Ident, @Tablename, @Column, @Uploadval
   
       end
   
     else
   
       begin
   
        if @ynglco ='Y' and @Co is not null and @Co <> ''
    	  begin
          select @GLCo = GLCo
          from bEMCO
          Where EMCo = @Co
   
          select @Identifier = DDUD.Identifier
     	   From DDUD
     	   inner join IMTD ON IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
          Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]' AND DDUD.ColumnName = 'GLCo'
   
          UPDATE IMWE
          SET IMWE.UploadVal = @GLCo
          where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @Identifier
         end
   
   
   	if @ynactualdate ='Y' and @Co is not null and @Co <> ''
    	  begin
          select @Identifier = DDUD.Identifier
   
     	   From DDUD
     	   inner join IMTD ON IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
          Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'ActualDate'
   
          UPDATE IMWE
          ----#141031
          SET IMWE.UploadVal = convert(varchar(20), dbo.vfDateOnly(),101)
          where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @Identifier
         end
   
   	if @ynemgroup ='Y' and @Co is not null and @Co <> ''
    	  begin
          exec @rcode = bspEMGroupGet @Co, @EMGroup output, @desc output
   
          select @Identifier = DDUD.Identifier
     	   From DDUD
     	   inner join IMTD ON IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
          Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'EMGroup'
   
          UPDATE IMWE
          SET IMWE.UploadVal = @EMGroup
          where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @Identifier
         end
   
   	if @yncostcode ='Y' and @Co is not null and @Co <> ''
    	  begin
          select @CostCode = DeprCostCode
          from bEMCO
       Where EMCo = @Co
   
          select @Identifier = DDUD.Identifier
     	   From DDUD
     	   inner join IMTD ON IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
          Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'CostCode'
   
          UPDATE IMWE
          SET IMWE.UploadVal = @CostCode
          where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @Identifier
         end
   
   	if @yncosttype ='Y' and @Co is not null and @Co <> ''
    	  begin
          select @EMCostType = LaborCT
          from bEMCO
          Where EMCo = @Co

          select @Identifier = DDUD.Identifier
     	   From DDUD
     	   inner join IMTD ON IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
          Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'EMCostType'
   
          UPDATE IMWE
          SET IMWE.UploadVal = @EMCostType
          where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @Identifier
         end
   
    
        if @yngltransacct ='Y' and @Co is not null and @Co <> ''
    	  begin
          select @EMGLTransAcct = null
   
          exec @recode = bspEMCostTypeValForCostCode @Co, @EMGroup, @EMCostType, @CostCode,
                                        @Equipment, 'N', @costtypeout, @EMGLTransAcct output,
                                        @msg output
   
          select @Identifier = DDUD.Identifier
     	   From DDUD
     	   inner join IMTD ON IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
          Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]' AND DDUD.ColumnName = 'GLTransAcct'
   
          UPDATE IMWE
          SET IMWE.UploadVal = @EMGLTransAcct
          where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @Identifier
   
         end
   
        if @yngloffsetacct ='Y' and @Co is not null and @Co <> ''
    	  begin
              select @Department = Department
              from bEMEM
              Where EMCo = @Co and Equipment = @Equipment
   
              select @GLOffsetAcct = DepreciationAcct
              from bEMDM
              where EMCo = @Co and Department = @Department
   
          select @Identifier = DDUD.Identifier
     	   From DDUD
     	   inner join IMTD ON IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
          Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'GLOffsetAcct'
   
          UPDATE IMWE
          SET IMWE.UploadVal = @GLOffsetAcct
          where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @Identifier
         end
   
              select @currrecseq = @Recseq
               select @counter = @counter + 1
   
           end
   
   end
   
   
   
   close WorkEditCursor
   deallocate WorkEditCursor
   
   bspexit:
       select @msg = isnull(@desc,'Equipment') + char(13) + char(10) + '[bspViewpointDefaultEMBFTimecard]'
   
       return @rcode
GO
GRANT EXECUTE ON  [dbo].[bspIMViewpointDefaultsEMBFTimecard] TO [public]
GO
