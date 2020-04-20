SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspIMImportIDValWithInfo    Script Date: 3/29/2002 9:34:23 AM ******/
   CREATE   Procedure [dbo].[bspIMImportIDValWithInfo]
   /***********************************************************
   * CREATED: MH 09/17/99
   * MODIFIEDS: GG 09/20/02 - #18522 ANSI nulls
   *
   * USAGE:
   * validates ImportID and returns additional information
   *
   * INPUT PARAMETERS
   *   ImportID
   
   * OUTPUT PARAMETERS
   *   @msg If Error, error message, otherwise description of ImportID
   * RETURN VALUE
   *   0   success
   *   1   fail
   *****************************************************/
   	(@importid varchar(20) = null, @template varchar(10) = null output, @rectype varchar(30) = null output,
           @tempdescription bDesc = null output, @importform varchar(30) = null output,
           @uploadrout varchar(30) = null output, @importformdesc bDesc = null output,
		   @batchyn bYN = null output, @msg varchar(60)=null output)
   --@minrecseq int output,
   as
   
   set nocount on
   
   
   declare @rcode int
   select @rcode = 0
   
   if @importid is null	-- #18522
   	begin
   	select @msg = 'Missing ImportID!', @rcode = 1
   	goto bspexit
   	end
   
   --if exists(select ImportId from IMWH where ImportId = @importid)
   if exists(select ImportId from IMWE with (nolock) where ImportId = @importid)
   	begin
           select @importid = ImportId, @template = ImportTemplate, @rectype= RecordType
           from IMWE with (nolock)
           where ImportId = @importid
   
           --select @minrecseq = min(RecordSeq) from IMWE
           --where ImportId = @importid
   
           if @template is null
               begin
               select @msg = 'Template does not exist in IMWE', @rcode = 1
               goto bspexit
               end
   
           if exists(select 1 from IMTH where ImportTemplate=@template)
               begin
                   select @tempdescription = IMTH.Description, @importform = IMTH.Form,   --get import routine for this template
                   @uploadrout = IMTH.UploadRoutine
                   from IMTH with (nolock)
                   where IMTH.ImportTemplate = @template
   
                   if @@rowcount <> 0     --get the form description for this form
                   begin
                       select @importformdesc=Description, @batchyn = BatchYN from DDUF with (nolock) where Form= @importform
                   end
               end
           else
               begin
                   select @msg = 'Template not set up in IMTH', @rcode = 1
                   goto bspexit
               end
   	end
   else
   	begin
   	select @msg = 'Not a valid ImportId', @rcode = 1
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMImportIDValWithInfo] TO [public]
GO
