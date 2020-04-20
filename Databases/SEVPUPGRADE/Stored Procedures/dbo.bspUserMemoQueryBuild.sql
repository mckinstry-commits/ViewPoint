SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspUserMemoQueryBuild Script Date: 11/25/2003 ******/
   CREATE   procedure [dbo].[bspUserMemoQueryBuild]
    /***********************************************************
    * Created By:	GF 11/25/2003 - issue #23139
    * Modified By:	GF 02/28/2005 - issue #19185 MS material vendor enhancement
    *
    *
    *
    * USAGE:
    * Creates an user memo update string based on passed in source and destination tables or views.
    * Unless working with the Viewpoint connection use views only, otherwise error will occur during
    * update. Also do not lead with 'dbo.' this will not work when checking sysobjects.
    *
    *
    * INPUT:
    *
    * OUTPUT:
    *   @errmsg     if something went wrong
    
    * RETURN VALUE
    *   0   success
    *   1   fail
    *****************************************************/
   (@co bCompany, @mth bMonth, @batchid bBatchID, @source varchar(30),
    @destination varchar(30), @ud_exists bYN output, @update varchar(2000) output, 
    @join varchar(2000) output, @where varchar(2000) output, @errmsg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @openusermemo int, @columnname varchar(30), @srcobject_id int, @dstobject_id int
   
   select @rcode = 0, @openusermemo = 0, @ud_exists = 'N'
   
   if isnull(@source,'') = ''
   	begin
   	select @errmsg = 'Missing source object.', @rcode = 1
   	goto bspexit
   	end
   
   if isnull(@destination,'') = ''
   	begin
   	select @errmsg = 'Missing destination object.', @rcode = 1
   	goto bspexit
   	end
   
   -- get object id for source from sysobjects
   select @srcobject_id = id from sysobjects where name = @source and xtype in ('U','V')
   if @@rowcount = 0
   	begin
   	select @errmsg = 'Missing source object_id in sysobjects.', @rcode = 1
   	goto bspexit
   	end
   
   -- get object id for destination from sysobjects
   select @dstobject_id = id from sysobjects where name = @destination and xtype in ('U','V')
   if @@rowcount = 0
   	begin
   	select @errmsg = 'Missing destination object_id in sysobjects.', @rcode = 1
   	goto bspexit
   	end
   
   
   
   -- set the user memo flags for the tables that have user memos
   if exists(select name from syscolumns where id = @srcobject_id and name like 'ud%')
     	begin
     	  	
     		-- declare cursor on User Memos that exist in source and destination objects
     		declare UserMemo cursor LOCAL FAST_FORWARD for select name
     		from syscolumns c where c.id = @srcobject_id and c.name like 'ud%'
     		and exists(select * from syscolumns t where t.name = c.name and t.id = @dstobject_id)
     
     		-- open user memo cursor
     		open UserMemo
     		set @openusermemo = 1
     
     		-- process through all entries in batch
     		UserMemo_loop:
     		fetch next from UserMemo into @columnname
     
     		if @@fetch_status = -1 goto UserMemo_end
     		if @@fetch_status <> 0 goto UserMemo_loop
     
     		set @ud_exists = 'Y'
     		if @update is null
     	  		select @update = 'update ' + @destination + ' set ' + @columnname + ' = b.' + @columnname
     		else
     			select @update = @update + ', ' + @columnname + ' = b.' + @columnname
     
     		goto UserMemo_loop
     
     		UserMemo_end:
     			close UserMemo
     			deallocate UserMemo
     			select @openusermemo = 0
     		
     	end
   
   -- if ud_exists = 'N' done, no need to build join or where clause
   if @ud_exists = 'N' goto bspexit
   
   -- create join clause and where clause
   if @source = 'MSTB' and @destination = 'MSTD'
   	begin
     	set @join = ' from MSTB b join MSTD on MSTD.MSCo = b.Co and MSTD.Mth = b.Mth and MSTD.MSTrans = b.MSTrans'
   	set @where = ' where b.Co = ' + convert(varchar(3),@co) 
     				+ ' and b.Mth = ' + CHAR(39) + convert(varchar(100),@mth) + CHAR(39)
   				+ ' and b.BatchId = ' + convert(varchar(10),@batchid)
     				+ ' and MSTD.MSCo = ' + convert(varchar(3),@co)
     				+ ' and MSTD.Mth = ' + CHAR(39) + convert(varchar(100),@mth) + CHAR(39)
   	end
   
   -- create join clause and where clause
   if @source = 'MSTD' and @destination = 'MSTB'
   	begin
     	set @join = ' from MSTD b join MSTB on MSTB.Co = b.MSCo and MSTB.Mth = b.Mth and MSTB.MSTrans = b.MSTrans'
   	set @where = ' where b.MSCo = ' + convert(varchar(3),@co)
     				+ ' and b.Mth = ' + CHAR(39) + convert(varchar(100),@mth) + CHAR(39)
     				+ ' and MSTB.Co = ' + convert(varchar(3),@co)
     				+ ' and MSTB.Mth = ' + CHAR(39) + convert(varchar(100),@mth) + CHAR(39)
   				+ ' and MSTB.BatchId = ' + convert(varchar(10),@batchid)
   	end
   
   if @source = 'MSIB' and @destination = 'MSIH'
   	begin
     	set @join = ' from MSIB b join MSIH on MSIH.MSCo = b.Co and MSIH.MSInv = b.MSInv and MSIH.Mth = b.Mth'
   	set @where = ' where b.Co = ' + convert(varchar(3),@co)
     				+ ' and b.Mth = ' + CHAR(39) + convert(varchar(100),@mth) + CHAR(39)
     				+ ' and MSIH.MSCo = ' + convert(varchar(3),@co)
     				+ ' and MSIH.Mth = ' + CHAR(39) + convert(varchar(100),@mth) + CHAR(39)
   	end
   
   -- create join clause and where clause
   if @source = 'MSHB' and @destination = 'MSHH'
   	begin
     	set @join = ' from MSHB b join MSHH on MSHH.MSCo = b.Co and MSHH.Mth = b.Mth and MSHH.HaulTrans = b.HaulTrans'
   	set @where = ' where b.Co = ' + convert(varchar(3),@co) 
     				+ ' and b.Mth = ' + CHAR(39) + convert(varchar(100),@mth) + CHAR(39)
   				+ ' and b.BatchId = ' + convert(varchar(10),@batchid)
     				+ ' and MSHH.MSCo = ' + convert(varchar(3),@co)
     				+ ' and MSHH.Mth = ' + CHAR(39) + convert(varchar(100),@mth) + CHAR(39)
   	end
   
   -- create join clause and where clause
   if @source = 'MSLB' and @destination = 'MSTD'
   	begin
     	set @join = ' from MSLB b join MSTD on MSTD.MSCo = b.Co and MSTD.Mth = b.Mth and MSTD.MSTrans = b.MSTrans'
   	set @where = ' where b.Co = ' + convert(varchar(3),@co)
     				+ ' and b.Mth = ' + CHAR(39) + convert(varchar(100),@mth) + CHAR(39)
   				+ ' and b.BatchId = ' + convert(varchar(10),@batchid)
     				+ ' and MSTD.MSCo = ' + convert(varchar(3),@co)
     				+ ' and MSTD.Mth = ' + CHAR(39) + convert(varchar(100),@mth) + CHAR(39)
   	end
   
   if @source = 'MSHH' and @destination = 'MSHB'
   	begin
     	set @join = ' from MSHH b join MSHB on MSHB.Co = b.MSCo and MSHB.Mth = b.Mth and MSHB.HaulTrans = b.HaulTrans'
   	set @where = ' where b.MSCo = ' + convert(varchar(3),@co) 
     				+ ' and b.Mth = ' + CHAR(39) + convert(varchar(100),@mth) + CHAR(39)
     				+ ' and MSHB.Co = ' + convert(varchar(3),@co)
     				+ ' and MSHB.Mth = ' + CHAR(39) + convert(varchar(100),@mth) + CHAR(39)
   				+ ' and MSHB.BatchId = ' + convert(varchar(10),@batchid)
   	end
   
   -- create join clause and where clause
   if @source = 'MSTD' and @destination = 'MSLB'
   	begin
     	set @join = ' from MSTD b join MSLB on MSLB.Co = b.MSCo and MSLB.Mth = b.Mth and MSLB.MSTrans = b.MSTrans'
   	set @where = ' where b.MSCo = ' + convert(varchar(3),@co)
     				+ ' and b.Mth = ' + CHAR(39) + convert(varchar(100),@mth) + CHAR(39)
     				+ ' and MSLB.Co = ' + convert(varchar(3),@co)
     				+ ' and MSLB.Mth = ' + CHAR(39) + convert(varchar(100),@mth) + CHAR(39)
   				+ ' and MSLB.BatchId = ' + convert(varchar(10),@batchid)
   	end
   
   -- create join clause and where clause
   if @source = 'MSWH' and @destination = 'APTH'
   	begin
     	set @join = ' from MSWH b join APTH on APTH.Mth = b.Mth'
   	set @where = ' where b.Co = ' + convert(varchar(3),@co)
     				+ ' and b.Mth = ' + CHAR(39) + convert(varchar(100),@mth) + CHAR(39)
   				+ ' and b.BatchId = ' + convert(varchar(10),@batchid)
   				+ ' and APTH.Mth = ' + CHAR(39) + convert(varchar(100),@mth) + CHAR(39)
   	end
   
   -- create join clause and where clause
   if @source = 'MSMH' and @destination = 'APTH'
   	begin
     	set @join = ' from MSMH b join APTH on APTH.Mth = b.Mth'
   	set @where = ' where b.Co = ' + convert(varchar(3),@co)
     				+ ' and b.Mth = ' + CHAR(39) + convert(varchar(100),@mth) + CHAR(39)
   				+ ' and b.BatchId = ' + convert(varchar(10),@batchid)
   				+ ' and APTH.Mth = ' + CHAR(39) + convert(varchar(100),@mth) + CHAR(39)
   	end
   
   
   -- create join clause and where clause
   if @source = 'APHB' and @destination = 'APTH'
   	begin
     	set @join = ' from APHB b join APTH on APTH.APCo = b.Co and APTH.Mth = b.Mth and APTH.APTrans = b.APTrans'
   	set @where = ' where b.Co = ' + convert(varchar(3),@co) 
     				+ ' and b.Mth = ' + CHAR(39) + convert(varchar(100),@mth) + CHAR(39)
   				+ ' and b.BatchId = ' + convert(varchar(10),@batchid)
     				+ ' and APTH.APCo = ' + convert(varchar(3),@co)
     				+ ' and APTH.Mth = ' + CHAR(39) + convert(varchar(100),@mth) + CHAR(39)
   	end
   
   -- create join clause and where clause
   if @source = 'APLB' and @destination = 'APTL'
   	begin
     	set @join = ' from APLB b join APTL on APTL.APCo = b.Co and APTL.Mth = b.Mth and APTL.APLine = b.APLine'
   	set @where = ' where b.Co = ' + convert(varchar(3),@co)
     				+ ' and b.Mth = ' + CHAR(39) + convert(varchar(100),@mth) + CHAR(39)
   				+ ' and b.BatchId = ' + convert(varchar(10),@batchid)
     				+ ' and APTL.APCo = ' + convert(varchar(3),@co)
     				+ ' and APTL.Mth = ' + CHAR(39) + convert(varchar(100),@mth) + CHAR(39)
   	end
   
   
   -- create join clause and where clause
   if @source = 'APTH' and @destination = 'APHB'
   	begin
     	set @join = ' from APTH b join APHB on APHB.Co = b.APCo and APHB.Mth = b.Mth and APHB.APTrans = b.APTrans'
   	set @where = ' where b.APCo = ' + convert(varchar(3),@co) 
     				+ ' and b.Mth = ' + CHAR(39) + convert(varchar(100),@mth) + CHAR(39)
     				+ ' and APHB.Co = ' + convert(varchar(3),@co)
     				+ ' and APHB.Mth = ' + CHAR(39) + convert(varchar(100),@mth) + CHAR(39)
   				+ ' and APHB.BatchId = ' + convert(varchar(10),@batchid)
   	end
   
   -- create join clause and where clause
   if @source = 'APTL' and @destination = 'APLB'
   	begin
     	set @join = ' from APTL b join APLB on APLB.Co = b.APCo and APLB.Mth = b.Mth and APLB.APLine = b.APLine'
   				+ ' join APHB h on h.Co = APLB.Co and h.Mth = APLB.Mth and h.BatchId = APLB.BatchId'
   				+ ' and h.BatchSeq = APLB.BatchSeq and h.Co = b.APCo and h.Mth = b.Mth and h.APTrans = b.APTrans'
   	set @where = ' where b.APCo = ' + convert(varchar(3),@co)
     				+ ' and b.Mth = ' + CHAR(39) + convert(varchar(100),@mth) + CHAR(39)
     				+ ' and APLB.Co = ' + convert(varchar(3),@co)
     				+ ' and APLB.Mth = ' + CHAR(39) + convert(varchar(100),@mth) + CHAR(39)
   				+ ' and APLB.BatchId = ' + convert(varchar(10),@batchid)
   	end
   

   

   
   
   
   
   bspexit:
     	if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) + '[bspUserMemoQueryBuild]'
      	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspUserMemoQueryBuild] TO [public]
GO
