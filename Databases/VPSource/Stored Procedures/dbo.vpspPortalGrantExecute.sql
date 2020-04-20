SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE            procedure [dbo].[vpspPortalGrantExecute]
  /*****************************************
   * Modified from bpsVPGrantAll   *
   *************************************/
   
  /********************************
* Created: George Clingerman
* Modified: Tim Stevens - 01/27/2009
*
* Used by VPUpdate to grant permissions to VP Connects objects
*
* Return code:
* @rcode - anything except 0 indicates an error
* 01/27/2009 - TMS - Added [viewpointcs] userid to grant of select, insert, update, delete
*
*********************************/
(@destdb varchar(30) = null, @rcode int output, @msg varchar(500) output)
  as
  
  declare @itemcount int, @name varchar(8000), @id int, @opencursor tinyint, @tsql varchar(8000),
      @changed tinyint
  
  set nocount on
  
  select @itemcount = 0
  --select 'Granting execute permission to VCSPortal on all procedures starting with (vpsp) in ' + DB_NAME()
  
  -- create cursor to loop through all Viewpoint procedures w/o execute permission
  declare VPname cursor for
  select o.name
  from sysobjects o
  left join sysprotects p on o.id = p.id
  where (p.action <> 224 or p.action is null) and o.type = 'P' and 
        (o.name like 'vpsp%') and
         user_name(o.uid)= 'dbo'
  order by o.name
  
  -- open cursor
  open VPname
  select @opencursor = 1
  
  -- loop through all procs in cursor
  proc_loop:
      fetch next from VPname into @name
  
     	if @@fetch_status <> 0 goto proc_end
  
      select @tsql = 'grant execute on [' + @name + '] to [VCSPortal]'
      exec (@tsql)
      
      if @@error <> 0 goto vsperror
	      
      select @itemcount = @itemcount + 1
      --select @name
      goto proc_loop
  
  proc_end:   -- finished with Viewpoint procedures
      --select convert(varchar(4),@itemcount) + ' procedures updated.'
      close VPname
      deallocate VPname
      select @opencursor = 0
  ----
    

 ----
  select @itemcount = 0
  --select 'Granting Select to VCSPortal on all views starting with "pv%" in ' + DB_NAME()
  
  -- create cursor to loop through all Viewpoint procedures w/o execute permission
  declare VPname cursor for
  select id, name
  from sysobjects where type = 'V' and user_name(uid)= 'dbo' and name like 'pv%'
  order by name
  
  -- open cursor
  open VPname
  select @opencursor = 1, @itemcount = 0, @changed = 0
  
  -- loop through all views in cursor
  view_loop:
      fetch next from VPname into @id, @name
  
     if @@fetch_status <> 0 goto view_end
  
      if (select count(*) from sysprotects where id = @id and action = 193) = 0   -- select
          begin
          select @tsql = 'grant select on [' + @name + '] to [VCSPortal]'
          exec (@tsql)
          if @changed = 0 select @changed = 1
          end
          
       if @@error <> 0 goto vsperror
	/*
      if @changed = 1
          begin
          select @name
          select @itemcount = @itemcount + 1, @changed = 0
          end
   */
      goto view_loop
  


 
  view_end:   -- finished with Viewpoint views
      --select convert(varchar(4),@itemcount) + ' views updated.'
      close VPname
      deallocate VPname
      select @opencursor = 0
  



select @itemcount = 0
--grant execute on [vspDDAddAppLog] to [VCSPortal]
Begin Try
	set @tsql = 'grant execute on [vspHQGetAttachmentInfo] to [VCSPortal]'
	grant execute on [vspHQGetAttachmentInfo] to [VCSPortal]
	set @tsql = 'grant execute on [vspDDGetDaysToKeepLogHistory] to [VCSPortal]'
	grant execute on [vspDDGetDaysToKeepLogHistory] to [VCSPortal]
	set @tsql = 'grant execute on [vspMailQueueDelete] to [VCSPortal]'
	grant execute on [vspMailQueueDelete] to [VCSPortal]
	set @tsql = 'grant execute on [vspMailQueueGet] to [VCSPortal]'
	grant execute on [vspMailQueueGet] to [VCSPortal]
	set @tsql = 'grant execute on [vspMailQueueInsert] to [VCSPortal]'
	grant execute on [vspMailQueueInsert] to [VCSPortal]
	set @tsql = 'grant execute on [vspMailQueueUpdate] to [VCSPortal]'
	grant execute on [vspMailQueueUpdate] to [VCSPortal]
	set @tsql = 'grant select on [DDAL] to [VCSPortal]'
	grant select on [DDAL] to [VCSPortal]
	set @tsql = 'grant select on [DDALog] to [VCSPortal]'
	grant select on [DDALog] to [VCSPortal]
End Try
Begin Catch
	 goto vsperror
End Catch



  set nocount on
  
  select @itemcount = 0
  --select 'Granting permissions to VCSPortal on all tables starting with (p) in ' + DB_NAME()
  
  --Create a cursor to loop through all the Portal Tables
  declare VPname cursor for
  select o.name
  from sysobjects o 
  where o.type = 'U' and 
        (o.name like 'p%') and
         user_name(o.uid)= 'dbo'
  order by o.name

Begin Try
  --Open the cursor
  open VPname
  select @opencursor = 1
  
  --Loop through all the Tables in cursor
  table_loop:
      fetch next from VPname into @name
  
      if @@fetch_status <> 0 goto table_end
  
      select @tsql = 'grant select on [' + @name + '] to [VCSPortal], [viewpointcs]'
      exec (@tsql)
 
      select @tsql = 'grant insert on [' + @name + '] to [VCSPortal], [viewpointcs]'
      exec (@tsql)

      select @tsql = 'grant update on [' + @name + '] to [VCSPortal], [viewpointcs]'
      exec (@tsql)

      select @tsql = 'grant delete on [' + @name + '] to [VCSPortal], [viewpointcs]'
      exec (@tsql)

	  --PRINT @name + ' permissions have been granted for VCSPortal and viewpointcs'

   	  -- select @name
      goto table_loop
  
  table_end:   -- finished with Portal Table
      --select convert(varchar(4),@itemcount) + ' table updated.'
      close VPname
      deallocate VPname
      select @opencursor = 0
  ----
  End Try
  Begin Catch
	goto vsperror
  End Catch
  bspexit:
      if @opencursor = 1
          begin
			  close VPname
			  deallocate VPname
          end
      set @rcode = 0
      set @msg = ''
      select @rcode, @msg
      return 
      
vsperror:
		select @msg = 'Error during grant execute , unable to complete.' + char(13) + @tsql
		set @rcode = -1
		 select @rcode, @msg
		return 
  






GO
GRANT EXECUTE ON  [dbo].[vpspPortalGrantExecute] TO [VCSPortal]
GO
