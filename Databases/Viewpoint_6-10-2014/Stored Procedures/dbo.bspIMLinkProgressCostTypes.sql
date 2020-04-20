SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspIMLinkProgressCostTypes    Script Date: 10/11/99 ******/
   CREATE             proc [dbo].[bspIMLinkProgressCostTypes]
   /***********************************************************
    * CREATED BY: DANF 09/05/02 
    *
    *
    * Usage:
    * This routine is used to create additional cost enteries for prodcution imports.
    *
    * Input params:
    *  @Company		Current Company
    *	@ImportId	   	Import Identifier
    *	@ImportTemplate	Import ImportTemplate
    *  @Form  			Imporrt Form
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
   
   
   declare @rcode int, @desc varchar(120), @ynphasegroup bYN, @ynglco bYN, @yngltransacct bYN, @ynum bYN,  @ynsource bYN, @ynToJCCo bYN,
           @CompanyID int, @defaultvalue varchar(30), @ReversalStatusID int, @TransTypeID int,  @JCTransTypeID int,
   		@RecSeq_fetchstatus int, @LinkProgress_fetchstatus int, @PhaseGroup_fetchstatus int, @PhaseGroupId int, 
           @RecSeq int, @CostTypeId int, @PhaseGroup bGroup, @AddCostType bJCCType, @Co bCompany, @Job bJob,
          @LinkProgress bJCCType, @GLTransAcct bGLAcct, @MaxRecSeq int, @UM bUM, @Phase bPhase, @UMId int, 
   		@GLTransAcctId int, @CostType bJCCType, @ctdesc varchar(20), @trackhours bYN, @costtypeout bJCCType,
   		@retainpct bDollar, @JobId int, @PhaseId int, @DefaultGLTransAcctId int, @DefaultUMId int
   
   
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
   
   select @rcode = 0
   
   select @CompanyID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Co', 'JCCB', 'N')
   select @PhaseGroupId=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PhaseGroup', 'JCCB', 'N')
   select @JobId=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Job', 'JCCB', 'N')
   select @PhaseId=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Phase', 'JCCB', 'N')
   select @CostTypeId=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CostType', 'JCCB', 'N')
   select @GLTransAcctId=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'GLTransAcct', 'JCCB', 'N')
   select @UMId=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'UM', 'JCCB', 'N')
   
   select @DefaultGLTransAcctId=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'GLTransAcct', 'JCCB', 'Y')
   select @DefaultUMId=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'UM', 'JCCB', 'Y')
   
   -- Select Phase Groups to iterate thru
   
   declare PhaseGroupCursor cursor for
   select Distinct(UploadVal) from bIMWE
   where ImportId = @ImportId and ImportTemplate = @ImportTemplate and Form = @Form and Identifier = @PhaseGroupId
   
   
   open PhaseGroupCursor
   -- set open cursor flag
   
   fetch next from PhaseGroupCursor into @PhaseGroup
   
   -- while cursor is not empty
   
   select @PhaseGroup_fetchstatus = @@fetch_status
   while @PhaseGroup_fetchstatus  = 0
   begin
   	-- Select LinkProgress Cost Types to iterate thru
   	
   	declare CostTypeCursor cursor for
   	select LinkProgress, CostType from bJCCT
   	where PhaseGroup = @PhaseGroup and LinkProgress is not null
   	
   	
   	open CostTypeCursor
   	-- set open cursor flag
   	
   	fetch next from CostTypeCursor into @LinkProgress, @AddCostType
   	
   	-- while cursor is not empty
   	
   	select @LinkProgress_fetchstatus = @@fetch_status
   	while @LinkProgress_fetchstatus  = 0
   	begin
   
   		-- Select RecordSequence to iterate thru
   		
   		declare RecSeqCursor cursor for
   		select RecordSeq from bIMWE
   		where ImportId = @ImportId and ImportTemplate = @ImportTemplate 
   		and Form = @Form and Identifier = @CostTypeId and UploadVal = @LinkProgress
   	
   		open RecSeqCursor
   		-- set open cursor flag
   		
   		fetch next from RecSeqCursor into @RecSeq
   		
   		-- while cursor is not empty
   		
   		select @RecSeq_fetchstatus = @@fetch_status
   		while @RecSeq_fetchstatus  = 0
   		begin
           	-- Copy Record Sequence
   			select @MaxRecSeq = Max(RecordSeq) from bIMWE
   			where ImportId = @ImportId and ImportTemplate = @ImportTemplate and Form = @Form
   
   			select @MaxRecSeq = @MaxRecSeq + 1
   
   			insert bIMWE ( ImportId, ImportTemplate, Form, Seq, Identifier, RecordSeq, ImportedVal, UploadVal, RecordType)
   			select ImportId, ImportTemplate, Form, Seq, Identifier, @MaxRecSeq, ImportedVal, UploadVal, RecordType
   			from bIMWE where ImportId = @ImportId and ImportTemplate = @ImportTemplate and Form = @Form and RecordSeq =@RecSeq		
   		
   		    -- Set Cost type for added record
   			Update bIMWE
   	        Set UploadVal = @AddCostType
   			from bIMWE where ImportId = @ImportId and ImportTemplate = @ImportTemplate
   			and Form = @Form and RecordSeq =@MaxRecSeq	and Identifier = @CostTypeId 	
   		   
   			--select needed data for new defaults
   
   			Select @Co = UploadVal
   			from bIMWE where ImportId = @ImportId and ImportTemplate = @ImportTemplate
   			and Form = @Form and RecordSeq =@MaxRecSeq and Identifier = @CompanyID 	
   
   			Select @Job = UploadVal
   			from bIMWE where ImportId = @ImportId and ImportTemplate = @ImportTemplate
   			and Form = @Form and RecordSeq =@MaxRecSeq and Identifier = @JobId 	
   
   			Select @PhaseGroup = UploadVal
   			from bIMWE where ImportId = @ImportId and ImportTemplate = @ImportTemplate
   			and Form = @Form and RecordSeq =@MaxRecSeq and Identifier = @PhaseGroupId
   
   			Select @Phase = UploadVal
   			from bIMWE where ImportId = @ImportId and ImportTemplate = @ImportTemplate
   			and Form = @Form and RecordSeq =@MaxRecSeq and Identifier = @PhaseId 
   	
   			Select @CostType = UploadVal
   			from bIMWE where ImportId = @ImportId and ImportTemplate = @ImportTemplate
   			and Form = @Form and RecordSeq =@MaxRecSeq and Identifier = @CostTypeId
   
   			-- Set Defaults based on new records.
   		     If @DefaultGLTransAcctId <> 0 and isnull(@Co,'') <> ''
   		 	      begin
   		            exec @rcode = bspJCCAGlacctDflt @Co, @Job, @PhaseGroup, @Phase, @CostType, 'N', @GLTransAcct output, @desc output
   		
   		            UPDATE IMWE
   			        SET IMWE.UploadVal = @GLTransAcct
   			        where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@MaxRecSeq and IMWE.Identifier = @GLTransAcctId
   		          end
   
   		     If @DefaultUMId <> 0 and isnull(@Co,'')<> '' and isnull(@Job,'')<>'' and isnull(@Phase,'')<>''
   		 	    begin
   		            exec @rcode = bspJCVCOSTTYPEWithHrs @Co, @Job, @PhaseGroup, @Phase, @CostType, 'N', @ctdesc output, @UM output, @trackhours output, @costtypeout output, @retainpct output, @desc output
   		
   		            UPDATE IMWE
   			        SET IMWE.UploadVal = @UM
   			        where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@MaxRecSeq and IMWE.Identifier = @UMId
   		        end
   		
   		fetch next from RecSeqCursor into @RecSeq
   		select @RecSeq_fetchstatus = @@fetch_status
   	
   		end
   	
   		close RecSeqCursor
   		deallocate RecSeqCursor
   
   
   	fetch next from CostTypeCursor into @LinkProgress, @AddCostType
   	select @LinkProgress_fetchstatus = @@fetch_status
   
   	end
   
   	close CostTypeCursor
   	deallocate CostTypeCursor
   
       fetch next from PhaseGroupCursor into @PhaseGroup
       select @PhaseGroup_fetchstatus = @@fetch_status
   end
   
   
   
   
   close PhaseGroupCursor
   deallocate PhaseGroupCursor
   
   
   
   bspexit:
       select @msg = isnull(@desc,'Link Cost Types') + char(13) + char(10) + '[bspIMLinkProgressCostTypes]'
   
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMLinkProgressCostTypes] TO [public]
GO
