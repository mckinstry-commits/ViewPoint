SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspGLACCopy    Script Date: 8/28/99 9:34:38 AM ******/
    CREATE                   procedure [dbo].[bspGLACCopy]
    /*******************************************************************
     * CREATED: 02/02/98 GDG
     * LAST MODIFIED: 02/25/98 GDG
     *                ALLENN - 04/26/01 Added CrossRefMemAcct column to all insert statements to bGLAC.  Added @crossrefmemacct  (issue# 11553)
     *				GG 08/07/01 - fixed cursor to include CrossRefMemAcct, convert to new format
     *				GG 11/12/01 - #14787 - don't replace spaces in source accounts, copy notes
     *             CMW 03/29/02 - fixed NULL concatenation problem - issue # 16835.
     *				allenn 07/30/02 - 17322 corrected @numbercopied 
     *				MV 01/24/03 - 19740 - removed 'Accounts Found: ' part of message
     *				MV 01/31/03 - #20246 - dbl quote cleanup.
     *				MV 02/04/03 - #20144 - insert new summaryacct for crossrefmemacct, mask check
     *				MV 02/07/03 - #19740 rej2 - added 'Accounts Found:' back to message, fixed numtocopy
     *				MV 02/13/03 - #20144 rej 1 - mask check needs to allow blanks.
     *				MV 08/20/03 - #22163 performance enhancements
     *				MV 12/03/03 = #23121 more duplicate record checks to prevent insert errors
     *
     * USAGE:  Called by GL Account Copy program to initialize new GL Accounts.
     * 	'Source' and 'To' masks assumed to be formatted as GL Accounts.
     * 	'Source' mask limited to single char pattern matching, assumes
     * 	that a '?' is used as a placeholder.  All '?' chars are converted
     * 	to '_' for SQL.
     * 	'To mask' will be applied to accounts found using 'source mask'
     * 	any character other than '?' and space will be replaced.
     * 	Skips inactive accounts, does not copy user memos columns
     *
     * INPUT PARAMS:
     *		@sourceco		Source GL Company #
     *		@sourcemask		Source GL Account mask
     *		@toco			Destination GL Company #
     *		@tomask			Destination GL Account mask
     *
     * OUTPUT PARAMS:
     *		@rcode		Return code; 0 = success, 1 = failure
     *		@errmsg		Error message; # copied if success, error message if failure
     ********************************************************************/
    	(@sourceco bCompany = 0, @sourcemask varchar(20) = null,
    	 @toco bCompany = 0,@tomask varchar(20) = null, @errmsg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @numtocopy int, @numcopied int, @opencursor tinyint,
   	@glco bCompany, @glacct bGLAcct, @summaryacct bGLAcct, @crossrefmemacct bGLAcct,
    	@masklen int, @newglacct bGLAcct, @i int, @a char(1), @newsummaryacct bGLAcct,
   	@tmpstring varchar(20), @newcrossrefmemacct bGLAcct, @crossrefsummaryacct bGLAcct,
   	@newcrossrefsummaryacct bGLAcct, @a2 char(1)
   
    /* initialize counters and flags */
    select @rcode = 0, @numtocopy = 0, @numcopied = 0,@opencursor = 0
   
    /* check for source GL company */
    if @sourceco = 0
    	begin
    	select @errmsg = 'Missing source GL company!', @rcode = 1
    	goto bspexit
    	end
    /* check for source GL Acct mask */
    if @sourcemask is null
     	begin
    	select @errmsg = 'Missing source GL Account mask!', @rcode = 1
    	goto bspexit
    	end
    /* check for destination GL company */
    if @toco = 0
     	begin
    	select @errmsg = 'Missing destination GL company!', @rcode = 1
    	goto bspexit
    	end
    /* check for destination GL Acct mask */
    if @tomask is null
    	begin
    	select @errmsg = 'Missing destination GL Account mask!', @rcode = 1
    	goto bspexit
    	end
   
    /* convert Source mask for SQL - change ? to _ */
    select @masklen = datalength(@sourcemask)
   
    select @i = 1
    	while @i <= @masklen
    		begin
    		select @a = substring(@sourcemask,@i,1)
    		if @a = '?' select @sourcemask = stuff(@sourcemask,@i,1,'_')
     		select @i=@i+1
    		end
   
   /* get number of glaccts to copy */
   select @numtocopy = (select count(*)from bGLAC WITH (NOLOCK) 
   	 where GLCo = @sourceco and Active = 'Y' and GLAcct like @sourcemask + '%')
   
   
   /* declare cursor on GL Account */
   declare bcGLAC_copy cursor LOCAL FAST_FORWARD for
   
   select GLCo, GLAcct, SummaryAcct, CrossRefMemAcct
   from bGLAC WITH (NOLOCK)
   where GLCo = @sourceco and Active = 'Y' and GLAcct like @sourcemask + '%'
   
   /* open cursor */
   open bcGLAC_copy
   select @opencursor = 1
   
   /* loop through all rows in cursor */
   copy_loop:
   	fetch next from bcGLAC_copy into @glco, @glacct, @summaryacct, @crossrefmemacct
   
    	if @@fetch_status = -1 goto bspexit
    	if @@fetch_status <> 0 goto copy_loop
   
   
    	/* accumulate number of GL Accounts to copy */
    	--select @numtocopy = @numtocopy + 1
   
   
    	/* copy new GL Account */
    	select @tmpstring = null, @i = 1
    	while @i <= @masklen
    		begin
    		select @a = substring(@tomask,@i,1)
    		if @a = '?' select @a = substring(@glacct,@i,1)
    		select @tmpstring = isnull(@tmpstring,'') + @a, @i = @i + 1
    		end
    	/* convert temp string to GL Acct */
    	select @newglacct = convert(char(20),@tmpstring)
   
   
    	/* copy new Summary GL Account */
   	if @glacct = @summaryacct
    		select @newsummaryacct = @newglacct
    	else
    		begin
   		-- #20144 check summaryacct against mask
   		select @i = 1
   		while @i <= @masklen
    			begin	
   			select @a = substring(@sourcemask,@i,1)
   			select @a2 = substring(@summaryacct,@i,1)
   			if @a <> '_' and @a2 <> @a and @a2 <> ' '
   				begin
   					select @newsummaryacct = @newglacct
   					goto NewCrossRefMemAcct
   				end
   			select @i = @i + 1
   			end
   		-- End #20144 check summaryacct against mask
   		select @tmpstring = null, @i = 1
    		while @i <= @masklen
    			begin
    			select @a = substring(@tomask,@i,1)
   			-- don't replace spaces in summary account
    			if @a = '?' or substring(@summaryacct,@i,1) = ' ' select @a = substring(@summaryacct,@i,1)
    			select @tmpstring = isnull(@tmpstring,'') + @a, @i = @i + 1
    			end
    		/* convert temp string to GL Summary Acct */
    		select @newsummaryacct = convert(char(20),@tmpstring)
    		end
   
   NewCrossRefMemAcct:
   	/* copy new Cross Reference Memo GL Account */
   	if @crossrefmemacct is null
   		select @newcrossrefmemacct = null	-- don't convert if current cross reference account is null
   	else
   		begin
   		-- #20144 check crossrefmemacct against mask
   		select @i = 1
   		while @i <= @masklen
    			begin	
   			select @a = substring(@sourcemask,@i,1)
   			select @a2 = substring(@crossrefmemacct,@i,1)
   			if @a <> '_' and @a2 <> @a and @a2 <> ' '
   				begin
   					select @newcrossrefmemacct = null
   					goto AddNewGLAccts
   				end
   			select @i = @i + 1
   			end
   		-- End #20144 check crossrefmemacct against mask
    		select @tmpstring = null, @i = 1
    		while @i <= @masklen
    			begin
    			select @a = substring(@tomask,@i,1)
   			-- don't replace spaces in cross reference account
    			if @a = '?' or substring(@crossrefmemacct,@i,1) = ' ' select @a = substring(@crossrefmemacct,@i,1)
    			select @tmpstring = isnull(@tmpstring,'') + @a, @i = @i + 1
    			end
   		/* convert temp string to GL Acct */
    		select @newcrossrefmemacct = convert(char(20),@tmpstring)
   		end
   
   AddNewGLAccts:
   /* skip if new GL Account already exists */
   if exists (select top 1 1 from bGLAC WITH (NOLOCK) where GLCo = @toco and GLAcct = @newglacct) goto copy_loop
   
    	/* if needed, add new Summary Account */
    	if @newsummaryacct is not null and @newsummaryacct <> @newglacct
    		begin
    		if not exists (select top 1 1 from bGLAC WITH (NOLOCK) where GLCo = @toco and GLAcct = @newsummaryacct)
    			begin
    			insert bGLAC (GLCo, GLAcct, Description, AcctType, SubType, NormBal, InterfaceDetail, Active,
   				SummaryAcct, CashAccrual, CashOffAcct, CrossRefMemAcct, Notes)
    			select @toco, @newsummaryacct, Description, AcctType, SubType, NormBal, InterfaceDetail, Active,
   				@newsummaryacct, CashAccrual, CashOffAcct, CrossRefMemAcct, Notes
    			from bGLAC WITH (NOLOCK) where GLCo = @glco and GLAcct = @summaryacct
   			if @@rowcount = 1 select @numcopied = @numcopied + 1
    			end
    		end
   
    	/* if needed, add new Cross Reference Account */
    	if @newcrossrefmemacct is not null and @newcrossrefmemacct <> @newglacct
   		begin
   		if not exists (select top 1 1 from bGLAC WITH (NOLOCK) where GLCo = @toco and GLAcct = @newcrossrefmemacct)
    		begin
    			-- Begin #20144 New Cross Ref Summary Acct --------------------------------------------------------------
   			select @crossrefsummaryacct = SummaryAcct from bGLAC WITH (NOLOCK)
   				where GLCo = @sourceco and GLAcct = @crossrefmemacct
   			-- check crossref's summary acct against mask
   			select @i = 1
   			while @i <= @masklen
   				begin	
   				select @a = substring(@sourcemask,@i,1)
   				select @a2 = substring(@crossrefsummaryacct,@i,1)
   				if @a <> '_' and @a2 <> @a and @a2 <> ' '
   					begin
   						select @newcrossrefsummaryacct = @newcrossrefmemacct
   					end
   				select @i = @i + 1
   				end
   			/* if needed, copy new Cross Ref's Summary GL Account and insert it */
   			if @newcrossrefsummaryacct is not null and @newcrossrefsummaryacct <> @newcrossrefmemacct
   				begin
   				select @tmpstring = null, @i = 1
   		 		while @i <= @masklen
   		 			begin
   		 			select @a = substring(@tomask,@i,1)
   					-- don't replace spaces in summary account
   		 			if @a = '?' or substring(@crossrefsummaryacct,@i,1) = ' ' select @a = substring(@crossrefsummaryacct,@i,1)
   		 			select @tmpstring = isnull(@tmpstring,'') + @a, @i = @i + 1
   		 			end
   		 		/* convert temp string to New Cross Ref Summary Acct */
   		 		select @newcrossrefsummaryacct = convert(char(20),@tmpstring)
   		 		-- if needed, add new Cross Ref's Summary Acct
   				if not exists (select top 1 1 from bGLAC WITH (NOLOCK) 
   					where GLCo = @toco and GLAcct = @newcrossrefsummaryacct) 
   					begin
   					insert bGLAC (GLCo, GLAcct, Description, AcctType, SubType, NormBal, InterfaceDetail, Active,
   						SummaryAcct, CashAccrual, CashOffAcct, CrossRefMemAcct, Notes)
   		 			select @toco, @newcrossrefsummaryacct, Description, AcctType, SubType, NormBal, InterfaceDetail, Active,
   						@newcrossrefsummaryacct, CashAccrual, CashOffAcct, null, Notes
   		 			from bGLAC WITH (NOLOCK) where GLCo = @glco and GLAcct = @crossrefsummaryacct
   					if @@rowcount = 1 select @numcopied = @numcopied + 1
   		 			end	-- End #20144 New Cross Ref Summary Acct -------------------------------------------
   				end 
   		-- Add new Cross Ref
   			if not exists (select top 1 1 from bGLAC WITH (NOLOCK) 
   				where GLCo = @toco and GLAcct = @newcrossrefmemacct) 
   				begin
   				insert bGLAC (GLCo, GLAcct, Description, AcctType, SubType, NormBal, InterfaceDetail, Active,
   				SummaryAcct, CashAccrual, CashOffAcct, CrossRefMemAcct, Notes)
   				select @toco, @newcrossrefmemacct, Description, AcctType, SubType, NormBal, InterfaceDetail, Active,
   				isnull(@newcrossrefsummaryacct,@newcrossrefmemacct), CashAccrual, CashOffAcct, CrossRefMemAcct, Notes
   				from bGLAC WITH (NOLOCK) where GLCo = @glco and GLAcct = @crossrefmemacct
   				if @@rowcount = 1 select @numcopied = @numcopied + 1
   				end
    		end
   		end
   /* insert new GL Account */
   if not exists (select top 1 1 from bGLAC WITH (NOLOCK) 
   	where GLCo = @toco and GLAcct = @newglacct) 
   	begin
   	insert bGLAC (GLCo, GLAcct, Description, AcctType, SubType, NormBal, InterfaceDetail, Active,
   		SummaryAcct, CashAccrual, CashOffAcct, CrossRefMemAcct, Notes)
   	select @toco, @newglacct, Description, AcctType, SubType, NormBal, InterfaceDetail, Active,
   		@newsummaryacct, CashAccrual, CashOffAcct, @newcrossrefmemacct, Notes
   	from bGLAC WITH (NOLOCK) where GLCo = @glco and GLAcct = @glacct
   	if @@rowcount = 1 select @numcopied = @numcopied + 1
   	end
   	goto copy_loop
   
   
    bspexit:
    	if @opencursor = 1
    		begin
    		close bcGLAC_copy
     		deallocate bcGLAC_copy
    		end
   
    	if @rcode = 0
    		begin
    		select @errmsg = 'GL Accounts found: ' + convert(varchar(6),@numtocopy)
    		select @errmsg = @errmsg + '  GL Accounts successfully copied: ' + convert(varchar(6),@numcopied)
    		end
   	if @rcode <> 0
   		begin
    		select @errmsg = @errmsg + ' Copying has been terminated. ' 
    		
    		end
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLACCopy] TO [public]
GO
