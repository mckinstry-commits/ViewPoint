SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMImportUMGet    Script Date: 8/28/99 9:35:13 AM ******/
   CREATE proc [dbo].[bspPMImportUMGet]
   
   /****************************************************************************
   * CREATED BY: 	GF  05/29/99
   * MODIFIED BY:
   *
   * USAGE:
   * 	Gets valid UM for import um.     
   *
   * INPUT PARAMETERS:
   *	Template, ImportUm, PMCo, Override, StdTemplate
   *
   * OUTPUT PARAMETERS:
   *	UM
   *       
   * RETURN VALUE:
   * 	0 	    Success
   *	1 & message Failure
   *
   *****************************************************************************/
   
    (@template varchar(10), @importum varchar(30), @pmco bCompany, @override bYN = 'N',
     @stdtemplate varchar(10) = '', @um bUM output)
   
    as
    set nocount on
    declare @rcode int, @xreftype tinyint, @ium bUM
    
    select @rcode = 0, @xreftype = 2
    
    select @ium = substring(@importum,1,3)
    
    if @importum is not null
       begin
       select @um = isnull(UM,'')
       from bPMUX where Template=@template and XrefType=@xreftype and XrefCode=@importum
         if @@rowcount = 0 
            begin
            select @um = isnull(UM,'')
            from bPMUX where Template=@template and XrefType=@xreftype and XrefCode=@importum
            if @@rowcount = 0 and @override='Y'
               begin
               select @um = isnull(UM,'')
               from bPMUX where Template=@stdtemplate and XrefType=@xreftype and XrefCode=@importum
               if @@rowcount = 0
                  begin
                  select @um = isnull(UM,'')
                  from bPMUX where Template=@stdtemplate and XrefType=@xreftype and XrefCode=@importum
                  end
               end
            end
       end
       
    if @um is null or @um=''
       begin
       select @um = isnull(UM,'') from bHQUM where UM=@ium
       end
    
    if @um is null or @um=''
       begin
       select @um=@ium
       end
       
    if @um is null or @um=''
       begin
       select @um=null
       end
    
   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMImportUMGet] TO [public]
GO
