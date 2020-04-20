SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   FUNCTION    [dbo].[vf_rptJBGetTempSeq]

   
   (@co bCompany, @template varchar(10), @category varchar(10), @jbidsource char(2),
   	@earntype bEarnType, @liabtype bLiabilityType, @phasegrp bGroup,
   	@jcctype bJCCType, @jctranstype varchar(2))

RETURNS int
AS
BEGIN

   /***********************************************************
   * 06/06/07 - to be used on custom report JHKWeeklySell.rpt - JH 
   *
   * INPUT PARAMETERS
   * 	@co - JB Company
   *	@template - Template from contract master
   *	@category - Labor, Equipment or Material Category
   *	@jbidsource - from JCCD left(Source,2) except if JCCD Source = 'JC MatUse' then source = 'IN'
   *	@earntype - from JCCD if they are sending it from PR (based on PRCO flag) or (JC with PR JCTransType)
   *	@liabtype - from JCCD if they are sending it form PR (based on PRCO flag) or (JC with PR JCTransType)
   *	@phasegrp - from HQCO for JBCo
   *	@jcctype - from JCCD
   *	@jctranstype - from JCCD except if 'CA' then 'JC' if 'MI' then 'IN'
   *
   *****************************************************/
   

   
   declare @rcode tinyint, @levelcount int, @earnliabtypeopt char(1), @worktemplateseq int,
   	@tempcategory varchar(10), @tempearntype bEarnType, @templiabtype bLiabilityType, 
   	@apyn bYN, @emyn bYN, @msyn bYN, @inyn bYN, @pryn bYN, @jcyn bYN, 
   	@seqmatchopencursor tinyint, @seqfilterlevel tinyint, @finalfilterlevel tinyint,
   	@jbctcategory char(1), @multmsg varchar(30),@templateseq int , @seqsortlevel tinyint ,
   	@seqsummaryopt tinyint , @groupnum int , @seqtype char(1)
   
   select @rcode =0, @seqmatchopencursor = 0, @levelcount = 0, @seqfilterlevel = 0, 
   	@finalfilterlevel = 0
   
   select @templateseq = null
   
   /* Source/CostType Evaluation:
      Get a list of those sequences that match with this transaction's JCTransType and 
      CostType.  (One example is: A Source 'MS', CostType 2 may exist on multiple
      Sequences using different Material Categories).  Any sequences using other Source 
      or CostType would not be a match to this transaction. 
   
      There is no reason to worry about the Actual Source on the Transaction. (ie: JC CostAdj
      Source with a JCTransType AP).  We use the JCTransType to match up with the Sequence's
      Source chkboxes.  Older code made some attempt to evaluate JCTransTypes from JC Source
      differently but, in testing, we found that the code did nothing.  (ie: An AP JCTransType
      from JC would NOT fall into a sequence marked as JCYN = 'Y'.)*/
   declare bcSeqMatch cursor local fast_forward for
   select s.Category, s.EarnLiabTypeOpt, s.EarnType, s.LiabilityType, s.Seq, 
   	s.APYN, s.EMYN, s.INYN, s.PRYN, s.JCYN, s.MSYN, 
   	s.Type, s.GroupNum,	s.SortLevel, s.SummaryOpt, t.JBCostTypeCategory
   
   from bJBTS s with (nolock) 
   left join bJBTC c with (nolock) on c.JBCo = s.JBCo and c.Template = s.Template
   	and c.Seq = s.Seq
   join bJCCT t with (nolock) on t.PhaseGroup = c.PhaseGroup and t.CostType = c.CostType
   where s.JBCo = @co and s.Template = @template
   	and s.Type in ('S','N')
   	and c.CostType = @jcctype
   	and ((@jctranstype in ('AP','MT','SL') and s.APYN = 'Y')
   		or (@jctranstype = 'EM' and s.EMYN = 'Y')
   		or (@jctranstype = 'IN' and s.INYN = 'Y')
   		or (@jctranstype = 'PR' and s.PRYN = 'Y')
   		or (@jctranstype = 'JC' and s.JCYN = 'Y')
   		or (@jctranstype = 'MS' and s.MSYN = 'Y'))
   
   /* Open SeqMatch cursor */
   open bcSeqMatch
   select @seqmatchopencursor = 1
   
   fetch next from bcSeqMatch into @tempcategory, @earnliabtypeopt, @tempearntype, @templiabtype, @worktemplateseq,
   	@apyn, @emyn, @inyn, @pryn, @jcyn, @msyn, 
   	@seqtype, @groupnum, @seqsortlevel, @seqsummaryopt, @jbctcategory
   while @@fetch_status = 0
   	begin 	/* Begin Matching Source/CostType Seq Loop */
   
   	/* All cursor lines begin by being a good match for this transaction based upon
   	   Source and CostType.  Set the initial matching filter level value indicating
   	   this matchup.  Further evaluation may change this initial setting. */
   	select @seqfilterlevel = 1		--Matches by Source and CostType
   
    	if @tempcategory is not null
   		begin 	/* Begin Category Not NULL Loop */
   		/* Evaluate Category */
   		if @tempcategory <> @category 
   			begin
   			select @seqfilterlevel = 0		--Fails Category, does not fit in this seq
   			goto GetNext
   			end
   
   		/* We have a good match based upon Source, CostType and Category only.  If we 
   		   are dealing with Labor, need to Evaluate EarnType and LiabType. */
   		if (@jctranstype = 'PR' or @jctranstype = 'JC') and @jbctcategory in ('L', 'B')
   			begin
   			if @earnliabtypeopt is null			-- For Isolating Null Types by themselves
   				begin
   				if @earntype is null and @liabtype is null
   					begin
   					select @seqfilterlevel = 5	--Matches by Source, CostType, Category and Types
   					goto GetNext
   					end
   				else
   					begin
   					select @seqfilterlevel = 0	--Fails Types, does not fit in this seq
   					goto GetNext
   					end
   				end
   			if @earnliabtypeopt = 'A'
   				begin
   				if (@tempearntype is null)
   					or (@tempearntype is not null and @tempearntype = @earntype)
   					or (@templiabtype is null)
   					or (@templiabtype is not null and @templiabtype = @liabtype)
   					begin
   					select @seqfilterlevel = 5
   					If (@tempearntype is not null and @tempearntype = @earntype)
   						or (@templiabtype is not null and @templiabtype = @liabtype) select @seqfilterlevel = 6
   					goto GetNext
   					end
   				else
   					begin
   					select @seqfilterlevel = 0
   					goto GetNext
   					end			
   				end
   			if @earnliabtypeopt = 'B'
   				begin
   				if (@tempearntype is null and @earntype is not null)
   					or (@tempearntype is not null and @tempearntype = @earntype)
   					or (@templiabtype is null and @liabtype is not null)
   					or (@templiabtype is not null and @templiabtype = @liabtype)		
   					begin
   					select @seqfilterlevel = 5
   					If (@tempearntype is not null and @tempearntype = @earntype)
   						or (@templiabtype is not null and @templiabtype = @liabtype) select @seqfilterlevel = 6
   					goto GetNext
   					end
   				else
   					begin
   					select @seqfilterlevel = 0
   					goto GetNext
   					end	
   				end
   			if @earnliabtypeopt = 'E'
   				begin
   				if (@tempearntype is null and @earntype is not null)
   					or (@tempearntype is not null and @tempearntype = @earntype)
   					begin
   					select @seqfilterlevel = 5
   					If (@tempearntype is not null and @tempearntype = @earntype) select @seqfilterlevel = 6
   					goto GetNext
   					end
   				else
   					begin
   					select @seqfilterlevel = 0
   					goto GetNext
   					end
   				end
  
   			if @earnliabtypeopt = 'L'
   				begin
   				if (@templiabtype is null and @liabtype is not null)
   					or (@templiabtype is not null and @templiabtype = @liabtype)
   					begin
   					select @seqfilterlevel = 5
   					if (@templiabtype is not null and @templiabtype = @liabtype) select @seqfilterlevel = 6
   					goto GetNext
   					end
   				else
   					begin
   					select @seqfilterlevel = 0
   					goto GetNext
   					end
   				end
   			end	
   		else
   			begin
   			/* We have a good match based upon Source, CostType and Category only. */
   			select @seqfilterlevel = 4
   			goto GetNext
   			end
   		end		/* End Category Not NULL Loop */
   	else
   		begin	/* Begin Category NULL Loop */
   		/* We have a good Match based upon Source and CostType only. 
   		   (Allow All Categories).  If we are dealing with Labor, need
   		   to Evaluate EarnType and LiabType. */ 		
   		if (@jctranstype = 'PR' or @jctranstype = 'JC') and @jbctcategory in ('L', 'B')
   			begin	/* Begin 2nd Type Eval */
   			if @earnliabtypeopt is null			-- For Isolating Null Types by themselves
   				begin
   				if @earntype is null and @liabtype is null
   					begin
   					select @seqfilterlevel = 2	--Matches by Source, CostType and Types
   					goto GetNext
   					end
   				else
   					begin
   					select @seqfilterlevel = 0	--Fails Types, does not fit in this seq
   					goto GetNext
   					end
   				end
   			if @earnliabtypeopt = 'A'
   				begin
   				if (@tempearntype is null)
   					or (@tempearntype is not null and @tempearntype = @earntype)
   					or (@templiabtype is null)
   					or (@templiabtype is not null and @templiabtype = @liabtype)
   					begin
   					select @seqfilterlevel = 2
   					If (@tempearntype is not null and @tempearntype = @earntype)
   						or (@templiabtype is not null and @templiabtype = @liabtype) select @seqfilterlevel = 3
   					goto GetNext
   					end
   				else
   					begin
   					select @seqfilterlevel = 0
   					goto GetNext
   					end			
   				end
   			if @earnliabtypeopt = 'B'
   				begin
   				if (@tempearntype is null and @earntype is not null)
   					or (@tempearntype is not null and @tempearntype = @earntype)
   					or (@templiabtype is null and @liabtype is not null)
   					or (@templiabtype is not null and @templiabtype = @liabtype)		
   					begin
   					select @seqfilterlevel = 2
   					If (@tempearntype is not null and @tempearntype = @earntype)
   						or (@templiabtype is not null and @templiabtype = @liabtype) select @seqfilterlevel = 3
   					goto GetNext
   					end
   				else
   					begin
   					select @seqfilterlevel = 0
   					goto GetNext
   					end	
   				end
   			if @earnliabtypeopt = 'E'
   				begin
   				if (@tempearntype is null and @earntype is not null)
   					or (@tempearntype is not null and @tempearntype = @earntype)
   					begin
   					select @seqfilterlevel = 2
   					If (@tempearntype is not null and @tempearntype = @earntype) select @seqfilterlevel = 3
   					goto GetNext
   					end
   				else
   					begin
   					select @seqfilterlevel = 0
   					goto GetNext
   					end
   				end
   			if @earnliabtypeopt = 'L'
   				begin
   				if (@templiabtype is null and @liabtype is not null)
   					or (@templiabtype is not null and @templiabtype = @liabtype)
   					begin
   					select @seqfilterlevel = 2
   					if (@templiabtype is not null and @templiabtype = @liabtype) select @seqfilterlevel = 3
   					goto GetNext
   					end
   				else
   					begin
   					select @seqfilterlevel = 0
   					goto GetNext
   					end
   				end
   			end		/* End 2nd Type Eval */
   		end		/* End Category NULL Loop */
   				
   GetNext:
   	/* FinalFilterLevel begins at 0. (@templateseq is null).  As a suitable seq match is
   	   found, the level is incremented and @templateseq is set, using the related seq value.
   	   FinalFilterLevel (and thus @templateseq) can only change if a more detailed sequence
   	   is found. */
   	if @finalfilterlevel < @seqfilterlevel
   		begin
   		select @finalfilterlevel = @seqfilterlevel, @templateseq = @worktemplateseq, @levelcount = 1,
   			@multmsg = isnull(convert(varchar(9),@worktemplateseq),'') + ':'
   		end
   	else
   	/* If the sequence being evaluated either has no match or the match is a lesser match,
   	   then nothing changes.  If it is an equal match then @levelcount is incremented and
   	   is used to indicate that more than one sequence exists for a given transaction. */
   		begin
   		if @finalfilterlevel = @seqfilterlevel 
   			begin
   			select @levelcount = @levelcount + 1
   			select @multmsg = isnull(@multmsg,'') + isnull(convert(varchar(9),@worktemplateseq),'') + ':'
   			end
   		end
   		
   	fetch next from bcSeqMatch into @tempcategory, @earnliabtypeopt, @tempearntype, @templiabtype, @worktemplateseq,
   		@apyn, @emyn, @inyn, @pryn, @jcyn, @msyn, 
   		@seqtype, @groupnum, @seqsortlevel, @seqsummaryopt, @jbctcategory
   
   	end		/* End Matching Source/CostType Seq Loop */
   
   bspexit:
   /* Final Evaluation. Anything but a single unique matchup will result in an error. 
   	@finalfilterlevel = 0 (None), 1 (Source/CostType), 2 (Source/CostType, EarnLiabType ALL/NULL)
   						3 (Source/CostType, EarnLiabType Specific), 4 (Source/CostType, Category),
   						5 (Source/CostType, Category, EarnLiabType ALL/NULL) 
   						6 (Source/CostType, Category, EarnLiabType Specific) */
   if @finalfilterlevel = 0
   	begin 
   	select @templateseq=null-- @rcode = 1, @msg = 'No Template Seq for this JobCost transaction.'
   	end
   else
   	begin		
   	if @levelcount > 1
   		begin
   		select @rcode = 1, @templateseq = null
   		end
   	end
   
   /* If we have successfully determined a unique Sequence, then do one final select
      to obtain related output values relative to the sequence being returned.  It is
      easier to do this here, at the last moment, then to constantly update these values
      as we are evaluating each sequence. */
   select @seqsortlevel =SortLevel, @seqsummaryopt = SummaryOpt, @groupnum = GroupNum,
   	@seqtype = Type 	 
   from bJBTS with (nolock) 
   where JBCo = @co and Template = @template and Seq = @templateseq
   
   /* Close Out */
   if @seqmatchopencursor = 1
   	begin
   	close bcSeqMatch
   	deallocate bcSeqMatch
   	select @seqmatchopencursor = 0
   	end
   
--------------------------------------------------------------------------------------------------------------------------------------------------
   RETURN( @templateseq)

END

GO
GRANT EXECUTE ON  [dbo].[vf_rptJBGetTempSeq] TO [public]
GO
