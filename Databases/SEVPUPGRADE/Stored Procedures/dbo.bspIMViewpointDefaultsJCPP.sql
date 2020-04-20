SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspIMViewpointDefaultsJCPP]
   /***********************************************************
    * CREATED BY: Danf
    *  Modified: 	TRL  10/27/08 - 130765 format numeric imports according viewpoint datatypes
*	*				GF 02/09/2009 - issue #132172 name wrong for checking defaults apply for ProgressCmplt.
	*				CC	 02/18/09 - Issue #24531 - Use default only if set to overwrite or value is null
	*				GF 09/15/2010 - issue #141031 changed to use vfDateOnly
	*				AMR 01/17/11 - #142350, making case insensitive by removing unused vars and renaming same named variables
    *
    *
    * Usage:
    *	Used by Imports to create values for needed or missing
    *  data based upon Bidtek default rules. 
    *  This is designed to be used for import progress entries.
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
   
   declare @rcode int, @desc varchar(120),  @defaultvalue varchar(30),
		   @ynphasegroup bYN, @ynactualunits bYN, @ynprogresscomplt bYN, @ynum bYN,  @ynprco bYN, 
           @CompanyID int, @UMID int, @PhaseGroupID int,  @ActualDateID int, @ProgressCompltID int, @ActualUnitsID int, @PRCoID int
   
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
   -- Check ImportTemplate detail for columns to set Bidtek Defaults
   select IMTD.DefaultValue
   From IMTD with (nolock)
   Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'
   
   if @@rowcount = 0
     begin
     select @desc='No Bidtek Defaults set up for ImportTemplate ' + @ImportTemplate +'.'
     goto bspexit
     end
   
   DECLARE 
			  @OverwriteCo 	 			 bYN
			, @OverwriteActualDate 	 	 bYN
			, @OverwritePhaseGroup 	 	 bYN
			, @OverwriteUM 	 			 bYN
			, @OverwriteActualUnits 	 bYN
			, @OverwriteProgressCmplt 	 bYN
			, @OverwritePRCo 	 		 bYN			
			,	@IsCoEmpty 				 bYN
			,	@IsMthEmpty 			 bYN
			,	@IsBatchIdEmpty 		 bYN
			,	@IsBatchSeqEmpty 		 bYN
			,	@IsActualDateEmpty 		 bYN
			,	@IsJobEmpty 			 bYN
			,	@IsPhaseGroupEmpty 		 bYN
			,	@IsPhaseEmpty 			 bYN
			,	@IsCostTypeEmpty 		 bYN
			,	@IsUMEmpty 				 bYN
			,	@IsActualUnitsEmpty 	 bYN
			,	@IsProgressCmpltEmpty 	 bYN
			,	@IsPRCoEmpty 			 bYN
			,	@IsCrewEmpty 			 bYN


	SELECT @OverwriteCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Co', @rectype);
	SELECT @OverwriteActualDate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ActualDate', @rectype);
	SELECT @OverwritePhaseGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PhaseGroup', @rectype);
	SELECT @OverwriteUM = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'UM', @rectype);
	SELECT @OverwriteActualUnits = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ActualUnits', @rectype);
	SELECT @OverwriteProgressCmplt = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ProgressCmplt', @rectype);
	SELECT @OverwritePRCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PRCo', @rectype);
	   
   select @CompanyID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Co'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCo, 'Y') = 'Y') 
    begin
      UPDATE IMWE
      SET IMWE.UploadVal = @Company
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @CompanyID
    end
   
   select @ActualDateID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'ActualDate'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteActualDate, 'Y') = 'Y') 
    begin
      UPDATE IMWE
      ----#141031
      SET IMWE.UploadVal = convert(varchar(10), dbo.vfDateOnly(),101)
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @ActualDateID
    end
    
    ----------------------
    
       select @CompanyID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Co'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCo, 'Y') = 'N') 
    begin
      UPDATE IMWE
      SET IMWE.UploadVal = @Company
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @CompanyID
      AND IMWE.UploadVal IS NULL
    end
   
   select @ActualDateID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'ActualDate'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteActualDate, 'Y') = 'N') 
    begin
      UPDATE IMWE
      ----#141031
      SET IMWE.UploadVal = convert(varchar(10), dbo.vfDateOnly(),101)
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @ActualDateID
      AND IMWE.UploadVal IS NULL
    end


   select @ynphasegroup = 'N'
   select @PhaseGroupID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PhaseGroup', @rectype, 'Y')
   if @PhaseGroupID <> 0 select @ynphasegroup = 'Y'

   select @ynum = 'N'
   select @UMID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'UM', @rectype, 'Y')
   if @UMID <> 0 select @ynum = 'Y'

   select @ynactualunits = 'N'
   select @ActualUnitsID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ActualUnits', @rectype, 'Y')
   if @ActualUnitsID <> 0 select @ynactualunits = 'Y'

----#132172
   select @ynprogresscomplt  = 'N'
   select @ProgressCompltID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ProgressCmplt', @rectype, 'Y')
   if @ProgressCompltID <> 0 select @ynprogresscomplt  = 'Y'

   select @ynprco  = 'N'
   select @PRCoID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PRCo', @rectype, 'Y')
   if @PRCoID <> 0 select @ynprco  = 'Y'

   declare WorkEditCursor cursor local fast_forward for
   select IMWE.RecordSeq, IMWE.Identifier, DDUD.TableName, DDUD.ColumnName, IMWE.UploadVal
       from IMWE
           inner join DDUD on IMWE.Identifier = DDUD.Identifier and DDUD.Form = IMWE.Form
       where IMWE.ImportId = @ImportId and IMWE.ImportTemplate = @ImportTemplate and IMWE.Form = @Form
       Order by IMWE.RecordSeq, IMWE.Identifier
   
   open WorkEditCursor
	-- set open cursor flag
	-- #142350 - removing the following fields @importid varchar(10), @seq int, @Identifier int
   DECLARE	@Recseq int,
			@Tablename varchar(20),
			@Column varchar(30),
			@Uploadval varchar(60),
			@Ident int
           
   
   declare @currrecseq int, @allownull int, @error int, @tsql varchar(255), @valuelist varchar(255),
           @columnlist varchar(255), @complete int, @counter int, @records int, @oldrecseq int
   
   declare @Co bCompany, @Mth bMonth, @BatchId bBatchID, @BatchSeq int,
   	@Job bJob, @PhaseGroup bGroup, @Phase bPhase, @CostType bJCCType, @ActualDate bDate,
   	@UM bUM, @ActualUnits bUnits, @PRCo bCompany,
   	@Crew varchar(10), @ProgressComplt bUnitCost, 
	@CurrentEstimatedUnits bUnits, @CurrentEstimatedDollars bDollar,
	@CurrentProjectedUnits bUnits, @CurrentCompletedUnits bUnits,
	@Total bUnits, @Estimate bUnits, @Projected bUnits,
	@TotalCompletedUnits bUnits, @Actual bUnits,
	@Plugged bYN
   
   declare @ctdesc varchar(60),@trackhours bYN, @costtypeout bJCCType, @retainpct bPct
   
   
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
   
    If @Column='Co' and  isnumeric(@Uploadval) =1 select @Co = Convert( int, @Uploadval)
   	If @Column='Mth' and isdate(@Uploadval) =1 select @Mth = Convert( smalldatetime, @Uploadval)
	--If @Column='BatchSeq' and  isnumeric(@Uploadval) =1 select @BatchSeq = @Uploadval
   	If @Column='Job' select @Job = @Uploadval
   	If @Column='PhaseGroup' and isnumeric(@Uploadval) = 1 select @PhaseGroup = @Uploadval
   	If @Column='Phase' select @Phase = @Uploadval
   	If @Column='CostType' and isnumeric(@Uploadval) = 1 select @CostType = @Uploadval
	If @Column='AcutalDate' and isdate(@Uploadval) =1 select @ActualDate = Convert( smalldatetime, @Uploadval)
   	If @Column='UM' select @UM = @Uploadval
	--Issue 130765
  	If @Column='ActualUnits' and isnumeric(@Uploadval) =1 select @ActualUnits = convert(numeric(12,3),@Uploadval)
	----#132172
	If @Column='ProgressCmplt' and isnumeric(@Uploadval) =1 select @ProgressComplt  = convert(numeric(12,3),@Uploadval)
   	If @Column='PRCo' and isnumeric(@Uploadval) =1 select @PRCo = @Uploadval
   	If @Column='Crew' select @Crew = @Uploadval

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
		IF @Column='ActualDate' 
			IF @Uploadval IS NULL
				SET @IsActualDateEmpty = 'Y'
			ELSE
				SET @IsActualDateEmpty = 'N'
		IF @Column='Job' 
			IF @Uploadval IS NULL
				SET @IsJobEmpty = 'Y'
			ELSE
				SET @IsJobEmpty = 'N'
		IF @Column='PhaseGroup' 
			IF @Uploadval IS NULL
				SET @IsPhaseGroupEmpty = 'Y'
			ELSE
				SET @IsPhaseGroupEmpty = 'N'
		IF @Column='Phase' 
			IF @Uploadval IS NULL
				SET @IsPhaseEmpty = 'Y'
			ELSE
				SET @IsPhaseEmpty = 'N'
		IF @Column='CostType' 
			IF @Uploadval IS NULL
				SET @IsCostTypeEmpty = 'Y'
			ELSE
				SET @IsCostTypeEmpty = 'N'
		IF @Column='UM' 
			IF @Uploadval IS NULL
				SET @IsUMEmpty = 'Y'
			ELSE
				SET @IsUMEmpty = 'N'
		IF @Column='ActualUnits' 
			IF @Uploadval IS NULL
				SET @IsActualUnitsEmpty = 'Y'
			ELSE
				SET @IsActualUnitsEmpty = 'N'
		IF @Column='ProgressCmplt' 
			IF @Uploadval IS NULL
				SET @IsProgressCmpltEmpty = 'Y'
			ELSE
				SET @IsProgressCmpltEmpty = 'N'
		IF @Column='PRCo' 
			IF @Uploadval IS NULL
				SET @IsPRCoEmpty = 'Y'
			ELSE
				SET @IsPRCoEmpty = 'N'
		IF @Column='Crew' 
			IF @Uploadval IS NULL
				SET @IsCrewEmpty = 'Y'
			ELSE
				SET @IsCrewEmpty = 'N'
   
   
              --fetch next record
   
           if @@fetch_status <> 0
             select @complete = 1
   
           select @oldrecseq = @Recseq
   
           fetch next from WorkEditCursor into @Recseq, @Ident, @Tablename, @Column, @Uploadval
   
       end
   
     else
   
       begin

		IF @Co is not null and @Co <> ''and @Job is not null and @Job <> '' and @Phase is not null and @Phase <> '' and @CostType is not null and @CostType <> ''
			begin

				--Current Estimated 
				--Units
				select @CurrentEstimatedUnits = isnull(sum(EstUnits),0) 
				from JCCD JCCD with (nolock) 
				join JCCH JCCH with (nolock) 
					on JCCH.JCCo=JCCD.JCCo and JCCH.Job=JCCD.Job and 
					  JCCH.PhaseGroup=JCCD.PhaseGroup and JCCH.Phase=JCCD.Phase and JCCH.CostType=JCCD.CostType
				where @Co=JCCD.JCCo and @Job=JCCD.Job and 
					  @PhaseGroup=JCCD.PhaseGroup and @Phase=JCCD.Phase and @CostType=JCCD.CostType and JCCH.UM=JCCD.UM

				--Dollars
				select @CurrentEstimatedDollars = isnull(sum(EstCost),0) 
				from JCCD JCCD with (nolock) 
				where @Co=JCCD.JCCo and @Job=JCCD.Job and 
					  @PhaseGroup=JCCD.PhaseGroup and @Phase=JCCD.Phase and @CostType=JCCD.CostType

				-- Current Projected 
				-- Units
				select @CurrentProjectedUnits = isnull(sum(ProjUnits),0) 
				from JCCD JCCD with (nolock) 
				join JCCH JCCH with (nolock) 
					on JCCH.JCCo=JCCD.JCCo and JCCH.Job=JCCD.Job and 
					  JCCH.PhaseGroup=JCCD.PhaseGroup and JCCH.Phase=JCCD.Phase and JCCH.CostType=JCCD.CostType
				where @Co=JCCD.JCCo and @Job=JCCD.Job and @PhaseGroup=JCCD.PhaseGroup 
				and @Phase=JCCD.Phase and @CostType=JCCD.CostType and JCCH.UM = JCCD.UM

				-- Current Completed Units
				select @CurrentCompletedUnits = isnull(sum(ActualUnits),0) 
				from JCCD JCCD with (nolock)
				join JCCH JCCH with (nolock) 
					on JCCH.JCCo=JCCD.JCCo and JCCH.Job=JCCD.Job and 
					  JCCH.PhaseGroup=JCCD.PhaseGroup and JCCH.Phase=JCCD.Phase and JCCH.CostType=JCCD.CostType 
				where @Co=JCCD.JCCo and @Job=JCCD.Job and @PhaseGroup=JCCD.PhaseGroup and @Phase=JCCD.Phase and @CostType=JCCD.CostType and JCCH.UM = JCCD.UM
				
				--Plugged
				select @Plugged = Plugged
				from JCCH JCCH with (nolock) 
				where @Co=JCCH.JCCo and @Job=JCCH.Job and 
					  @PhaseGroup=JCCH.PhaseGroup and @Phase=JCCH.Phase and @CostType=JCCH.CostType


				--Total Complete
				--ActualUnits + (select isnull(sum(ActualUnits),0) from JCCD JCCD with (nolock) where JCPP.Co=JCCD.JCCo and JCPP.Job=JCCD.Job and JCPP.PhaseGroup=JCCD.PhaseGroup and JCPP.Phase=JCCD.Phase and JCPP.CostType=JCCD.CostType and JCCH.UM = JCCD.UM )
			end
			else
			begin
				select @Plugged = 'N', @CurrentEstimatedDollars = 0, @CurrentEstimatedUnits = 0
			end
/*
			   -- Calculate Percent Complete
               Case myfields.NewlyCompletedUnits
                    If e.ValueChanged = True Then
                        Total = CurrentCompletedUnits + NewlyCompletedUnits
                        TotalCompletedUnits=Total
                        Projected = CurrentProjectedUnits
                        Estimate = CurrentEstimatedUnits
                        If Plugged = "Y" Then
                            If Projected = 0 Then
                                TotalPercent=0
                            ElseIf (Total / Projected) <= 99.9999 Then
                                TotalPercent=(Total / Projected)
                            Else
                                TotalPercent=99.9999
                            End If
                        Else
                            If Estimate = 0 Then
                                TotalPercent=0
                            ElseIf (Total / Estimate) <= 99.9999 Then
                                TotalPercent=Math.Abs(Total / Estimate)
                            Else
                                TotalPercent=99.9999
                            End If
                        End If
                    End If

                Case myfields.TotalCompletedUnits
                    If e.ValueChanged = True Then
                        Total= TotalCompletedUnits
                        Actual = CurrentCompletedUnits

                        NewlyCompletedUnits = Total - Actual

                        Projected = CurrentProjectedUnits
                        Estimate = CurrentEstimatedUnits

                        If Plugged = "Y" Then
                            If Projected = 0 Then
                                TotalPercent = 0
                            ElseIf (Total / Projected) <= 99.9999 Then
                                TotalPercent=Total / Projected
                            Else
                                TotalPercent=99.9999
                            End If
                        Else
            If Estimate = 0 Then
                                TotalPercent=0
                            ElseIf (Total / Estimate) <= 99.9999 Then
                                TotalPercent=Total / Estimate
                            Else
                                TotalPercent=99.9999
                            End If
                        End If
                    End If

				-- Calculate Newly Completed Units
                Case myfields.TotalPercent
                    If e.ValueChanged = True Then
                        PercentComplete = TotalPercent

                        If PercentComplete <> 0 Then
                            If Plugged = "Y" Then
                                Projected = CurrentProjectedUnits
                                TotalCompletedUnits=Projected * PercentComplete
                            Else
                                Estimate = CurrentEstimatedUnits
                                TotalCompletedUnits=Estimate * PercentComplete
                            End If

                        Else
                            TotalCompletedUnits=0
                        End If
                        Actual = CurrentCompletedUnits
                        Total = TotalCompletedUnits
                        NewlyCompletedUnits=Total - Actual
                    End If

*/

       If @ynphasegroup ='Y' and @Co is not null and @Co <> '' AND (ISNULL(@OverwritePhaseGroup, 'Y') = 'Y' OR ISNULL(@IsPhaseGroupEmpty, 'Y') = 'Y')
    	     begin
				exec @rcode = bspJCPhaseGrpGet @Co, @PhaseGroup output, @desc output
   
				UPDATE IMWE
   				SET IMWE.UploadVal = @PhaseGroup
   				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @PhaseGroupID
           end

        If @ynum ='Y' and @Co is not null and @Co <> ''and @Job is not null and @Job <> '' and @Phase is not null and @Phase <> '' AND (ISNULL(@OverwriteUM, 'Y') = 'Y' OR ISNULL(@IsUMEmpty, 'Y') = 'Y')
    	    begin
               exec @rcode = bspJCVCOSTTYPEWithHrs @Co, @Job, @PhaseGroup, @Phase, @CostType, 'N', @ctdesc output, @UM output, @trackhours output, @costtypeout output, @retainpct output, @desc output
     
				UPDATE IMWE
   				SET IMWE.UploadVal = @UM
   				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @UMID
           end
   
          If @ynprco ='Y' and @Co is not null and @Co <> '' AND (ISNULL(@OverwritePRCo, 'Y') = 'Y' OR ISNULL(@IsPRCoEmpty, 'Y') = 'Y')
    	     begin
				select @PRCo = PRCo 
				from JCCO with (nolock)
				where JCCo = @Co

				UPDATE IMWE
   				SET IMWE.UploadVal = @PRCo
   				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @PRCoID
           end

	select @ynactualunits, @ynprogresscomplt

       If @ynactualunits ='Y'  AND (ISNULL(@OverwriteActualUnits, 'Y') = 'Y' OR ISNULL(@IsActualUnitsEmpty, 'Y') = 'Y')
    	     begin
						select @ProgressComplt = isnull(@ProgressComplt,0)

                        If isnull(@ProgressComplt,0) <> 0 
							begin
                            If @Plugged = 'Y' 
								begin
                                select @Projected = isnull(@CurrentProjectedUnits,0)
                                select @TotalCompletedUnits=@Projected * @ProgressComplt
								end
                            Else
								begin
                                select @Estimate = isnull(@CurrentEstimatedUnits,0)
                                select @TotalCompletedUnits=@Estimate * @ProgressComplt
								end
							end
                        Else
							begin
                            select @TotalCompletedUnits=0
							end

                        select @Actual = isnull(@CurrentCompletedUnits,0)
                        select @Total = isnull(@TotalCompletedUnits,0)
                        select @ActualUnits=@Total - @Actual

				UPDATE IMWE
   				SET IMWE.UploadVal = @ActualUnits
   				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @ActualUnitsID
           end

        If @ynprogresscomplt ='Y'  AND (ISNULL(@OverwriteProgressCmplt, 'Y') = 'Y' OR ISNULL(@IsProgressCmpltEmpty, 'Y') = 'Y')
    	    begin

                        select @Total = isnull(@CurrentCompletedUnits,0) + isnull(@ActualUnits,0)
                        select @Projected = isnull(@CurrentProjectedUnits,0)
                        select @Estimate = isnull(@CurrentEstimatedUnits,0)
                        If @Plugged = 'Y' 
							begin
                            If @Projected = 0 
                                select @ProgressComplt=0
                            Else
								begin
								If (@Total / @Projected) <= 99.9999 
									select @ProgressComplt=(@Total / @Projected)
								Else
									select @ProgressComplt=99.9999
								end
							end
                        Else
							begin
                            If @Estimate = 0 
								select @ProgressComplt=0
                            Else
								begin
								If (@Total / @Estimate) <= 99.9999 
									select @ProgressComplt=(@Total / @Estimate)
								Else
									select @ProgressComplt=99.9999
								end
							end

				UPDATE IMWE
   				SET IMWE.UploadVal = @ProgressComplt
   				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @ProgressCompltID
           end

               select @currrecseq = @Recseq
               select @counter = @counter + 1
   
           end
   
   end
   

   UPDATE IMWE
   SET IMWE.UploadVal = 0
   where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.UploadVal is null and
   (IMWE.Identifier = 91 or IMWE.Identifier = 93 )
   
   
   close WorkEditCursor
   deallocate WorkEditCursor
   
   bspexit:
       select @msg = isnull(@desc,'Job Cost Progress') + char(13) + char(10) + '[bspViewpointDefaultJCPP]'
   
       return @rcode



GO
GRANT EXECUTE ON  [dbo].[bspIMViewpointDefaultsJCPP] TO [public]
GO
