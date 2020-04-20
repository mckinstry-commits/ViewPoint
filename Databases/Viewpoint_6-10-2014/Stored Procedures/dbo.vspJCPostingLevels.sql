SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[vspJCPostingLevels]
   /****************************************************************************
   * Created By:   DanF 03/01/2006
   * Modified By: 
   *
   * USAGE:
   * 	Return the JC Company GL Interface level and journal description for
   *    display in form JC Batch update.
   *
   * INPUT PARAMETERS:
   *	JC Company
   *	Source Source
   *
   * OUTPUT PARAMETERS:
   *	JCCO GL data
   *
   * RETURN VALUE:
   * 	0 	    Success
   *	1 & message Failure
   *
   *****************************************************************************/
   (@jcco bCompany = null, @source bSource, @glinterfacelvldesc bDesc output, @gljournaldesc bDesc output,
     @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @glcostjournal bJrnl, @glrevjournal bJrnl, @glclosejournal bJrnl,
           @glmatjournal bJrnl, @glco bCompany,
		   @glcostlevel tinyint, @costjrnldesc bDesc, @glrevlevel tinyint, @revjrnldesc bDesc, 
		   @glcloselevel tinyint, @closejrnldesc bDesc, @glmatlevel tinyint, @matjrnldesc bDesc 

   select @rcode = 0, @glcostlevel = 0, @costjrnldesc = '', @glrevlevel = 0, @revjrnldesc = '',
          @glcloselevel = 0, @closejrnldesc = '', @glmatlevel = 0, @matjrnldesc = '',
		 @gljournaldesc ='Missing Journal', @glinterfacelvldesc = 'Missing Interface Level'
   
   if @jcco is null
       begin
   	select @msg = 'Missing JC Company', @rcode = 1
   	goto bspexit
   	end

   if @source is null
       begin
   	select @msg = 'Missing Source', @rcode = 1
   	goto bspexit
   	end
   
   -- get JCCo data
   select @glco=GLCo, @glcostlevel=GLCostLevel, @glcostjournal=GLCostJournal,
          @glrevlevel=GLRevLevel, @glrevjournal=GLRevJournal, @glcloselevel=GLCloseLevel,
          @glclosejournal=GLCloseJournal, @glmatlevel=GLMaterialLevel, @glmatjournal=GLMatJournal
   from dbo.bJCCO with (nolock) where JCCo=@jcco
   if @@rowcount = 0
       begin
       select @msg = 'JC Company does not exist.', @rcode = 1
       goto bspexit
       end
   
   -- get GL Journal Descriptions
   select @costjrnldesc=Description from bGLJR where GLCo=@glco and Jrnl=@glcostjournal
   
   select @revjrnldesc=Description from bGLJR where GLCo=@glco and Jrnl=@glrevjournal
   
   select @closejrnldesc=Description from bGLJR where GLCo=@glco and Jrnl=@glclosejournal
   
   select @matjrnldesc=Description from bGLJR where GLCo=@glco and Jrnl=@glmatjournal

   
if @source = 'JC CostAdj' or @source = 'JC Progres'
	begin
		select @gljournaldesc = @costjrnldesc
		set @glinterfacelvldesc = 'None'
		if @glcostlevel = 1 set @glinterfacelvldesc = 'Summary'
		if @glcostlevel = 2 set @glinterfacelvldesc = 'Detail'
	end 

if @source = 'JC MatUse'
	begin
		select @gljournaldesc = @matjrnldesc
		set @glinterfacelvldesc = 'None'
		if @glmatlevel = 1 set @glinterfacelvldesc = 'Summary'
		if @glmatlevel = 2 set @glinterfacelvldesc = 'Detail'
	end 

if @source = 'JC RevAdj'
	begin
		select @gljournaldesc = @matjrnldesc
		set @glinterfacelvldesc = 'None'
		if @glrevlevel = 1 set @glinterfacelvldesc = 'Summary'
		if @glrevlevel = 2 set @glinterfacelvldesc = 'Detail'
	end 

if @source = 'JC Close'
	begin
		select @gljournaldesc = @closejrnldesc
		set @glinterfacelvldesc = 'None'
		if @glcloselevel = 1 set @glinterfacelvldesc = 'Summary'
		if @glcloselevel = 2 set @glinterfacelvldesc = 'Detail'
	end 

if @source = 'JC Projctn' or @source = 'JC RevProj'
	begin
		set @gljournaldesc = ''
		set @glinterfacelvldesc = ''
		
	end 


   bspexit:
   	if @rcode<>0 select @msg=@msg
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCPostingLevels] TO [public]
GO
