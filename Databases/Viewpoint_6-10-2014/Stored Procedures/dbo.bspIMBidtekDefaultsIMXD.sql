SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspIMBidtekDefaultsIMXD    Script Date: 10/11/99 ******/
   CREATE    proc [dbo].[bspIMBidtekDefaultsIMXD]
   /***********************************************************
    * CREATED BY: Danf
    * MODIFIED BY: DANF 03/19/02 - Added Record Type
    *
    * Usage:
    *	Used by Imports to create values for needed or missing
    *      data based upon Bidtek default rules.
    *
    * Input params:
    *	@ImportId	Import Identifier
    *	@ImportTemplate	Import ImportTemplate
    *
    * Output params:
    *	@msg		error message
    *
    * Return code:
    *	0 = success, 1 = failure
    ************************************************************/
   
    (@Company bCompany, @ImportId varchar(20), @ImportTemplate varchar(20), @Form varchar(20), @rectype varchar(30), @msg varchar(120) output)
   
   as
   
   set nocount on
   
   declare @desc varchar(255), @rcode int
   
   
   /* check required input params */
   
   if @ImportId is null
     begin
     select @desc = 'Missing ImportId.', @rcode = 1
     goto bspexit
     end
   if @ImportTemplate is null
     begin
     select @desc = 'Missing ImportTemplate.', @rcode = 1
     goto bspexit
     end
   
   if @Form is null
     begin
     select @desc = 'Missing Form.', @rcode = 1
     goto bspexit
    end
   --
   
   
   bspexit:
       select @msg = isnull(@desc,'Cross reference Detail') + char(13) + char(10) + '[bspBidtekDefaultIMXD]'
   
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMBidtekDefaultsIMXD] TO [public]
GO
