SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

CREATE procedure [dbo].[vspVAViewGen]
   /************************************************************************
   * CREATED:  MH 10/10/00
   * MODIFIED: DANF 01/11/00 correct where clause to use isnull instead of in
   *			RM 03/16/01 Modified tablename length and base table validation to include UD tables
   *				and changed create string so that it doesnt put the viewname twice.
   *           kb 1/23/2 - issue #16020
   *			GG 06/03/02 - #17516 - changed the way nulls are handled within view text
   *			RM 09/18/02 - Commented out all sp_recompile calls, they are not needed, and will be handled
   							automatically by SQL.
   *			GG 10/22/02 - #19082 - don't try to regenerate non-base views if text is null
   *			kb 11/8/2 - #19277 - problem recompiling dependent views need to change
   *                                charindex code to do an upper first so it could find a match
   *			DANF 12/10/02 - #19597 - move nullable columns with datatpye selection logic my changes are mark with ----
   *			DANF 05/29/03 - #20783 - If one data type is secured on a table then more the column is null check outside the subquery.
   *			DANF 07/23/03 - #21929 - refresh dependent views using (exec sp_refreshview titleview) instead of recompiling view from syscomments.
   *			DANF 08/18/03 - #22178 - expand @whereclausevp to 150
   *			DANF 11/06/03 - #22894 - regenerate JCJP view with JCCH.
   *			DANF 09/14/2004 - Issue 19246 added new login
   *			DANF 03/27/2006 - Issue 120726 Correct view Generator to consider Application Role security.
   *			JRK 01/23/2007 - Port to VP6.  vDDFR revamped.
   *			JonathanP 02/26/2007 - Added "with execute as 'viewpointcs'" after parameters to give access those not logged in as viewpointcs.
   *			JonathanP 10/25/07 - Added "and @inputtype <> 6" in the section that checks for type conversions. See issue #125829
   *			DANF 11/28/2007 - #120454 - Reconstructed views for performance by removing old style joins and using sub queries.
   *			DANF 02/05/2008 - #125049 - Use the Employee column from DDDU instead of the Instance column and remove the convert.
   *			George Clingerman 05/08/2008 - #128257 - Exclude VCSPortal from datatype security when the views are generated
   *			JonathanP 06/11/2008 - #128393 - The Where clause has changed when setting the @ViewDepends variable from "Text like @likeclause and so.Type = 'V'" to " Text like '% dbo.' + @viewname + ' %' or sc.text like '% ' + @viewname + ' %'	 and so.Type = 'V
'"
   *			JonathanP 06/18/2008 - #128393 rejection 2 - Fixed the where clause from my last change. I changed it to: where ((sc.text like '% dbo.' + @viewname + ' %') or (sc.text like '% ' + @viewname + ' %')) and so.Type = 'V'
   *			JonathanP 08/13/2008 - #129381 - Added vspRefreshParentViews to fix the error. 
   *			JonathanP 08/21/2008 - #129381 - My last fix did not fix the problem. I now correctly refresh all the views using vspRefreshViews.
   *			JonathanP 09/16/2008 - #129656 - We will now not refresh dependent views. @viewname and @tablename are now 60 characters also.   
   *			JonathanP 02/18/2008 - #129835 - Refactored the procedure to call the vfVAViewGenQuery function to get the dynamic query to execute.
   *
   * Purpose of Stored Procedure
   *
   *    Generate a new view or re-generate and exising view.
   *    Will factor in security.
   *
   *    Parameters
   *    ------------------------
   *    @viewname = Name of view
   *    @tablename = Name of table view based on.
   *    @msg = Return message.
   *
   * Notes about Stored Procedure
   *
   * returns 0 if successfull
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
    (@viewname varchar(60),  @tablename varchar(60) = null, @msg varchar(256) output) with execute as 'viewpointcs'
   
   as
set nocount on
	   
	declare @rcode int, @app bYN, @dynamicSqlQuery varchar(max), @grantquery varchar(max)
	set @rcode = 0

	if @viewname is null
	begin
		select @msg = 'Missing View name.', @rcode = 1
		goto bspexit
	end

	if @tablename is not null and (objectproperty (object_id(@tablename),'ISTABLE') = 0)
	begin
		select @msg = @tablename + ' is not a Viewpoint table.', @rcode = 1
		goto bspexit
	end				
		
	--if (len(@viewname) <> 4) and (@viewname not like 'ud%') goto NotBaseView   		 		

	-- Get the query to execute that will create/update the view.	
	select @dynamicSqlQuery = dbo.vfVAViewGenQuery(@viewname, @tablename)

	-- Create/Update the view.
	exec (@dynamicSqlQuery)

	-- Handle permissions for the view.
	if object_id(@viewname) is not null
	begin
		select @grantquery = 'grant Select,Insert,Update,Delete on ' +  @viewname + ' to public'
		exec (@grantquery)
			
		select @app = isnull(UseAppRole,'N') from DDVS with (nolock)
		
		if @app = 'Y'
		begin
			select @grantquery = 'Revoke Insert,Update,Delete on [' + @viewname + '] to public'
			exec(@grantquery)

			select @grantquery = 'Grant Select,Insert,Update,Delete on [' + @viewname + '] to Viewpoint'
			exec(@grantquery)
		end
	end
	else
	begin
		select @msg = 'Unable to create view ' + @viewname + '.', @rcode = 1
		goto bspexit
	end
	   
NotBaseView:	-- not a Viewpoint base security view, so rebuild it based on current text    	
   
bspexit:

  	return @rcode




GO
GRANT EXECUTE ON  [dbo].[vspVAViewGen] TO [public]
GO
