SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Aaron Lang, vspVADDFSForm>
-- Create date: <05/23/03>
-- Description:	<Description>
-- =============================================
CREATE PROCEDURE [dbo].[vspVADDFSForm]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT Co, Form, Mod, SecurityGroup, Groups, VPUserName,
Access=
 (case f.Access
   when 0 then '0-Full' --(case f.SecLvl when 0 then 'Full' else 'ReadOnly' end)
   when 1 then '1-ByTab'
   when 2 then '2-ReadOnly'
END)  
,RecAdd, [RecDelete], [RecUpdate] 


FROM DDFSForm f


END




GO
GRANT EXECUTE ON  [dbo].[vspVADDFSForm] TO [public]
GO
