SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bsp_RegenerateViews]
   /*******************************************************************************
   * Created: DANF 12/21/2004
   * Modified:
   *
   * This SP will regeerate views that have been generated with data type security.
   *
   *
   ********************************************************************************/
   
   as
   
   declare @viewname varchar(20), @tablename varchar(21), @msg varchar(80), @rc int, @opencursor int
   
   declare bcViews cursor local fast_forward for
   select o.name, 'b' + o.name from syscomments s with (nolock)
   join sysobjects o with (nolock) on o.id=s.id
   where text like '%DDDU%' and o.xtype = 'V' and o.name<>'DDDU' and len(o.name)=4
   order by o.name
   -- open cursor
   open bcViews
   select @opencursor = 1
   -- loop through bcViews cursor
   Views_loop:
       fetch next from bcViews into @viewname, @tablename
       if @@fetch_status <> 0 goto Views_end
   
   
   exec @rc = dbo.bspVAViewGen @viewname, @tablename, @msg
   	if @rc<>0
   		begin
   		print 'Error' + isnull(@viewname,'') + isnull(@msg,'')
   		end
   goto Views_loop
   
   Views_end:   -- finished with close and deallocate cursor
       close bcViews
       deallocate bcViews
       select @opencursor = 0

GO
GRANT EXECUTE ON  [dbo].[bsp_RegenerateViews] TO [public]
GO
