SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspIMGetMaxSeq    Script Date: 11/6/2002 9:31:36 AM ******/
   
   CREATE   Procedure [dbo].[bspIMGetMaxSeq]
   /***********************************************************
    * CREATED BY: GR 09/30/99
    *
    * USAGE:
    * Gets the Max Record Seq for the template/ImportID - used
    * when we need to append another text file
    *
    * INPUT PARAMETERS
    *   ImportID
    *   Template
    * OUTPUT PARAMETERS
    *   Max seq
    *   @msg If Error, error message, otherwise description of ImportID
    * RETURN VALUE
    *   0   success
    *   1   failure
    *****************************************************/
   	(@template varchar(20) = null, @importid varchar(20), @maxseq int output, @msg varchar(60) output)
   as
   
   set nocount on
   
   
   declare @rcode int
   select @rcode = 0
   
   if @template is null
   	begin
   	select @msg = 'Missing Template!', @rcode = 1
   	goto bspexit
   	end
   if @importid is null
       begin
       select @msg='Missing ImportId', @rcode =1
       goto bspexit
       end
   
   
   if exists(select max(RecordSeq) from IMWE where ImportTemplate = @template and ImportId = @importid)
   	begin
           select @maxseq = max(RecordSeq) from IMWE where ImportTemplate = @template and ImportId = @importid
       end
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMGetMaxSeq] TO [public]
GO
