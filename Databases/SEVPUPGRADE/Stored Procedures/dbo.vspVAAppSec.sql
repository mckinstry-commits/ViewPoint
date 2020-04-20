SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   PROCEDURE [dbo].[vspVAAppSec]
   /****************************************************************
   	Created:  RM 08/10/01
   	Modified: RT 12/11/03 - issue #23173, exclude non-dbo views.
  			  DANF 05/13/2004 - Corrected Select statement.
 			  RT 01/27/05 - issue #26957, put brackets around view names in case they start with a number.
			  DANF 01/24/05 - issue #119669 exclude system views (begining with sys) from permission setting
			  DANF 02/12/07 - issue 123846 increase the view name from 30 to 128
			  AARONL 03/08/07 - Added "Execute as" in order to allow users to fire procedure. Commented out Drop statement 
			  AL 1/17/08 - Added try/catch blocks to handle insert errors on system views.   
			  AMR - 144712 - fixing the app role so that public gets select permissions
	Usage: Activates or Deactivates Viewpoint Application Role Security
   
   	Pass in:
   	@activate, Y = activate, N = deactivate
   
   ****************************************************************/
    (
      @activate bYN,
      @msg VARCHAR(255) OUTPUT
    )
    WITH EXECUTE AS 'viewpointcs'
AS 
    DECLARE @viewname VARCHAR(128),
        @permissionstring VARCHAR(255),
        @error INTEGER
   
	
	
    DECLARE bcViews CURSOR local fast_forward
    FOR
        --issue #23173
	SELECT    TABLE_NAME
      FROM      INFORMATION_SCHEMA.VIEWS
      ORDER BY  TABLE_NAME

   /* Note replaced by query above as sysobject and sysusers cannot be used in future version of SQL
	Select a.name from sysobjects a with (nolock) 
   join sysusers b with (nolock) on a.uid = b.uid 
   where a.xtype = 'V' and b.name = 'dbo' and substring(a.name,1,3) <> 'sys'*/
   
   --Select name from sysobjects where xtype = 'V'
    OPEN bcViews
   
    IF @activate = 'Y' 
        BEGIN
   
            FETCH NEXT FROM bcViews INTO @viewname
            WHILE @@Fetch_status = 0 
                BEGIN
                    BEGIN TRY

                        SELECT  @permissionstring = 'REVOKE INSERT,UPDATE,DELETE ON ['
                                + @viewname + '] TO public'
   		
                        EXEC(@permissionstring)
                        --144172 - adding the select to public
                        SELECT  @permissionstring = 'GRANT SELECT ON ['
                                + @viewname + '] TO public'
   	
                        EXEC(@permissionstring)
   
                        SELECT  @permissionstring = 'GRANT SELECT,INSERT,UPDATE,DELETE ON ['
                                + @viewname + '] TO Viewpoint'
   	
                        EXEC(@permissionstring)
                    END TRY

                    BEGIN CATCH
                        SELECT  @error = ERROR_SEVERITY()
                        IF ERROR_SEVERITY() <> 16 
                            RAISERROR ('Error while updating views', @error, 1)
                    END CATCH
   		
                    FETCH NEXT FROM bcViews INTO @viewname
                END
   
        END
    ELSE 
        BEGIN
   
            FETCH NEXT FROM bcViews INTO @viewname
            WHILE @@Fetch_status = 0 
                BEGIN
                    BEGIN TRY
                        SELECT  @permissionstring = 'Grant Select,Insert,Update,Delete on ['
                                + @viewname + '] to public'
   		
                        EXEC(@permissionstring)
                    END TRY

                    BEGIN CATCH
                        SELECT  @error = ERROR_SEVERITY()
                        IF ERROR_SEVERITY() <> 16 
                            RAISERROR ('Error while updating views', @error, 1)
                    END CATCH

                    FETCH NEXT FROM bcViews INTO @viewname
                END
   
--   	if exists(select top 1 1 from sys.database_principals  where name='Viewpoint')
--		begin
--   		DROP APPLICATION ROLE Viewpoint
--		end
   
        END
   
   
    CLOSE bcViews
    DEALLOCATE bcViews








GO
GRANT EXECUTE ON  [dbo].[vspVAAppSec] TO [public]
GO
