SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 4/15/2014
-- Description:	Toggle lock/unlock all contract items.
-- =============================================
CREATE PROCEDURE [dbo].[mckJCCILockUnlock] 
	-- Add the parameters for the stored procedure here
	@JCCo bCompany = 1, 
	@Contract bContract = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	--@LockState = 1 when contains unlocked items.  @LockState = 0 when no unlocked items exist.
	DECLARE @LockState BIT = 0

	IF EXISTS(
	SELECT TOP 1 1
	FROM dbo.JCCI
	WHERE JCCo = @JCCo AND Contract = @Contract
		AND udLockYN = 'N'
	)
	SET @LockState = 1


	IF @LockState = 1
	BEGIN
		UPDATE dbo.JCCI
		SET udLockYN = 'Y'
		WHERE JCCo = @JCCo AND Contract = @Contract AND udLockYN = 'N'
	END

	IF @LockState = 0
	BEGIN
		UPDATE dbo.JCCI
		SET udLockYN = 'N'
		WHERE JCCo = @JCCo AND Contract = @Contract --AND udLockYN = 'Y'
	END
END
GO
