SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    procedure [dbo].[bspPRTemplateCopy]
   /************************************************************************
   * CREATED:	mh 6/26/04    
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *	Copy a template    
   *    
   *           
   * Notes about Stored Procedure
   *
   *	If Destination Template does not exist, it will be created as part of 
   *	this procedure.
   * 
   *	@prco - PRCompany
   *	@copyfrom - Copy from Template or Standard Crafts and Classes.  T or S.
   *	@sourcetemplate - Source Template if @copyfrom is 'T'
   *	@whatcrafts - Copy 'All Crafts' or 'Selected Craft'
   *	@sourcecraft - Source Craft if @whatcrafts is 'S'
   *
   *	@payrateyn - Include Pay Rates
   *	@addonearnyn - Include Add-on earnings
   *	@variableearnyn - Include Variable Earnings
   *	@dedliabyn - Include Deductions and Liabilities
   *	@notesyn - Include Notes
   *	@jcitemsyn - Include Job Craft Items
   *	@destemplate - Destination Template
   *	@destdesc - Destination description
   *
   * 	returns 0 if successfull 
   * 	returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@prco bCompany, @copyfrom char(1), @sourcetemplate smallint, @whatcrafts char(1), 
   	@sourcecraft bCraft, @payrateyn bYN = 'N', @addonearnyn bYN = 'N', 
   	@variableearnyn bYN = 'N', @dedliabyn bYN = 'N', @notesyn bYN = 'N', @jcitemsyn bYN,
   	@desttemplate smallint, @destdesc bDesc, @msg varchar(100) = '' output)
   
   as
   set nocount on
   
       declare @rcode int, @templateexistsyn bYN
   
       select @rcode = 0
   
   	if @prco is null
   	begin
   		select @msg = 'Missing PR Company.', @rcode = 1
   		goto bspexit
   	end
   
   	if @copyfrom is null
   	begin
   		select @msg = 'Copy from not specified.', @rcode = 1
   		goto bspexit
   	end
   
   	if @copyfrom not in ('T', 'S') 
   	begin	
   		select @msg = 'Invalid copy from value.  Must be "T - Template" or "S - Standard C/C"', @rcode = 1
   		goto bspexit
   	end
   
   	if @copyfrom = 'T' and @sourcetemplate is null
   	begin
   		select @msg = 'Copy from "Template" specified.  Source Template not entered.', @rcode = 1
   		goto bspexit
   	end
   
   	if @whatcrafts is null
   	begin
   		select @msg = 'All Crafts or Selected Craft not specified.', @rcode = 1
   		goto bspexit
   	end
   
   	if @whatcrafts not in ('A', 'S') 
   	begin
   		select @msg = 'Invalid copy Craft Selection.  Must be "A - All Crafts" or "S - Selected Craft".'
   	end
   
   	if @whatcrafts = 'S' and @sourcecraft is null
   	begin
   		select @msg = 'Copy "Selected Craft" specified.  Craft not entered.', @rcode = 1
   		goto bspexit
   	end
   
   	if @desttemplate is null
   	begin
   		select @msg = 'Destination Template not specified', @rcode = 1
   		goto bspexit
   	end
   
   	--Destination Template exist?
   	exec @rcode = bspPRTemplateExistsVal @prco, @desttemplate, @templateexistsyn output, @msg output
   
   	if @rcode = 0	
   	begin
   		if @templateexistsyn = 'N'
   		begin
   			begin transaction
   			--Template does not exist.  Create it.
   			insert dbo.PRTM (PRCo, Template, Description) 
   			values (@prco, @desttemplate, @destdesc)
   			if @@rowcount = 1
   				commit transaction
   			else
   			begin
   				rollback transaction
   				select @rcode = 1, @msg = 'Unable to create destination Template #' + convert(varchar(5), @desttemplate)
   				goto bspexit
   			end
   		end
   	end
   
   	if @copyfrom = 'T'
   	begin
   
   	    exec @rcode = bspPRTemplateCraftClassCopy @prco, @sourcetemplate, @whatcrafts, @sourcecraft, 
   		@payrateyn, @addonearnyn, @variableearnyn, @dedliabyn, @jcitemsyn, @notesyn, @desttemplate, 
   		@msg output
   
   /*
   		if @whatcrafts = 'S'
   		begin
   			exec @rcode = bspPRTemplateCopyByCraft @prco, @sourcetemplate, @sourcecraft, @payrateyn, @addonearnyn,
   			@variableearnyn, @dedliabyn, @notesyn, @jcitemsyn, @desttemplate, @msg output
   		end
   
   		if @whatcrafts = 'A'
   		begin
   			exec @rcode = bspPRTemplateCopyAllCrafts  @prco, @sourcetemplate, @payrateyn, @addonearnyn, 
   			@variableearnyn, @dedliabyn, @jcitemsyn, @notesyn, @desttemplate, @msg output
   		end
   */
   
   		if @rcode <> 0
   		begin
   			select @msg = 'Unable to copy template.  ' +  @msg
   			goto bspexit
   		end
   	end
   
   	if @copyfrom = 'S'
   	begin
   		exec @rcode = bspPRTemplateStdCraftClassCopy @prco, @whatcrafts, @sourcecraft, @payrateyn, @addonearnyn, 
   		@variableearnyn, @dedliabyn, @notesyn, @desttemplate, @msg output
   
   		if @rcode <> 0
   		begin
   			select @msg = 'Unable to copy template.  ' +  @msg
   			goto bspexit
   		end
   	end
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRTemplateCopy] TO [public]
GO
