SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspIMBidtekDefaultsJCPP    Script Date: 10/11/99 ******/
    CREATE   proc [dbo].[bspIMBidtekDefaultsJCPP]
    /***********************************************************
     * CREATED BY: Danf
     * MODIFIED BY:	GF 09/14/2010 - issue #141031 change to use vfDateOnly
     *				AMR 01/12/11 - Issue #142350, making case sensitive by removing unused vars and renaming same named variables
     *
     *
     *
     * Usage:
     *	Used by Imports to create values for needed or missing
     *      data based upon Bidtek default rules.
     *  Columns Co, PhaseGroup, UM, PRCo, ActualDate
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
    
     (@Company bCompany, @ImportId varchar(20), @ImportTemplate varchar(20), @Form varchar(20), @msg varchar(120) output)
    
    as
    
    set nocount on
    
    declare @rcode int, @desc varchar(120), @defaultvalue varchar(30) ----,@Today varchar(60)
    declare @ynCo bYN, @CoID int, @ynPhaseGroup bYN, @PhaseGroupID int, @ynUM bYN, @UMID int,
            @ynPRCo bYN, @PRCoID int,  @ynActualDate bYN, @ActualDateID int
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
    select @CoID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Co'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'
     begin
       UPDATE IMWE
       SET IMWE.UploadVal = @Company
       where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @CoID
     end
    
    select @ActualDateID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'ActualDate'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'
     begin
      UPDATE IMWE
      ----#141031
      SET IMWE.UploadVal = convert(varchar(20), dbo.vfDateOnly(),101)
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @ActualDateID
     end
    
    select @PhaseGroupID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PhaseGroup'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynPhaseGroup ='Y'
    
    select @PRCoID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PRCo'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynPRCo ='Y'
    
    select @UMID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'UM'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' select @ynUM ='Y'
    
    
     declare WorkEditCursor cursor for
     select IMWE.RecordSeq, IMWE.Identifier, DDUD.TableName, DDUD.ColumnName, IMWE.UploadVal
         from IMWE
  
         inner join DDUD on IMWE.Identifier = DDUD.Identifier and DDUD.Form = IMWE.Form
         where IMWE.ImportId = @ImportId and IMWE.ImportTemplate = @ImportTemplate and IMWE.Form = @Form
         Order by IMWE.RecordSeq, IMWE.Identifier
    
    open WorkEditCursor
    -- set open cursor flag

	--#142350 remvoing @importid   
    DECLARE @Recseq int,
			@Tablename varchar(20),
			@Column varchar(30),
			@Uploadval varchar(60),
			@Ident int
	    
    declare @currrecseq int, @allownull int, @error int, @tsql varchar(255), @valuelist varchar(255),
            @columnlist varchar(255), @complete int, @counter int, @records int, @oldrecseq int
    
    declare @JCCo bCompany, @PhaseGroup bGroup, @PRCo bGroup, @ActualDate bDate,
            @Job bJob, @Phase bPhase, @CostType bJCCType, @UM bUM, @AcutalUnits bUnits,
            @ProgressCmplt bUnits, @Crew varchar(10)
    
    
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
    
        If @Column='Co' and  isnumeric(@Uploadval) =1 select @JCCo = Convert( int, @Uploadval)
     	If @Column='Job' select @Job = @Uploadval
        If @Column='PhaseGroup' and isnumeric(@Uploadval) =1 select @PhaseGroup = Convert( int, @Uploadval)
        If @Column='Phase' select @Phase = @Uploadval
    	If @Column='CostType' and  isnumeric(@Uploadval) =1 select @CostType = convert(numeric,@Uploadval)
        If @Column='UM' select @UM = @Uploadval
        If @Column='AcutalUnits' and isnumeric(@Uploadval) =1 select @AcutalUnits = convert(decimal(10,5),@Uploadval)
    	If @Column='ProgressCmplt' and isnumeric(@Uploadval) =1 select @ProgressCmplt = convert(decimal(10,5),@Uploadval)
        If @Column='PRCo' and  isnumeric(@Uploadval) =1 select @PRCo = convert(int,@Uploadval)
        If @Column='Crew' select @Crew = @Uploadval
    	If @Column='ActualDate' and isdate(@Uploadval) =1 select @ActualDate = Convert( smalldatetime, @Uploadval)
    
               --fetch next record
    
            if @@fetch_status <> 0
              select @complete = 1
    
            select @oldrecseq = @Recseq
    
            fetch next from WorkEditCursor into @Recseq, @Ident, @Tablename, @Column, @Uploadval
    
        end
    
      else
    
        begin
    
    	if @ynPhaseGroup ='Y' -- and isnull(@JCCo,'') <> ''
     	  begin
    
          select @PhaseGroup = PhaseGroup
          from bHQCO
          where HQCo = @JCCo
    
          select @defaultvalue = @PhaseGroup
    
    
           UPDATE IMWE
           SET IMWE.UploadVal = @defaultvalue
           where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
                 and IMWE.Identifier = @PhaseGroupID
          end
    
    	if @ynPRCo ='Y'
     	  begin
    
          select @PRCo = PRCo
          from bJCCO
          where JCCo = @JCCo
    
          select @defaultvalue = @PRCo
    
    
           UPDATE IMWE
           SET IMWE.UploadVal = @defaultvalue
           where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
           and IMWE.Identifier = @PRCoID
          end
    
    	if @ynUM ='Y'
     	  begin
    
          select @UM = UM
          from bJCCH
          where JCCo = @JCCo and Job = @Job and PhaseGroup = @PhaseGroup and Phase = @Phase and CostType = @CostType
    
          select @defaultvalue = @UM
    
    
           UPDATE IMWE
           SET IMWE.UploadVal = @defaultvalue
           where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
           and IMWE.Identifier = @PRCoID
          end
    
    
                select @currrecseq = @Recseq
                select @counter = @counter + 1
    
            end
    
    end
    
    
    
    close WorkEditCursor
    deallocate WorkEditCursor
    
    bspexit:
        select @msg = isnull(@desc,'Job Progress') + char(13) + char(10) + '[bspBidtekDefaultJCPP]'
    
        return @rcode
GO
GRANT EXECUTE ON  [dbo].[bspIMBidtekDefaultsJCPP] TO [public]
GO
