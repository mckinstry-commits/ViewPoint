SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [dbo].[bspVAAppSec]
   /****************************************************************
   	Created:  RM 08/10/01
   	Modified: RT 12/11/03 - issue #23173, exclude non-dbo views.
  			  DANF 05/13/2004 - Corrected Select statement.
 			  RT 01/27/05 - issue #26957, put brackets around view names in case they start with a number.
			  DANF 01/24/05 - issue #119669 exclude system views (begining with sys) from permission setting
			  DANF 02/12/07 - issue 123846 increase the view name from 30 to 128
   
   	Usage: Activates or Deactivates Viewpoint Application Role Security
   
   	Pass in:
   	@activate, Y = activate, N = deactivate
   
   ****************************************************************/
   (@activate bYN,@msg varchar(255) output)
   
    AS
   
   declare @viewname varchar(128), @permissionstring varchar(200)
   
   declare bcViews cursor for  
   --issue #23173
	select TABLE_NAME from INFORMATION_SCHEMA.VIEWS

   /* Note replaced by query above as sysobject and sysusers cannot be used in future version of SQL
	Select a.name from sysobjects a with (nolock) 
   join sysusers b with (nolock) on a.uid = b.uid 
   where a.xtype = 'V' and b.name = 'dbo' and substring(a.name,1,3) <> 'sys'*/
   
   --Select name from sysobjects where xtype = 'V'
   open bcViews
   
   if @activate = 'Y' 
   begin
   
   	fetch next from bcViews into @viewname
   	while @@Fetch_status = 0
   	begin
   		
   		select @permissionstring = 'Revoke Insert,Update,Delete on [' + @viewname + '] to public'
   		
   		exec(@permissionstring)
   
   		select @permissionstring = 'Grant Select,Insert,Update,Delete on [' + @viewname + '] to Viewpoint'
   	
   		exec(@permissionstring)
   		
   		
   		fetch next from bcViews into @viewname
   	end
   
   end
   else
   begin
   
   	fetch next from bcViews into @viewname
   	while @@Fetch_status = 0
   	begin
   		select @permissionstring = 'Grant Select,Insert,Update,Delete on [' + @viewname + '] to public'
   		
   		exec(@permissionstring)
   		
   		fetch next from bcViews into @viewname
   	end
   
   	if exists(select top 1 1 from sys.database_principals  where name='Viewpoint')
		begin
   		DROP APPLICATION ROLE Viewpoint
		end
   
   end
   
   
   close bcViews
   deallocate bcViews

GO
GRANT EXECUTE ON  [dbo].[bspVAAppSec] TO [public]
GO
