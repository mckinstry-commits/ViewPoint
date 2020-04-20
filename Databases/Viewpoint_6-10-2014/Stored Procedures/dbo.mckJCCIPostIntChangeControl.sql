SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 1/8/2014
-- Description:	Procedure to prevent changes to Contract Items after interface
-- =============================================
CREATE PROCEDURE [dbo].[mckJCCIPostIntChangeControl] 
	-- Add the parameters for the stored procedure here
	@JCCo TINYINT = 0, 
	@Contract bContract = 0
	, @Item bContractItem
	, @ReturnMessage VARCHAR(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @Status TINYINT, @LockYN bYN, @rcode TINYINT = 0

	IF EXISTS(SELECT TOP 1 1 FROM JCCI WHERE @JCCo = JCCo AND @Contract = Contract AND @Item = Item)
	BEGIN
		SELECT @LockYN = udLockYN FROM JCCI WHERE @JCCo = JCCo AND @Contract = Contract AND @Item = Item
		IF @LockYN <> 'N'
		BEGIN
			SELECT @ReturnMessage = 'This Contract Item is locked. Contact accounting dept for changes.'
				, @rcode = 1
			GOTO spexit
		END

		--SELECT @Status = ContractStatus FROM JCCM WHERE @JCCo = JCCo AND @Contract = Contract
		--IF @Status <> 0
		--BEGIN
		--	SELECT @ReturnMessage = 'This Contract has already been interfaced. Contact accounting dept for changes.'
		--	, @rcode = 1
		--	GOTO spexit
		--END
	END
	
	
	spexit:
	BEGIN
		RETURN @rcode
	END
END
GO
GRANT EXECUTE ON  [dbo].[mckJCCIPostIntChangeControl] TO [public]
GO
