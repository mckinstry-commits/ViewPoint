SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 3/14/2014
-- Description:	Work around for bug in SM Work Order template import routine
-- =============================================
CREATE PROCEDURE [dbo].[mckIMWOResetCallType] 
	-- Add the parameters for the stored procedure here
	(
	@Company bCompany = 0, 
	@ImportId varchar(20) = 0
	, @ImportTemplate VARCHAR(20)
	, @Form VARCHAR(20)
	, @msg VARCHAR(120) OUTPUT
	)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	declare @rcode int, /*@recode int,*/ @desc varchar(120)
       
        set nocount on
 
        select @rcode = 0
        
        
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

    -- Insert statements for procedure here
	
	BEGIN
	--handle the fact that the UserRoutine doesn't run for both record types.
	SET @Form = @Form + 'Scope'
	--update the record.
		UPDATE dbo.IMWE
		SET IMWE.UploadVal = IMWE.ImportedVal
		WHERE IMWE.ImportId = @ImportId AND ImportTemplate = @ImportTemplate AND Form = @Form AND RecordType = 2
			AND Identifier IN  (20,30) 
		--SELECT @Company, @ImportId
		

	END


	bspexit:
	SELECT @msg = ISNULL(@desc,'User Routine') + CHAR(13) + CHAR(10) + '[[mckIMWOResetCallType]]'
	RETURN @rcode
END
GO
GRANT EXECUTE ON  [dbo].[mckIMWOResetCallType] TO [public]
GO
