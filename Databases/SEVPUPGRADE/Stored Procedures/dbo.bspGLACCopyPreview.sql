SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspGLACCopyPreview    Script Date: 8/28/99 9:34:39 AM ******/
   
   CREATE     procedure [dbo].[bspGLACCopyPreview]
   /*******************************************************************
    * Used by GL Account Copier to preview new GL Accounts
    *
    *	Last Modified:	MV 01/24/03 - #16835 - CW made a fix to bspGLACCopy
    *						should have made the same fix here.
    *					MV 01/31/03 - #20246 - dbl quote cleanup. 
    * pass in Source Co#, Source Mask, To Co#, length of minor portion 
    * of mask, and To Mask
    *
    * 'Source' and 'To' masks assumed to be formatted as GL Accounts.
    *
    * 'Source' mask limited to single char pattern matching, assumes
    * that a '?' is used as a placeholder.  All '?' chars are converted
    * to '_' for SQL.
    *
    * 'To mask' will be applied to accounts found using 'source mask'
    * any character other than '?' will be replaced.
    *
    * Skips inactive accounts.
    *  
    * returns 0 and recordsetr of Accounts
    * Returns 1 and error message if unable to process.
    ********************************************************************/
   
   	(@sourceco bCompany = 0, @sourcemask varchar(20) = null,
   	 @toco bCompany = 0,	@tomask varchar(20) = null, @errmsg varchar(255) output)
   --	 @minorlen tinyint = 0, @errmsg varchar(255) output)
   as
   set nocount on
   declare @rcode int, @opencursor tinyint, @glco bCompany, @glacct bGLAcct, @description bDesc,
   	@masklen int, @newglacct bGLAcct, @i int, @a char(1), @b char(1), @tmpstring varchar(20)
   
   /* initialize counters and flags */
   select @rcode = 0, @opencursor = 0
   
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
   
   create table #GLAcctPreview (SourceAcct varchar(20) NOT NULL, DestAcct varchar(20) NOT NULL, Description varchar(30) NULL)
   
   /* declare cursor on GL Accounts */
   declare bcSourceAcct cursor for select GLAcct, Description
   	from bGLAC where GLCo = @sourceco and Active = 'Y' and GLAcct like @sourcemask --+ '%' 
   	order by GLAcct
   
   open bcSourceAcct
   select @opencursor = 1
   
   /* loop through all rows in cursor */
   next_SourceAcct:
   	fetch next from bcSourceAcct into @glacct, @description
   
   	if @@fetch_status = -1 goto bspexit
   	if @@fetch_status <> 0 goto next_SourceAcct
   	
   	
   	/* convert  GL Account */
   	select @tmpstring = null, @i = 1
   	while @i <= @masklen
   
   		begin
   		select @a = substring(@tomask,@i,1)
   		if @a = '?' select @a = substring(@glacct,@i,1)
   		select @tmpstring = isnull(@tmpstring,'') + @a, @i = @i + 1	
   		--select @tmpstring = @tmpstring + @a, @i = @i + 1
   
   		end
   
   	/* convert temp string to GL Acct */
   	select @newglacct = convert(char(20),@tmpstring)
   
   
   	
   	/* see if new GL Account already exists */
   	if exists(select * from bGLAC where GLCo = @toco and GLAcct = @newglacct) goto next_SourceAcct
   
   	insert #GLAcctPreview values(@glacct, @newglacct, @description)
   	
   	goto next_SourceAcct
   
   
   
   
   bspexit:
   	if @opencursor = 1
   		begin
   		close bcSourceAcct
   		deallocate bcSourceAcct
   		end
   
   	select SourceAcct, DestAcct, Description from #GLAcctPreview
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLACCopyPreview] TO [public]
GO
