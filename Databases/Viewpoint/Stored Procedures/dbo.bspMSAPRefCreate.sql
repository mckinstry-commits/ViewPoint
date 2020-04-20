SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspMSAPRefALTER  ******/
   CREATE   proc [dbo].[bspMSAPRefCreate]
   /***********************************************************
     * CREATED By:	GF 03/04/2005
     * MODIFIED By:	GF 09/27/2005 - issue #29919 need to group by APRef sequence part to get accurate max.
     *             
     *        
     *
     *
     *
     *
     * USAGE: called from MS Hauler Worksheet Initialize and 
     * MS Material Vendor Worksheet Initialize to generate a unique AP Reference.
     * Will create up to a 2-digit number starting at one. The first occurance
     * of the APRef in the batch will not have a sequence number added to it.
     * The length of the APRef before adding a sequence must be 13 characters or less.
     *
     *
     *
     * INPUT PARAMETERS
     * @msco			MS Company
     * @mth				Month of batch
     * @batchid			Batch ID
     * @ref				AP Reference to validate
     * @source			MS Batch Source (MS HaulPay or MS MatlPay)
     *
     *
     * OUTPUT PARAMETERS
     * @newapref		New APRef with a sequence attached or the passed in APRef
     * @msg				message if Reference is not unique otherwise nothing
     *
     * RETURN VALUE
     *   0         success
     *   1         failure
     *****************************************************/
    (@msco bCompany = null, @mth bMonth = null, @batchid bBatchID = null,
     @ref bAPReference = null, @source bSource = null, 
     @newref bAPReference output, @msg varchar(255) output)
    as
    set nocount on
    
    declare @rcode int, @refpart varchar(13), @inputlength varchar(10), @inputmask varchar(30),
    		@tmpvalue varchar(15), @tmpseq int
    
    select @rcode = 0
    
    if isnull(@ref,'') = '' goto bspexit
    
    -- -- -- get the mask for bAPReference
    select @inputmask=InputMask, @inputlength = convert(varchar(10), InputLength)
    from DDDTShared with (nolock) where Datatype = 'bAPReference'
    if isnull(@inputmask,'') = '' select @inputmask = 'L'
    if isnull(@inputlength,'') = '' select @inputlength = '15'
    if @inputmask in ('R','L')
      	begin
      	select @inputmask = @inputlength + @inputmask + 'N'
      	end
    
    -- -- -- if length of @ref is greater than 13 then set to itself and exit
    if datalength(ltrim(rtrim(@ref))) > 13
    	begin
    	set @newref = @ref
    	goto bspexit
    	end
    
    set @refpart = ltrim(rtrim(@ref))
    
    -- -- -- check to see if AP ref exist in batch, if not then do not add sequence
    if @source = 'MS HaulPay'
    	begin
    	if not exists(select top 1 1 from bMSWH where Co=@msco and Mth=@mth
    				and BatchId=@batchid and ltrim(rtrim(APRef)) = @refpart)
    		begin
    		set @newref = @ref
    		goto bspexit
    		end
    	end
    else
    	begin
    	if not exists(select top 1 1 from bMSMH where Co=@msco and Mth=@mth
    				and BatchId=@batchid and ltrim(rtrim(APRef)) = @refpart)
    		begin
    		set @newref = @ref
    		goto bspexit
    		end
    	end
    
    -- -- -- get temp seq for max(APRef) to create next sequential APRef
    if @source = 'MS HaulPay'
    	begin
    	select @tmpvalue = max(ltrim(rtrim(APRef)))
    	from bMSWH with (nolock) where Co=@msco and Mth=@mth and BatchId=@batchid 
    	and substring(ltrim(rtrim(APRef)), 1, len(@refpart)) = @refpart
   	-- -- -- issue #29919
   	group by convert(int,substring(APRef, len(@refpart)+1, 2))
    	-- parse out the sequence part of the APRef
    	if len(@tmpvalue) > len(@refpart)
    		set @tmpseq = convert(int, substring(@tmpvalue, len(@refpart) + 1, len(@tmpvalue)))
    	else
    		set @tmpseq = 0
    	end
    else
    	begin
    	select @tmpvalue = max(ltrim(rtrim(APRef)))
    	from bMSMH with (nolock) where Co=@msco and Mth=@mth and BatchId=@batchid 
    	and substring(ltrim(rtrim(APRef)), 1, len(@refpart)) = @refpart
   	-- -- -- issue #29919
   	group by convert(int,substring(APRef, len(@refpart)+1, 2))
    	-- parse out the sequence part of the APRef
    	if len(@tmpvalue) > len(@refpart)
    		set @tmpseq = convert(int, substring(@tmpvalue, len(@refpart) + 1, len(@tmpvalue)))
    	else
    		set @tmpseq = 0
    	end
   
   
    -- -- -- create new AP Ref
    set @tmpseq = @tmpseq + 1
    -- -- -- verify sequence range
    if @tmpseq < 1 or @tmpseq > 99
    	begin
    	set @newref = @ref
    	goto bspexit
    	end
   
   -- -- -- concatenate seq to ref part
   set @refpart = @refpart + convert(varchar(2), @tmpseq)
   -- -- -- format APRef
   exec @rcode = dbo.bspHQFormatMultiPart @refpart, @inputmask, @newref output
   
   
   set @rcode = 0
   
   
   
   bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSAPRefCreate] TO [public]
GO
