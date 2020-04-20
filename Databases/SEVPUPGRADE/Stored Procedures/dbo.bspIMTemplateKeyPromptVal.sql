SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspIMTemplateKeyPromptVal]
   
     /**************************************************
     *
     * Created By:  RT 10/09/03 - #13558
     * Modified By: 
     *
     * DESCRIPTION
     *   Prevent more than one identifier from being set 
     *		to be a Key field AND prompt the user on import.
     *
     * INPUT PARAMETERS
     *    <LIST>
     *
     * RETURN PARAMETERS
     *    Error Message and
     *	   0 for success, or
     *    1 for failure
     *
     *************************************************/
     (@template varchar(10), @rectype varchar(30), @identifier int, @keyyn bYN, @promptyn bYN, @errmsg varchar(255) = null output)
    
     AS
    
     set nocount on
   
     declare @checkedcount int, @rcode int, @isIdentUpdateKey int, @isIdentPrompt int
   
     select @rcode = 0, @errmsg = null
     --if the user is unchecking the options, don't validate.
     if @keyyn = 'N' goto bspexit
     if @promptyn = 'N' goto bspexit
   
     select @checkedcount = count(*) from bIMTD
     where ImportTemplate = @template 
   	and RecordType = @rectype and ImportPromptYN = 'Y' and UpdateKeyYN = 'Y'
   	and Identifier <> @identifier
   
     if @checkedcount > 0
     begin
   	select @rcode = 1
   	select @errmsg = 'Only one key identifier may be marked to prompt on import.'
     end
   
   bspexit:
   
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMTemplateKeyPromptVal] TO [public]
GO
