SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**********************************************************/
   CREATE PROCEDURE [dbo].[bspBatchUserMemoUpdatePMSL]
   /***********************************************************
   * CREATED BY:	GF 07/20/2004 - issue #25100
   * MODIFIED By:	GF 01/14/2005 - #25726 changed exec update to sp_executesql statement. changed varchar to nvarchar
   *				DANF 04/02/08 - #125049 Corrected update statement for dynamic sql.
   *				DC 1/26/09 - #131969 - Variable length insufficient
   *				GF 06/25/2010 - issue #135813 expanded SL to varchar(30)
   *
   *
   * USAGE:     Updates SLIB or SLIT with user memo data from PMSL for PM Interface
   *
   * INPUT:
   *
   * OUTPUT:
   *   @errmsg     if something went wrong
   *
   * RETURN VALUE
   *   0   success
   *   1   fail
   *****************************************************/
   (@slco bCompany, @mth bMonth, @batchid bBatchID, @batchseq int, @sl VARCHAR(30),
    @slitem bItem, @pmco int, @project bJob, @pmslseq int, @table varchar(30), 
    @errmsg varchar(255) output)
   as
   set nocount on
    
   /*DC #131969  
   declare @rcode int, @updatestring nvarchar(1000), @columnname varchar(128), @paramsin nvarchar(500)
	*/
   declare @rcode int, @updatestring nvarchar(MAX), @columnname varchar(128), @paramsin nvarchar(500)
      
   set @rcode = 0
   
   -- -- -- define parameters for exec sql statement #25726
   select @paramsin = N'@slco tinyint, @mth bMonth, @batchid int, @batchseq int, @sl varchar(30), ' +
   					'@slitem smallint, @pmco tinyint, @project varchar(30), @pmslseq int'
   
   
   if @table = 'SLIB'
   BEGIN
   	-- -- -- pseudo cursor for ud columns in source to be updated
   	select @columnname = min(name) from syscolumns where name like 'ud%' and id = object_id('dbo.PMSL')
   	while @columnname is not null
   	BEGIN
   		-- -- -- check if ud column exists in SLIB
   		if exists(select * from syscolumns where name = @columnname and id = object_id('dbo.SLIB'))
   			begin
   			set @updatestring = null
   			select @updatestring = 'update SLIB set ' + @columnname  + '= p.' + @columnname +
   	 				' from PMSL p join SLIB b on p.SLCo=b.Co and p.SLItem=b.SLItem' +
   					' where b.Co=@slco and b.Mth=@mth and b.BatchId=@batchid and b.BatchSeq=@batchseq' +
   	 				' and b.SLItem=@slitem and p.PMCo=@pmco and p.Project=@project' +
   	 				' and p.Seq=@pmslseq and p.SLCo=@slco and p.SL=@sl and p.SLItem=@slitem'
   
   
   			-- -- -- changed to use sp_executesql - #25726
   			EXECUTE sp_executesql @updatestring, @paramsin, @slco, @mth, @batchid, @batchseq, @sl, @slitem, @pmco, @project, @pmslseq
   -- -- -- 		exec (@updatestring)
   			if @@rowcount = 0
   				begin
   				select @rcode = 1
   				goto bspexit
   				end
   			end
   	
   	
   	select @columnname = min(name) from syscolumns where name like 'ud%' and id = object_id('dbo.PMSL') and name > @columnname
   	if @@rowcount = 0 select @columnname = null
   	END
   END
   
   
   
   if @table = 'SLIT'
   BEGIN
   	-- -- -- pseudo cursor for ud columns in source to be updated
   	select @columnname = min(name) from syscolumns where name like 'ud%' and id = object_id('dbo.PMSL')
   	while @columnname is not null
   	BEGIN
   	
   		-- -- -- check if ud column exists in SLIT
   		if exists(select * from syscolumns where name = @columnname and id = object_id('dbo.SLIT'))
   			begin
   			set @updatestring = null
   			select @updatestring = 'update SLIT set ' + @columnname  + '= p.' + @columnname +
   	 				' from PMSL p join SLIT b on p.SLCo=b.SLCo and p.SL=b.SL and p.SLItem=b.SLItem' +
   					' where b.SLCo=' + convert(varchar(3),@slco) + 
   					' and b.SL=''' + convert(varchar(30),@sl) + '''' +
   	 				' and b.SLItem=' + convert(varchar(10),@slitem) +
   	 		 		' and p.PMCo=' + convert(varchar(3),@pmco) + 
   	 				' and p.Project=''' + convert(varchar(30),@project)+ '''' +
   	 				' and p.Seq=' + convert(varchar(6),@pmslseq) + 
 
   	 				' and p.SLCo=' + convert(varchar(3),@slco) + 
   	 				' and p.SL=''' + convert(varchar(30),@sl)+ '''' + 
   	 		 		' and p.SLItem=' + convert(varchar(10),@slitem)
   
   
   			-- -- -- changed to use sp_executesql - #25726
   			EXECUTE sp_executesql @updatestring, @paramsin, @slco, @mth, @batchid, @batchseq, @sl, @slitem, @pmco, @project, @pmslseq
   -- -- -- 		exec (@updatestring)
   			if @@rowcount = 0
   				begin
   				select @rcode = 1
   				goto bspexit
   				end
   			end
   	
   	
   	select @columnname = min(name) from syscolumns where name like 'ud%' and id = object_id('dbo.PMSL') and name > @columnname
   	if @@rowcount = 0 select @columnname = null
   	END
   END
   
   
   
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspBatchUserMemoUpdatePMSL] TO [public]
GO
