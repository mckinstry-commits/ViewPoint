SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**********/
CREATE  proc [dbo].[bspHQWDJoinClauseBuild]
/*************************************
* Created By:   GF 12/19/2001
* Modified By:  GF 07/31/2002 - Remmed out code to switch the sub contact with archeng contact.
*				GF 01/20/2004 - issue #18841 added word table to input parameters
*				RM 03/26/04 - Issue# 23061 - Added IsNulls
*				GF 04/01/2004 - issue #24215 - expanded join string from 2000 to 4000
*				GF 10/30/2009 - issue #134090
*
* Creates join clause for use with Word Document Template merge.
*
*
* Pass:
*	HQ Template Type
*
* Success returns:
*	0 and Join Clause
*
* Error returns:
*	1 and error message
**************************************/
(@templatetype varchar(10), @viewjoins bYN = 'N', @sendtosub bYN = 'Y', @wordtable bYN = 'N',
@joinstring varchar(4000) output, @msg varchar(255) output)
as
set nocount on
   
   declare @rcode int, @validcnt int, @opencursor tinyint, @docobject varchar(30), 
   		@linkeddocobject varchar(30), @objecttable varchar(30), @joinorder tinyint,
   		@alias varchar(2), @required bYN, @joinclause varchar(255), @linkedobjecttable varchar(30)
   
   
   select @rcode = 0, @opencursor = 0
   
   ----if @templatetype is null
   ----	begin
   ----	select @msg = 'Missing Template Type', @rcode = 1
   ----	goto bspexit
   ----	end
   
   if not exists(select top 1 1 from bHQWO with (nolock) where TemplateType=@templatetype)
   	begin
   	select @msg = 'Missing Document Objects for Template Type - ' + isnull(@templatetype,'') + '.', @rcode=1
   	goto bspexit
   	end
   
   
   -- create a cursor to to process document objects from bHQWO
   declare bcHQWO cursor LOCAL FAST_FORWARD
   for select DocObject, LinkedDocObject, ObjectTable, JoinOrder, Alias, Required, JoinClause
   from bHQWO where TemplateType = @templatetype and WordTable = @wordtable
   Order By JoinOrder
   
   -- open cursor
   open bcHQWO
   select @opencursor = 1
   
   -- loop through bcHQWO cursor
   HQWO_loop:
   fetch next from bcHQWO into @docobject, @linkeddocobject, @objecttable, @joinorder, @alias, @required, @joinclause
   
   if @@fetch_status <> 0 goto HQWO_end
   
   if @joinorder = 0 and @required <> 'Y'
   	begin
   	select @msg = 'First document object must be required. DocObject: ' + isnull(@docobject,'') + '!', @rcode = 1
   	goto bspexit
   	end
   
   if @joinorder = 0 and isnull(@joinclause,'') <> ''
   	begin
   	select @msg = 'First document object may not have a join clause. DocObject: ' + isnull(@docobject,'') + '!', @rcode = 1
   	goto bspexit
   	end
   
   if isnull(@joinstring,'') = '' and @joinorder <> 0
   	begin
   	select @msg = 'Missing base join clause, join order must be zero and required for first document object', @rcode = 1
   	goto bspexit
   	end
   
   -- get linked object data
   if isnull(@linkeddocobject,'') <> ''
   	begin
   	select @linkedobjecttable = ObjectTable
   	from bHQWO with (nolock) where TemplateType=@templatetype and DocObject=@linkeddocobject
   	if @@rowcount <> 1
   		begin
   		select @msg = 'Missing linked object - ' + isnull(@linkeddocobject,'') + ', cannot build join statement', @rcode = 1
   		goto bspexit
   		end
   	end
   
---- create base join clause
if @joinorder = 0
	begin
	if @viewjoins = 'Y'
		select @joinstring = ' from ' + isnull(@objecttable,'') + ' ' + isnull(@alias,'') + ' with (nolock)' + CHAR(13) + CHAR(10)
	else
		select @joinstring = ' from ' + isnull(@objecttable,'') + ' ' + isnull(@alias,'') + ' with (nolock)'
	goto HQWO_loop
	end

-- build required join clauses
if @required = 'Y'
	begin
	if @viewjoins = 'Y'
		select @joinstring = isnull(@joinstring,'') + ' join ' + isnull(@objecttable,'') + ' ' + isnull(@alias,'') + ' with (nolock) ON ' + isnull(@joinclause,'') + CHAR(13) + CHAR(10)
	else
		select @joinstring = isnull(@joinstring,'') + ' join ' + isnull(@objecttable,'') + ' ' + isnull(@alias,'') + ' with (nolock) ON ' + isnull(@joinclause,'')
	goto HQWO_loop
	end

-- build other joins for view
if @viewjoins = 'Y'
	begin
	select @joinstring = isnull(@joinstring,'') + ' left join ' + isnull(@objecttable,'') + ' ' + isnull(@alias,'') + ' with (nolock) ON ' + isnull(@joinclause,'') + CHAR(13) + CHAR(10)
	goto HQWO_loop
	end
   	
   	
select @joinstring = isnull(@joinstring,'') + ' left join ' + isnull(@objecttable,'') + ' ' + isnull(@alias,'') + ' with (nolock) ON ' + isnull(@joinclause,'')
goto HQWO_loop
   	
   ------ if @templatetype is not 'Submit'
   ----if @templatetype <> 'Submit'
   ----	begin
   ----	select @joinstring = isnull(@joinstring,'') + ' left join ' + isnull(@objecttable,'') + ' ' + isnull(@alias,'') + ' with (nolock) ON ' + isnull(@joinclause,'')
   ----	goto HQWO_loop
   ----	end
   
   ------ if @sendtosub = 'Y' then accept join clause as is
   ----if @sendtosub = 'Y'
   ----	begin
   ----	select @joinstring = isnull(@joinstring,'') + ' left join ' + isnull(@objecttable,'') + ' ' + isnull(@alias,'') + ' with (nolock) ON ' + isnull(@joinclause,'')
   ----	goto HQWO_loop
   ----	end
   
   ------ need to replace the SubFirm with the ArchEngFirm - not sending to sub
   ------ select @joinclause = replace(@joinclause, 'SubFirm', 'ArchEngFirm')
   ------ select @joinclause = replace(@joinclause, 'SubContact', 'ArchEngContact')
   ----select @joinstring = isnull(@joinstring,'') + ' left join ' + isnull(@objecttable,'') + ' ' + isnull(@alias,'') + ' with (nolock) ON ' + isnull(@joinclause,'')
   ----goto HQWO_loop




HQWO_end:
	if @opencursor = 1
	   begin
	   close bcHQWO
	   deallocate bcHQWO
	   set @opencursor = 0
	   end


bspexit:
	if @opencursor = 1
   		begin
   		close bcHQWO
   		deallocate bcHQWO
   		set @opencursor = 0
   		end

   if @rcode<>0 select @msg=isnull(@msg,'') /*+ char(13) + char(10) + '[bspHQWDJoinClauseBuild]'*/
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQWDJoinClauseBuild] TO [public]
GO
