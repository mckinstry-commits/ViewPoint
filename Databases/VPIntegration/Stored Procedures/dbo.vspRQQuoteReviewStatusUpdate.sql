SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspRQQuoteReviewStatusUpdate]
  /*******************************************************************************************************
  * CREATED BY: 	 DC 6/13/07
  * MODIFIED By :  
  *
  * USAGE:  
  *		This will mark RQ Reviewer Quote Lines as approved or rejected.  
  *
  * INPUTS:
  *	@co
  *	@reviewer
  *	@status
  *	@keyarray
  *	
  *
  * OUTPUTS:
  * ReturnCode	0 = Success, 1 = failed,  7 = some RQRR records failed, some successed
  *	@msg		
  *
  *******************************************************************************************************/
  (@co bCompany, @reviewer varchar(3), @status bYN, @keyarray varchar(5000), @msg varchar(5000) output)

	as
	set nocount on

	declare @rcode int,
			@keyarraylength as int,
			@keylength as int,
			@keydelimiter as char(1),
			@keypos as int,
			@key as varchar(20),
			@rqdelimiter as char(1),
			@rqpos as int,
			@quoteid as int,
			@quoteline as int,
			@statuscode as int

	select @rcode = 0, @keydelimiter = ';', @rqdelimiter = ',' select @msg = ''

	if @status = 'Y'  
		BEGIN		
			SET @statuscode = 1 
		END
	if @status = 'N'  
		BEGIN		
			SET @statuscode = 0 
		END

	if @co is null
		begin
    	select @msg = 'Missing PO Company!', @rcode = 1
    	goto vspexit
    	end
	if @reviewer is null
    	begin
    	select @msg = 'Missing Reviewer!', @rcode = 1
    	goto vspexit
    	end
	if @status is null
    	begin
    	select @msg = 'Missing Status!', @rcode = 1
    	goto vspexit
    	end
	if @keyarray is null or len(@keyarray) = 0 
    	begin
    	select @msg = 'Missing Key String!', @rcode = 1
    	goto vspexit
    	end
	
	WHILE len(@keyarray) > 0 
		BEGIN

			set @keyarraylength= LEN(@keyarray)
			set @keypos = CHARINDEX(@keydelimiter, @keyarray)
			set @key = SUBSTRING(@keyarray,1,@keypos)

			set @keylength = LEN(@key)
			set @rqpos = CHARINDEX(@rqdelimiter,@key)
			set @quoteid = SUBSTRING(@key,1,@rqpos-1)
			set @quoteline = SUBSTRING(@key,@rqpos+1,@keylength-@rqpos-1)
			

			BEGIN TRY
				-- update RQQR 
				UPDATE RQQR
				SET Status = @statuscode
				FROM RQQR
				WHERE RQQR.RQCo = @co and RQQR.Quote = @quoteid and RQQR.QuoteLine = @quoteline and RQQR.Reviewer = @reviewer

			END TRY
			BEGIN CATCH
				select @msg = @msg + 'Quote: ' + ltrim(@quoteid) + ' RQLine: ' + ltrim(@quoteline) + '=' + ERROR_MESSAGE() + char(13), @rcode = 7
			END CATCH

			set @keyarray = SUBSTRING(@keyarray,@keylength+1,@keyarraylength-@keylength)

		END
		
    vspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspRQQuoteReviewStatusUpdate] TO [public]
GO
